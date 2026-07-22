import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/cxc_remote_datasource.dart';
import '../../domain/entities/cuenta_cobrar.dart';
import '../bloc/cxc_bloc.dart';
import '../../../../core/widgets/aries_app_bar.dart';
import '../../../../core/widgets/number_form_field.dart';
import '../../../tablas/data/datasources/tablas_remote_datasource.dart';
import '../../../tablas/data/models/tabla_model.dart';
import '../../../tablas/domain/entities/tabla_base.dart';

class CxCDetailPage extends StatelessWidget {
  final String cxcId;
  const CxCDetailPage({super.key, required this.cxcId});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CxCBloc(getIt<CxCRemoteDataSource>())..add(CxCLoadDetail(cxcId)),
    child: _View(cxcId: cxcId),
  );
}

class _View extends StatelessWidget {
  final String cxcId;
  const _View({required this.cxcId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AriesAppBar(title: const Text('Cuenta por Cobrar')),
      body: BlocConsumer<CxCBloc, CxCState>(
        listener: (ctx, s) {
          if (s is CxCError) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(s.message), backgroundColor: Colors.red));
          if (s is CxCCobroRegistrado) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Cobro registrado'), backgroundColor: Colors.green));
            ctx.read<CxCBloc>().add(CxCLoadDetail(cxcId));
          }
          if (s is CxCRenovada) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text('Renovación generada: ${s.nuevas.length} letra(s)'),
              backgroundColor: Colors.blue,
            ));
            Navigator.of(ctx).pop();
          }
        },
        builder: (ctx, s) {
          if (s is CxCLoading || s is CxCSaving) return const Center(child: CircularProgressIndicator());
          if (s is CxCError) return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(s.message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => ctx.read<CxCBloc>().add(CxCLoadDetail(cxcId)), child: const Text('Reintentar')),
            ]),
          ));
          if (s is! CxCDetailLoaded) return const Center(child: CircularProgressIndicator());
          final cxc = s.cxc;
          final cobros = s.cobros;
          return ListView(padding: const EdgeInsets.all(16), children: [
            _card(cxc, ctx),
            const SizedBox(height: 16),
            Text('Cobros (${cobros.length})', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...cobros.map((c) => Card(child: ListTile(
              leading: const Icon(Icons.payment),
              title: Text('Recibo ${c.numeroRecibo} — ${c.tipoPago}'),
              subtitle: Text(c.fecha),
              trailing: Text('S/ ${c.monto.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            ))),
            if (cobros.isEmpty) const Text('Sin cobros registrados', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            if (cxc.pendiente) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.attach_money),
                label: const Text('Registrar cobro'),
                onPressed: () => _showCobroDialog(ctx, cxc),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.autorenew),
                label: const Text('Renovar CxC'),
                onPressed: () => _showRenovarDialog(ctx, cxc),
              ),
            ],
          ]);
        },
      ),
    );
  }

  Widget _card(CuentaCobrar cxc, BuildContext ctx) => Card(child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Provisión ${cxc.numeroProvision}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Chip(
          label: Text(cxc.pendiente ? 'PENDIENTE' : 'CANCELADA'),
          backgroundColor: cxc.pendiente ? Colors.orange[100] : Colors.green[100],
        ),
      ]),
      const Divider(),
      _row('Cliente', cxc.razonSocialCliente ?? cxc.codigoCliente),
      _row('Documento', '${cxc.abreviaturaDocumento ?? cxc.codigoDocumento}-${cxc.serieDocumento ?? '0001'}-${cxc.numeroDocumento}'),
      _row('Tipo', cxc.tipo.name),
      _row('Emisión', cxc.fechaEmision),
      if (cxc.fechaVencimiento != null) _row('Vencimiento', cxc.fechaVencimiento!),
      if (cxc.numeroCuota > 0 && cxc.totalCuotas > 1) _row('Cuota', '${cxc.numeroCuota} / ${cxc.totalCuotas}'),
      const Divider(),
      _row('Total', 'S/ ${cxc.montoTotal.toStringAsFixed(2)}'),
      _row('Pagado', 'S/ ${cxc.montoPagado.toStringAsFixed(2)}'),
      _row('Saldo', 'S/ ${cxc.saldo.toStringAsFixed(2)}', bold: true),
      if (cxc.interes > 0) _row('Interés', 'S/ ${cxc.interes.toStringAsFixed(2)}'),
      if (cxc.referencia != null) _row('Referencia', cxc.referencia!),
    ]),
  ));

  Widget _row(String l, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      SizedBox(width: 110, child: Text(l, style: const TextStyle(color: Colors.grey))),
      Expanded(child: Text(v, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
    ]),
  );

  void _showCobroDialog(BuildContext ctx, CuentaCobrar cxc) {
    final reciboCtrl = TextEditingController();
    final montoCtrl  = TextEditingController(text: cxc.saldo.toStringAsFixed(2));
    final operCtrl   = TextEditingController();
    List<TipoPago> tiposPago = [];
    TipoPago? tipoPagoSeleccionado;
    bool fetched = false;
    DateTime fecha   = DateTime.now();

    showDialog(context: ctx, builder: (dctx) => StatefulBuilder(builder: (dctx, setSt) {
      if (!fetched) {
        fetched = true;
        getIt<TablasRemoteDataSource>().list('tipos-pago', activo: true).then((raw) {
          setSt(() => tiposPago = raw.map(TablaModel.tipoPagoFromJson).toList());
        }).catchError((_) {});
      }
      return AlertDialog(
      title: const Text('Registrar Cobro'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Saldo: S/ ${cxc.saldo.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(controller: reciboCtrl, decoration: const InputDecoration(labelText: 'N° Recibo')),
        const SizedBox(height: 8),
        NumberFormField(controller: montoCtrl, decoration: const InputDecoration(labelText: 'Monto')),
        const SizedBox(height: 8),
        DropdownButtonFormField<TipoPago>(
          value: tipoPagoSeleccionado,
          decoration: const InputDecoration(labelText: 'Tipo Pago'),
          items: tiposPago.map((t) => DropdownMenuItem(value: t, child: Text(t.descripcion))).toList(),
          onChanged: (v) => setSt(() {
            tipoPagoSeleccionado = v;
            operCtrl.clear();
          }),
        ),
        if (tipoPagoSeleccionado?.requiereOperacion == true)
          TextField(controller: operCtrl, decoration: const InputDecoration(labelText: 'N° Operación')),
        const SizedBox(height: 8),
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
            if (reciboCtrl.text.isEmpty || m == null || m <= 0 || tipoPagoSeleccionado == null) return;
            Navigator.pop(dctx);
            ctx.read<CxCBloc>().add(CxCRegistrarCobro(
              cuentaCobrarId: cxc.id,
              numeroRecibo: reciboCtrl.text.trim(),
              fecha: fecha.toIso8601String().substring(0, 10),
              tipoPago: tipoPagoSeleccionado!.descripcion,
              monto: m,
              numeroOperacion: operCtrl.text.isNotEmpty ? operCtrl.text.trim() : null,
            ));
          },
          child: const Text('Guardar'),
        ),
      ],
    );}));
  }

  void _showRenovarDialog(BuildContext ctx, CuentaCobrar cxc) {
    int step = 0;
    final letraBaseCtrl  = TextEditingController(text: 'L-001');
    final tasaCtrl       = TextEditingController(text: '0');
    final cuotasCtrl     = TextEditingController(text: '3');
    final plazoDiasCtrl  = TextEditingController(text: '30');
    DateTime fechaInicio = DateTime.now().add(const Duration(days: 30));
    List<_CuotaRen> cronograma = [];

    List<_CuotaRen> generarCronograma() {
      final tasa      = double.tryParse(tasaCtrl.text) ?? 0;
      final numCuotas = (int.tryParse(cuotasCtrl.text) ?? 1).clamp(1, 120);
      final plazo     = (int.tryParse(plazoDiasCtrl.text) ?? 30).clamp(1, 3650);
      final total     = double.parse((cxc.saldo * (1 + tasa / 100)).toStringAsFixed(2));
      final montoBase = double.parse((total / numCuotas).toStringAsFixed(2));
      final letraBase = letraBaseCtrl.text.trim().isEmpty ? 'L' : letraBaseCtrl.text.trim();
      final result    = <_CuotaRen>[];
      double acumulado = 0;
      for (int i = 0; i < numCuotas; i++) {
        final esUltima = i == numCuotas - 1;
        final monto = esUltima
          ? double.parse((total - acumulado).toStringAsFixed(2))
          : montoBase;
        acumulado = double.parse((acumulado + monto).toStringAsFixed(2));
        result.add(_CuotaRen(
          numeroCuota: i + 1,
          letraCtrl: TextEditingController(
            text: '$letraBase-${(i + 1).toString().padLeft(3, '0')}'),
          fechaVencimiento: fechaInicio
            .add(Duration(days: plazo * i))
            .toIso8601String().substring(0, 10),
          monto: monto,
        ));
      }
      return result;
    }

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dctx) => StatefulBuilder(builder: (dctx, setSt) {
        final titles = ['Configuración', 'Cronograma', 'Resumen'];

        Widget buildStep0() => Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Saldo a renovar: S/ ${cxc.saldo.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(controller: letraBaseCtrl,
            decoration: const InputDecoration(labelText: 'Base N° Letra (ej. L-001)', isDense: true)),
          const SizedBox(height: 8),
          NumberFormField(controller: tasaCtrl,
            decoration: const InputDecoration(labelText: 'Tasa de interés (%)', isDense: true)),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('Fecha inicio: ${fechaInicio.toIso8601String().substring(0, 10)}'),
            trailing: const Icon(Icons.calendar_today, size: 18),
            onTap: () async {
              final d = await showDatePicker(
                context: dctx, initialDate: fechaInicio,
                firstDate: DateTime.now(), lastDate: DateTime(2035));
              if (d != null) setSt(() => fechaInicio = d);
            },
          ),
          NumberFormField(controller: cuotasCtrl, allowDecimal: false,
            decoration: const InputDecoration(labelText: 'Cantidad de cuotas', isDense: true)),
          const SizedBox(height: 8),
          NumberFormField(controller: plazoDiasCtrl, allowDecimal: false,
            decoration: const InputDecoration(labelText: 'Plazo entre cuotas (días)', isDense: true)),
        ]);

        Widget buildStep1() => Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Edita el N° de letra si es necesario:',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          ...cronograma.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(width: 20,
                child: Text('${c.numeroCuota}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              const SizedBox(width: 6),
              Expanded(flex: 3, child: TextField(
                controller: c.letraCtrl,
                decoration: const InputDecoration(
                  labelText: 'N° Letra', isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
              )),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(c.fechaVencimiento, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text('S/ ${c.monto.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
            ]),
          )),
        ]);

        Widget buildStep2() {
          final total = cronograma.fold(0.0, (s, c) => s + c.monto);
          return Column(mainAxisSize: MainAxisSize.min, children: [
            _sumRow('Cuotas', '${cronograma.length}'),
            _sumRow('Saldo original', 'S/ ${cxc.saldo.toStringAsFixed(2)}'),
            _sumRow('Total letras', 'S/ ${total.toStringAsFixed(2)}'),
            _sumRow('Venc. final', cronograma.isNotEmpty ? cronograma.last.fechaVencimiento : '-'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                'Al confirmar, la deuda original quedará cancelada y se crearán las letras indicadas.',
                style: TextStyle(fontSize: 11, color: Colors.deepOrange),
                textAlign: TextAlign.center,
              ),
            ),
          ]);
        }

        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 580),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Renovar CxC — ${titles[step]}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(height: 16),
                  Flexible(child: SingleChildScrollView(
                    child: step == 0 ? buildStep0()
                      : step == 1 ? buildStep1()
                      : buildStep2(),
                  )),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      step > 0
                        ? TextButton(
                            onPressed: () => setSt(() => step--),
                            child: const Text('Atrás'))
                        : OutlinedButton(
                            onPressed: () => Navigator.pop(dctx),
                            child: const Text('Cancelar')),
                      FilledButton(
                        onPressed: () {
                          if (step == 0) {
                            final nc = int.tryParse(cuotasCtrl.text) ?? 0;
                            if (nc <= 0) return;
                            setSt(() {
                              cronograma = generarCronograma();
                              step = 1;
                            });
                          } else if (step == 1) {
                            setSt(() => step = 2);
                          } else {
                            Navigator.pop(dctx);
                            ctx.read<CxCBloc>().add(CxCRenovar(
                              id: cxc.id,
                              cuotas: cronograma.map((c) => {
                                'numeroCuota': c.numeroCuota,
                                'numeroLetra': c.letraCtrl.text.trim(),
                                'fechaVencimiento': c.fechaVencimiento,
                                'monto': c.monto,
                              }).toList(),
                            ));
                          }
                        },
                        child: Text(step < 2 ? 'Siguiente' : 'Renovar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _sumRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]),
  );
}

class _CuotaRen {
  final int numeroCuota;
  final TextEditingController letraCtrl;
  final String fechaVencimiento;
  final double monto;
  _CuotaRen({
    required this.numeroCuota,
    required this.letraCtrl,
    required this.fechaVencimiento,
    required this.monto,
  });
}
