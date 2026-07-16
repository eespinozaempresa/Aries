import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/export_service.dart';
import '../../data/datasources/caja_remote_datasource.dart';
import '../../domain/entities/sesion_caja.dart';
import '../bloc/caja_bloc.dart';

class CajaReportePage extends StatelessWidget {
  final String sesionId;
  const CajaReportePage({super.key, required this.sesionId});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CajaBloc(getIt<CajaRemoteDataSource>())..add(CajaLoadReporte(sesionId)),
    child: _View(sesionId: sesionId),
  );
}

class _View extends StatelessWidget {
  final String sesionId;
  const _View({required this.sesionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Caja'),
        actions: [
          BlocBuilder<CajaBloc, CajaState>(
            builder: (ctx, state) {
              if (state is! CajaReporteLoaded) return const SizedBox.shrink();
              final r = state.reporte;
              if (r.movimientos.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Exportar',
                onPressed: () => ExportService.showExportDialog(
                  context: context,
                  title: 'Reporte de Caja ${r.sesion.codigoCaja}',
                  columns: const ['Concepto', 'Tipo', 'Fecha', 'Referencia', 'Monto'],
                  rows: r.movimientos.map((m) => [
                    m.concepto, m.tipo.name, m.fecha,
                    m.referencia ?? '', m.monto.toStringAsFixed(2),
                  ]).toList(),
                  subtitle: 'Apertura: ${r.sesion.fechaApertura.substring(0, 10)} | Saldo: S/ ${r.saldoFinal.toStringAsFixed(2)}',
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<CajaBloc, CajaState>(
        listener: (ctx, s) {
          if (s is CajaError) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(s.message), backgroundColor: Colors.red));
          if (s is CajaCerrada) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Caja cerrada'), backgroundColor: Colors.orange));
            Navigator.of(ctx).pop();
          }
          if (s is CajaMovimientoRegistrado) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Movimiento registrado'), backgroundColor: Colors.green));
            ctx.read<CajaBloc>().add(CajaLoadReporte(sesionId));
          }
        },
        builder: (ctx, s) {
          if (s is CajaLoading || s is CajaSaving) return const Center(child: CircularProgressIndicator());
          if (s is! CajaReporteLoaded) return const Center(child: CircularProgressIndicator());
          final r = s.reporte;
          final abierta = r.sesion.estado == EstadoCaja.ABIERTA;
          return ListView(padding: const EdgeInsets.all(16), children: [
            // Header card
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Caja ${r.sesion.codigoCaja}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Chip(
                  label: Text(r.sesion.estado.name),
                  backgroundColor: abierta ? Colors.green[100] : Colors.grey[200],
                ),
              ]),
              const Divider(),
              _row('Apertura', r.sesion.fechaApertura.substring(0, 16)),
              if (r.sesion.fechaCierre != null) _row('Cierre', r.sesion.fechaCierre!.substring(0, 16)),
              _row('Monto apertura', 'S/ ${r.sesion.montoApertura.toStringAsFixed(2)}'),
              const Divider(),
              _row('Ingresos',  'S/ ${r.totalIngresos.toStringAsFixed(2)}', color: Colors.green),
              _row('Egresos',   'S/ ${r.totalEgresos.toStringAsFixed(2)}',  color: Colors.red),
              _row('Saldo final','S/ ${r.saldoFinal.toStringAsFixed(2)}', bold: true),
              if (r.sesion.montosCierre != null)
                _row('Diferencia', 'S/ ${r.sesion.diferencia!.toStringAsFixed(2)}',
                  color: r.sesion.diferencia! == 0 ? Colors.green : Colors.orange),
            ]))),
            const SizedBox(height: 16),
            Text('Movimientos (${r.movimientos.length})', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...r.movimientos.map((m) => ListTile(
              dense: true,
              leading: Icon(m.tipo == TipoMovCaja.INGRESO ? Icons.arrow_downward : Icons.arrow_upward,
                color: m.tipo == TipoMovCaja.INGRESO ? Colors.green : Colors.red, size: 20),
              title: Text(m.concepto),
              subtitle: Text('${m.fecha}${m.referencia != null ? " • ${m.referencia}" : ""}'),
              trailing: Text('S/ ${m.monto.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: m.tipo == TipoMovCaja.INGRESO ? Colors.green : Colors.red,
                )),
            )),
            if (r.movimientos.isEmpty) const Text('Sin movimientos', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            if (abierta) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Registrar movimiento'),
                onPressed: () => _showMovDialog(ctx, r.sesion.id),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.lock),
                label: const Text('Cerrar caja'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _showCerrarDialog(ctx, r.sesion, r.saldoFinal),
              ),
            ],
          ]);
        },
      ),
    );
  }

  Widget _row(String l, String v, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      SizedBox(width: 130, child: Text(l, style: const TextStyle(color: Colors.grey))),
      Expanded(child: Text(v, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color))),
    ]),
  );

  void _showMovDialog(BuildContext ctx, String sesionId) {
    final conceptoCtrl = TextEditingController();
    final montoCtrl    = TextEditingController();
    final refCtrl      = TextEditingController();
    String tipo = 'INGRESO';
    DateTime fecha = DateTime.now();

    showDialog(context: ctx, builder: (dctx) => StatefulBuilder(builder: (dctx, setSt) => AlertDialog(
      title: const Text('Registrar Movimiento'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'INGRESO', label: Text('Ingreso'), icon: Icon(Icons.arrow_downward)),
            ButtonSegment(value: 'EGRESO',  label: Text('Egreso'),  icon: Icon(Icons.arrow_upward)),
          ],
          selected: {tipo},
          onSelectionChanged: (s) => setSt(() => tipo = s.first),
        ),
        const SizedBox(height: 8),
        TextField(controller: conceptoCtrl, decoration: const InputDecoration(labelText: 'Concepto')),
        TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Referencia (opcional)')),
        TextField(controller: montoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto')),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Fecha: ${fecha.toIso8601String().substring(0, 10)}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final d = await showDatePicker(context: dctx, initialDate: fecha, firstDate: DateTime(2020), lastDate: DateTime.now());
            if (d != null) setSt(() => fecha = d);
          },
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final m = double.tryParse(montoCtrl.text);
            if (conceptoCtrl.text.isEmpty || m == null || m <= 0) return;
            Navigator.pop(dctx);
            ctx.read<CajaBloc>().add(CajaRegistrarMovimiento(
              sesionCajaId: sesionId,
              tipo: tipo,
              concepto: conceptoCtrl.text.trim(),
              monto: m,
              fecha: fecha.toIso8601String().substring(0, 10),
              referencia: refCtrl.text.isNotEmpty ? refCtrl.text.trim() : null,
            ));
          },
          child: const Text('Guardar'),
        ),
      ],
    )));
  }

  void _showCerrarDialog(BuildContext ctx, SesionCaja sesion, double saldoFinal) {
    final montoCtrl = TextEditingController(text: saldoFinal.toStringAsFixed(2));

    showDialog(context: ctx, builder: (dctx) => AlertDialog(
      title: const Text('Cerrar Caja'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Saldo calculado: S/ ${saldoFinal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(controller: montoCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto contado (S/)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () {
            final m = double.tryParse(montoCtrl.text);
            if (m == null) return;
            Navigator.pop(dctx);
            ctx.read<CajaBloc>().add(CajaCerrar(id: sesion.id, montosCierre: m));
          },
          child: const Text('Cerrar caja'),
        ),
      ],
    ));
  }
}
