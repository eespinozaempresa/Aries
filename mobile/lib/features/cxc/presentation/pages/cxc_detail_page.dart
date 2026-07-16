import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/cxc_remote_datasource.dart';
import '../../domain/entities/cuenta_cobrar.dart';
import '../bloc/cxc_bloc.dart';

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
      appBar: AppBar(title: const Text('Cuenta por Cobrar')),
      body: BlocConsumer<CxCBloc, CxCState>(
        listener: (ctx, s) {
          if (s is CxCError) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(s.message), backgroundColor: Colors.red));
          if (s is CxCCobroRegistrado) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Cobro registrado'), backgroundColor: Colors.green));
            ctx.read<CxCBloc>().add(CxCLoadDetail(cxcId));
          }
          if (s is CxCRenovada) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('CxC renovada'), backgroundColor: Colors.blue));
            Navigator.of(ctx).pop();
          }
        },
        builder: (ctx, s) {
          if (s is CxCLoading || s is CxCSaving) return const Center(child: CircularProgressIndicator());
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
      _row('Cliente', cxc.codigoCliente),
      _row('Documento', '${cxc.codigoDocumento} ${cxc.numeroDocumento}'),
      _row('Tipo', cxc.tipo.name),
      _row('Emisión', cxc.fechaEmision),
      if (cxc.fechaVencimiento != null) _row('Vencimiento', cxc.fechaVencimiento!),
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
    String tipoPago  = 'EFECTIVO';
    DateTime fecha   = DateTime.now();

    showDialog(context: ctx, builder: (dctx) => StatefulBuilder(builder: (dctx, setSt) => AlertDialog(
      title: const Text('Registrar Cobro'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Saldo: S/ ${cxc.saldo.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(controller: reciboCtrl, decoration: const InputDecoration(labelText: 'N° Recibo')),
        const SizedBox(height: 8),
        TextField(controller: montoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: tipoPago,
          decoration: const InputDecoration(labelText: 'Tipo Pago'),
          items: ['EFECTIVO', 'TRANSFERENCIA', 'CHEQUE']
            .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setSt(() => tipoPago = v!),
        ),
        if (tipoPago != 'EFECTIVO')
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
        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final m = double.tryParse(montoCtrl.text);
            if (reciboCtrl.text.isEmpty || m == null || m <= 0) return;
            Navigator.pop(dctx);
            ctx.read<CxCBloc>().add(CxCRegistrarCobro(
              cuentaCobrarId: cxc.id,
              numeroRecibo: reciboCtrl.text.trim(),
              fecha: fecha.toIso8601String().substring(0, 10),
              tipoPago: tipoPago,
              monto: m,
              numeroOperacion: operCtrl.text.isNotEmpty ? operCtrl.text.trim() : null,
            ));
          },
          child: const Text('Guardar'),
        ),
      ],
    )));
  }

  void _showRenovarDialog(BuildContext ctx, CuentaCobrar cxc) {
    DateTime nuevaFecha = DateTime.now().add(const Duration(days: 30));
    final interesCtrl  = TextEditingController(text: '0');
    final docCtrl      = TextEditingController(text: cxc.codigoDocumento);
    final numDocCtrl   = TextEditingController(text: cxc.numeroDocumento);

    showDialog(context: ctx, builder: (dctx) => StatefulBuilder(builder: (dctx, setSt) => AlertDialog(
      title: const Text('Renovar CxC'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Saldo actual: S/ ${cxc.saldo.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Nueva venc.: ${nuevaFecha.toIso8601String().substring(0, 10)}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final d = await showDatePicker(context: dctx, initialDate: nuevaFecha,
              firstDate: DateTime.now(), lastDate: DateTime(2030));
            if (d != null) setSt(() => nuevaFecha = d);
          },
        ),
        TextField(controller: interesCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Interés (S/)')),
        TextField(controller: docCtrl, decoration: const InputDecoration(labelText: 'Código documento')),
        TextField(controller: numDocCtrl, decoration: const InputDecoration(labelText: 'N° documento')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dctx);
            ctx.read<CxCBloc>().add(CxCRenovar(
              id: cxc.id,
              nuevaFechaVencimiento: nuevaFecha.toIso8601String().substring(0, 10),
              interes: double.tryParse(interesCtrl.text),
              codigoDocumento: docCtrl.text.trim(),
              numeroDocumento: numDocCtrl.text.trim(),
            ));
          },
          child: const Text('Renovar'),
        ),
      ],
    )));
  }
}
