import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/export_service.dart';
import '../../../../features/tablas/data/datasources/tablas_remote_datasource.dart';
import '../../../../features/tablas/data/models/tabla_model.dart';
import '../../../../features/tablas/domain/entities/tabla_base.dart';
import '../../data/datasources/caja_remote_datasource.dart';
import '../../domain/entities/sesion_caja.dart';
import '../bloc/caja_bloc.dart';
import '../../../../core/widgets/aries_app_bar.dart';
import '../../../../core/widgets/number_form_field.dart';

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
      appBar: AriesAppBar(
        title: const Text('Reporte de Caja'),
        actions: [
          BlocBuilder<CajaBloc, CajaState>(
            builder: (ctx, state) {
              if (state is! CajaReporteLoaded) return const SizedBox.shrink();
              final r = state.reporte;
              return IconButton(
                icon: const Icon(Icons.account_balance_outlined),
                tooltip: 'Balance',
                onPressed: () => _showBalanceDialog(context, r),
              );
            },
          ),
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
                    m.concepto, m.tipo.name, ExportService.fmtDate(m.fecha),
                    m.referencia ?? '', m.monto.toStringAsFixed(2),
                  ]).toList(),
                  subtitle: 'Apertura: ${ExportService.fmtDate(r.sesion.fechaApertura)} | Saldo: S/ ${r.saldoFinal.toStringAsFixed(2)}',
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
              subtitle: Text('${m.fecha}${m.tipoPago != null ? " • ${m.tipoPago}" : ""}${m.referencia != null ? " • ${m.referencia}" : ""}'),
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
    final nroOpCtrl    = TextEditingController();
    String tipo = 'INGRESO';
    DateTime fecha = DateTime.now();
    List<TipoPago> tiposPago = [];
    TipoPago? tipoPagoSeleccionado;
    bool _fetched = false;

    showDialog(context: ctx, builder: (dctx) => StatefulBuilder(builder: (dctx, setSt) {
      if (!_fetched) {
        _fetched = true;
        getIt<TablasRemoteDataSource>().list('tipos-pago', activo: true).then((raw) {
          setSt(() => tiposPago = raw.map(TablaModel.tipoPagoFromJson).toList());
        }).catchError((_) {});
      }
      return AlertDialog(
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
          NumberFormField(controller: montoCtrl, decoration: const InputDecoration(labelText: 'Monto')),
          if (tiposPago.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<TipoPago>(
              value: tipoPagoSeleccionado,
              decoration: const InputDecoration(labelText: 'Tipo de Pago'),
              items: tiposPago.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.descripcion),
              )).toList(),
              onChanged: (v) => setSt(() {
                tipoPagoSeleccionado = v;
                nroOpCtrl.clear();
              }),
            ),
          ],
          if (tipoPagoSeleccionado?.requiereOperacion == true) ...[
            const SizedBox(height: 8),
            TextField(controller: nroOpCtrl, decoration: const InputDecoration(labelText: 'N° Operación')),
          ],
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
          OutlinedButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancelar')),
          FilledButton(
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
                tipoPago: tipoPagoSeleccionado?.descripcion,
              ));
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    }));
  }

  void _showBalanceDialog(BuildContext ctx, ReporteCaja r) {
    showDialog(
      context: ctx,
      builder: (_) => _BalanceDialog(reporte: r),
    );
  }

  void _showCerrarDialog(BuildContext ctx, SesionCaja sesion, double saldoFinal) {
    final montoCtrl = TextEditingController(text: saldoFinal.toStringAsFixed(2));

    showDialog(context: ctx, builder: (dctx) => AlertDialog(
      title: const Text('Cerrar Caja'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Saldo calculado: S/ ${saldoFinal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        NumberFormField(controller: montoCtrl,
          decoration: const InputDecoration(labelText: 'Monto contado (S/)')),
      ]),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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

// ── Balance Dialog ────────────────────────────────────────────────────────────

class _BalanceDialog extends StatefulWidget {
  final ReporteCaja reporte;
  const _BalanceDialog({required this.reporte});

  @override
  State<_BalanceDialog> createState() => _BalanceDialogState();
}

class _BalanceDialogState extends State<_BalanceDialog> {
  bool _detallado = false;
  String? _filtroPago; // null = todos

  ReporteCaja get r => widget.reporte;

  List<MovimientoCaja> get _movsFiltrados {
    if (_filtroPago == null) return r.movimientos;
    return r.movimientos.where((m) => m.tipoPago == _filtroPago).toList();
  }

  List<String> get _tiposPagoDisponibles {
    final tipos = r.movimientos
        .map((m) => m.tipoPago)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    return tipos;
  }

  void _export(BuildContext context) {
    final movs = _movsFiltrados;
    final filtroLabel = _filtroPago ?? 'Todos los pagos';
    final cajaLabel = r.sesion.codigoCaja;
    final apertura = r.sesion.montoApertura;
    final totalIngresos = movs.where((m) => m.tipo == TipoMovCaja.INGRESO).fold(0.0, (s, m) => s + m.monto);
    final totalEgresos  = movs.where((m) => m.tipo == TipoMovCaja.EGRESO ).fold(0.0, (s, m) => s + m.monto);
    final saldoFinal    = apertura + totalIngresos - totalEgresos;
    final subtitle = 'Filtro: $filtroLabel | Apertura: S/ ${apertura.toStringAsFixed(2)} | Saldo Final: S/ ${saldoFinal.toStringAsFixed(2)}';

    if (_detallado) {
      ExportService.showExportDialog(
        context: context,
        title: 'Balance Detallado - Caja $cajaLabel',
        subtitle: subtitle,
        columns: const ['Tipo', 'Fecha', 'Concepto', 'Referencia', 'Tipo de Pago', 'Monto (S/)'],
        rows: [
          ['APERTURA', ExportService.fmtDate(r.sesion.fechaApertura), 'Monto de apertura', '', '', apertura.toStringAsFixed(2)],
          ...movs.map((m) => [
            m.tipo.name,
            ExportService.fmtDate(m.fecha),
            m.concepto,
            m.referencia ?? '',
            m.tipoPago ?? '',
            m.monto.toStringAsFixed(2),
          ]),
          ['', '', '', '', 'Total Ingresos', totalIngresos.toStringAsFixed(2)],
          ['', '', '', '', 'Total Egresos',  totalEgresos.toStringAsFixed(2)],
          ['', '', '', '', 'Saldo Final',    saldoFinal.toStringAsFixed(2)],
        ],
      );
    } else {
      // Resumido: group by tipo → tipoPago
      final Map<String, Map<String, double>> grupos = {};
      for (final m in movs) {
        final tipo = m.tipo.name;
        final pago = m.tipoPago ?? '(Sin tipo)';
        grupos.putIfAbsent(tipo, () => {})[pago] =
            (grupos[tipo]![pago] ?? 0) + m.monto;
      }
      final rows = <List<String>>[
        ['APERTURA', '', apertura.toStringAsFixed(2)],
      ];
      for (final tipo in ['INGRESO', 'EGRESO']) {
        if (!grupos.containsKey(tipo)) continue;
        final subtotal = tipo == 'INGRESO' ? totalIngresos : totalEgresos;
        for (final e in grupos[tipo]!.entries) {
          rows.add([tipo, e.key, e.value.toStringAsFixed(2)]);
        }
        rows.add([tipo, 'TOTAL ${tipo == 'INGRESO' ? 'INGRESOS' : 'EGRESOS'}', subtotal.toStringAsFixed(2)]);
        rows.add(['', '', '']);
      }
      rows.add(['', 'Saldo Final', saldoFinal.toStringAsFixed(2)]);

      ExportService.showExportDialog(
        context: context,
        title: 'Balance Resumido - Caja $cajaLabel',
        subtitle: subtitle,
        columns: const ['Tipo', 'Tipo de Pago', 'Monto (S/)'],
        rows: rows,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final movs = _movsFiltrados;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Icon(Icons.account_balance_outlined, color: cs.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Balance de Caja — ${r.sesion.codigoCaja}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
              ),
              IconButton(
                icon: Icon(Icons.close, color: cs.onPrimaryContainer),
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          // Mode selector + filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Resumido'), icon: Icon(Icons.bar_chart)),
                  ButtonSegment(value: true,  label: Text('Detallado'), icon: Icon(Icons.list_alt)),
                ],
                selected: {_detallado},
                onSelectionChanged: (s) => setState(() => _detallado = s.first),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _filtroPago,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Pago',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Todos los pagos')),
                  ..._tiposPagoDisponibles.map((t) => DropdownMenuItem<String?>(
                    value: t,
                    child: Text(t),
                  )),
                ],
                onChanged: (v) => setState(() => _filtroPago = v),
              ),
            ]),
          ),

          const Divider(height: 20),

          // Content
          Expanded(
            child: _detallado
                ? _DetalladoView(movs: movs, reporte: r)
                : _ResumidoView(movs: movs, reporte: r),
          ),

          // Footer
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Exportar'),
                onPressed: () => _export(context),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Resumido ──────────────────────────────────────────────────────────────────

