import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/compras_remote_datasource.dart';
import '../../domain/entities/compra.dart';
import '../bloc/compra_bloc.dart';
import '../bloc/compra_event.dart';
import '../bloc/compra_state.dart';

class CompraDetailPage extends StatelessWidget {
  final String compraId;
  const CompraDetailPage({super.key, required this.compraId});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CompraBloc(getIt<ComprasRemoteDataSource>())..add(CompraLoadDetail(compraId)),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle Compra')),
      body: BlocConsumer<CompraBloc, CompraState>(
        listener: (ctx, state) {
          if (state is CompraAnulado) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Compra anulada'), backgroundColor: Colors.orange));
          if (state is CompraError) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        },
        builder: (ctx, state) {
          if (state is CompraDetailLoading || state is CompraSaving) return const Center(child: CircularProgressIndicator());
          final c = switch (state) {
            CompraDetailLoaded(:final compra) => compra,
            CompraAnulado(:final compra) => compra,
            _ => null,
          };
          if (c == null) return const Center(child: CircularProgressIndicator());
          return ListView(padding: const EdgeInsets.all(16), children: [
            _card('Documento',   '${c.codigoDocumento} ${c.numeroDocumento}'),
            _card('Fecha',       c.fecha),
            _card('Proveedor',   c.codigoProveedor),
            _card('Almacén',     c.codigoAlmacen),
            _card('Forma pago',  c.formaPago.name),
            if (c.formaPago == FormaPago.CREDITO) _card('Vencimiento', c.fechaVencimiento ?? '-'),
            _card('Moneda',      '${c.moneda} (T.C. ${c.tipoCambio.toStringAsFixed(4)})'),
            if (c.observacion != null) _card('Observación', c.observacion!),
            _card('Estado',      c.anulado ? 'ANULADA' : 'Vigente'),
            const SizedBox(height: 16),
            Text('Detalle', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...c.detalles.map((d) => ListTile(
              dense: true,
              title: Text(d.descripcionArticulo ?? d.codigoArticulo),
              subtitle: Text('${d.codigoArticulo}  |  ${d.cantidad} × ${d.precioUnitario.toStringAsFixed(4)}'),
              trailing: Text('S/ ${d.importe.toStringAsFixed(2)}'),
            )),
            const Divider(),
            _totRow(ctx, 'Subtotal', c.subtotal),
            _totRow(ctx, 'IGV', c.igv),
            _totRow(ctx, 'Total', c.total, bold: true),
            const SizedBox(height: 24),
            if (!c.anulado)
              OutlinedButton.icon(
                icon: const Icon(Icons.block),
                label: const Text('Anular compra'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _confirm(ctx, c.id),
              ),
          ]);
        },
      ),
    );
  }

  Widget _card(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
    ]),
  );

  Widget _totRow(BuildContext ctx, String label, double v, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      const SizedBox(width: 16),
      SizedBox(width: 90, child: Text('S/ ${v.toStringAsFixed(2)}', textAlign: TextAlign.right,
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
    ]),
  );

  void _confirm(BuildContext context, String id) {
    showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Anular compra'),
      content: const Text('Se revertirán los movimientos de almacén. ¿Continuar?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Anular', style: TextStyle(color: Colors.red))),
      ],
    )).then((ok) { if (ok == true && context.mounted) context.read<CompraBloc>().add(CompraAnular(id)); });
  }
}
