import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/cxp_remote_datasource.dart';
import '../../domain/entities/cuenta_pagar.dart';
import '../bloc/cxp_bloc.dart';

class CxPDetailPage extends StatelessWidget {
  final String cxpId;
  const CxPDetailPage({super.key, required this.cxpId});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CxPBloc(getIt<CxPRemoteDataSource>())..add(CxPLoadDetail(cxpId)),
    child: _View(cxpId: cxpId),
  );
}

class _View extends StatelessWidget {
  final String cxpId;
  const _View({required this.cxpId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta por Pagar')),
      body: BlocConsumer<CxPBloc, CxPState>(
        listener: (ctx, s) {
          if (s is CxPError) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(s.message), backgroundColor: Colors.red));
          if (s is CxPPagoRegistrado) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Pago registrado'), backgroundColor: Colors.green));
            ctx.read<CxPBloc>().add(CxPLoadDetail(cxpId));
          }
          if (s is CxPRenovada) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('CxP renovada'), backgroundColor: Colors.blue));
            Navigator.of(ctx).pop();
          }
        },
        builder: (ctx, s) {
          if (s is CxPLoading || s is CxPSaving) return const Center(child: CircularProgressIndicator());
          if (s is! CxPDetailLoaded) return const Center(child: CircularProgressIndicator());
          final cxp = s.cxp;
          final pagos = s.pagos;
          return ListView(padding: const EdgeInsets.all(16), children: [
            _card(cxp),
            const SizedBox(height: 16),
            Text('Pagos (${pagos.length})', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...pagos.map((p) => Card(child: ListTile(
              leading: const Icon(Icons.receipt),
              title: Text('Voucher ${p.numeroVoucher} — ${p.tipoPago}'),
              subtitle: Text(p.fecha),
              trailing: Text('S/ ${p.monto.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            ))),
            if (pagos.isEmpty) const Text('Sin pagos registrados', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            if (cxp.pendiente) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Registrar pago'),
                onPressed: () => _showPagoDialog(ctx, cxp),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.autorenew),
                label: const Text('Renovar CxP'),
                onPressed: () => _showRenovarDialog(ctx, cxp),
              ),
            ],
          ]);
        },
      ),
    );
  }

  Widget _card(CuentaPagar cxp) => Card(child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Provisión ${cxp.numeroProvision}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Chip(
          label: Text(cxp.pendiente ? 'PENDIENTE' : 'CANCELADA'),
          backgroundColor: cxp.pendiente ? Colors.orange[100] : Colors.green[100],
        ),
      ]),
      const Divider(),
      _row('Proveedor', cxp.codigoProveedor),
      _row('Documento', '${cxp.codigoDocumento} ${cxp.numeroDocumento}'),
      _row('Tipo', cxp.tipo.name),
      _row('Emisión', cxp.fechaEmision),
      if (cxp.fechaVencimiento != null) _row('Vencimiento', cxp.fechaVencimiento!),
      const Divider(),
      _row('Total', 'S/ ${cxp.montoTotal.toStringAsFixed(2)}'),
      _row('Pagado', 'S/ ${cxp.montoPagado.toStringAsFixed(2)}'),
      _row('Saldo', 'S/ ${cxp.saldo.toStringAsFixed(2)}', bold: true),
      if (cxp.interes > 0) _row('Interés', 'S/ ${cxp.interes.toStringAsFixed(2)}'),
      if (cxp.referencia != null) _row('Referencia', cxp.referencia!),
    ]),
  ));

  Widget _row(String l, String v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      SizedBox(width: 110, child: Text(l, style: const TextStyle(color: Colors.grey))),
      Expanded(child: Text(v, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
    ]),
  );

  void _showPagoDialog(BuildContext ctx, CuentaPagar cxp) {
    final voucherCtrl = TextEditingController();
    final montoCtrl   = TextEditingController(text: cxp.saldo.toStringAsFixed(2));
    final operCtrl    = TextEditingController();
    String tipoPago   = 'EFECTIVO';
    DateTime fecha    = DateTime.now();

    showDialog(context: ctx, builder: (dctx) => StatefulBuilder(builder: (dctx, setSt) => AlertDialog(
      title: const Text('Registrar Pago'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Saldo: S/ ${cxp.saldo.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(controller: voucherCtrl, decoration: const InputDecoration(labelText: 'N° Voucher')),
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
            if (voucherCtrl.text.isEmpty || m == null || m <= 0) return;
            Navigator.pop(dctx);
            ctx.read<CxPBloc>().add(CxPRegistrarPago(
              cuentaPagarId: cxp.id,
              numeroVoucher: voucherCtrl.text.trim(),
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

  void _showRenovarDialog(BuildContext ctx, CuentaPagar cxp) {
    DateTime nuevaFecha = DateTime.now().add(const Duration(days: 30));
    final interesCtrl   = TextEditingController(text: '0');
    final docCtrl       = TextEditingController(text: cxp.codigoDocumento);
    final numDocCtrl    = TextEditingController(text: cxp.numeroDocumento);

    showDialog(context: ctx, builder: (dctx) => StatefulBuilder(builder: (dctx, setSt) => AlertDialog(
      title: const Text('Renovar CxP'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Saldo actual: S/ ${cxp.saldo.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
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
            ctx.read<CxPBloc>().add(CxPRenovar(
              id: cxp.id,
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