class _ResumidoView extends StatelessWidget {
  final List<MovimientoCaja> movs;
  final ReporteCaja reporte;
  const _ResumidoView({required this.movs, required this.reporte});

  @override
  Widget build(BuildContext context) {
    // Group: tipo → tipoPago → total
    final Map<String, Map<String, double>> grupos = {};
    for (final m in movs) {
      final tipo = m.tipo.name; // INGRESO | EGRESO
      final pago = m.tipoPago ?? '(Sin tipo)';
      grupos.putIfAbsent(tipo, () => {})[pago] =
          (grupos[tipo]![pago] ?? 0) + m.monto;
    }

    final totalIngresos = movs
        .where((m) => m.tipo == TipoMovCaja.INGRESO)
        .fold(0.0, (s, m) => s + m.monto);
    final totalEgresos = movs
        .where((m) => m.tipo == TipoMovCaja.EGRESO)
        .fold(0.0, (s, m) => s + m.monto);
    final saldoFiltrado = reporte.sesion.montoApertura + totalIngresos - totalEgresos;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
      // Monto apertura
      _SummaryTile(label: 'Monto apertura', value: reporte.sesion.montoApertura, color: Colors.grey),
      const SizedBox(height: 8),

      for (final tipo in ['INGRESO', 'EGRESO']) ...[
        if (grupos.containsKey(tipo)) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(tipo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: tipo == 'INGRESO' ? Colors.green[700] : Colors.red[700],
                letterSpacing: 0.5,
              )),
          ),
          ...grupos[tipo]!.entries.map((e) => _GroupRow(
            pago: e.key,
            monto: e.value,
            isIngreso: tipo == 'INGRESO',
          )),
          _TotalRow(
            label: 'Total ${tipo == 'INGRESO' ? 'ingresos' : 'egresos'}',
            value: tipo == 'INGRESO' ? totalIngresos : totalEgresos,
            isIngreso: tipo == 'INGRESO',
          ),
          const SizedBox(height: 4),
        ],
      ],

      const Divider(height: 20),
      _SummaryTile(
        label: 'Saldo resultante',
        value: saldoFiltrado,
        color: saldoFiltrado >= 0 ? Colors.blue[700]! : Colors.orange,
        bold: true,
      ),
    ]);
  }
}

class _GroupRow extends StatelessWidget {
  final String pago;
  final double monto;
  final bool isIngreso;
  const _GroupRow({required this.pago, required this.monto, required this.isIngreso});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      const SizedBox(width: 12),
      Expanded(child: Text(pago, style: const TextStyle(fontSize: 13))),
      Text('S/ ${monto.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 13,
          color: isIngreso ? Colors.green[700] : Colors.red[700],
        )),
    ]),
  );
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isIngreso;
  const _TotalRow({required this.label, required this.value, required this.isIngreso});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 2, bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: (isIngreso ? Colors.green : Colors.red).withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
      Text('S/ ${value.toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 13,
          color: isIngreso ? Colors.green[700] : Colors.red[700],
        )),
    ]),
  );
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;
  const _SummaryTile({required this.label, required this.value, required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label,
      style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: Colors.grey[700]))),
    Text('S/ ${value.toStringAsFixed(2)}',
      style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color, fontSize: bold ? 15 : 13)),
  ]);
}

// ── Detallado ─────────────────────────────────────────────────────────────────

class _DetalladoView extends StatelessWidget {
  final List<MovimientoCaja> movs;
  final ReporteCaja reporte;
  const _DetalladoView({required this.movs, required this.reporte});

  @override
  Widget build(BuildContext context) {
    final totalIngresos = movs.where((m) => m.tipo == TipoMovCaja.INGRESO).fold(0.0, (s, m) => s + m.monto);
    final totalEgresos  = movs.where((m) => m.tipo == TipoMovCaja.EGRESO ).fold(0.0, (s, m) => s + m.monto);
    final saldoFinal    = reporte.sesion.montoApertura + totalIngresos - totalEgresos;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Apertura row
        _DetailHeaderRow(
          tipo: '—',
          fecha: reporte.sesion.fechaApertura.substring(0, 10),
          concepto: 'APERTURA DE CAJA',
          referencia: '',
          tipoPago: '',
          monto: reporte.sesion.montoApertura,
          color: Colors.grey[700]!,
        ),
        const Divider(height: 10),

        // Column headers
        const _DetailHeaderLabels(),
        const Divider(height: 8),

        // Rows
        if (movs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: Text('Sin movimientos', style: TextStyle(color: Colors.grey))),
          )
        else
          ...movs.map((m) => _DetailRow(m: m)),

        const Divider(height: 16),

        // Totals
        _DetailTotalRow(label: 'Total Ingresos', value: totalIngresos, color: Colors.green[700]!),
        _DetailTotalRow(label: 'Total Egresos',  value: totalEgresos,  color: Colors.red[700]!),
        const SizedBox(height: 4),
        _DetailTotalRow(
          label: 'Saldo Final',
          value: saldoFinal,
          color: Colors.blue[700]!,
          bold: true,
        ),
      ]),
    );
  }
}

class _DetailHeaderLabels extends StatelessWidget {
  const _DetailHeaderLabels();

  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
    child: Row(children: const [
      SizedBox(width: 52, child: Text('Tipo')),
      SizedBox(width: 72, child: Text('Fecha')),
      Expanded(child: Text('Concepto')),
      SizedBox(width: 64, child: Text('Ref.', overflow: TextOverflow.ellipsis)),
      SizedBox(width: 70, child: Text('Monto', textAlign: TextAlign.right)),
    ]),
  );
}

class _DetailHeaderRow extends StatelessWidget {
  final String tipo, fecha, concepto, referencia, tipoPago;
  final double monto;
  final Color color;
  const _DetailHeaderRow({
    required this.tipo, required this.fecha, required this.concepto,
    required this.referencia, required this.tipoPago, required this.monto, required this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 52, child: Text(tipo, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold))),
      SizedBox(width: 72, child: Text(fecha, style: const TextStyle(fontSize: 11))),
      Expanded(child: Text(concepto, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
      SizedBox(width: 64, child: Text(referencia, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
      SizedBox(width: 70,
        child: Text('S/ ${monto.toStringAsFixed(2)}',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color))),
    ]),
  );
}

class _DetailRow extends StatelessWidget {
  final MovimientoCaja m;
  const _DetailRow({required this.m});

  @override
  Widget build(BuildContext context) {
    final isIngreso = m.tipo == TipoMovCaja.INGRESO;
    final color = isIngreso ? Colors.green[700]! : Colors.red[700]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 52,
            child: Text(isIngreso ? 'INGRESO' : 'EGRESO',
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold))),
          SizedBox(width: 72, child: Text(m.fecha, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(m.concepto, style: const TextStyle(fontSize: 11))),
          SizedBox(width: 64,
            child: Text(m.referencia ?? '', style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 70,
            child: Text('S/ ${m.monto.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color))),
        ]),
        if (m.tipoPago != null)
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(m.tipoPago!, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic)),
          ),
      ]),
    );
  }
}

class _DetailTotalRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;
  const _DetailTotalRow({required this.label, required this.value, required this.color, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Expanded(child: Text(label,
        style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, fontSize: bold ? 14 : 12))),
      Text('S/ ${value.toStringAsFixed(2)}',
        style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, fontSize: bold ? 14 : 12, color: color)),
    ]),
  );
}
