import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/ventas_remote_datasource.dart';
import '../../domain/entities/venta.dart';
import '../bloc/venta_bloc.dart';
import '../bloc/venta_event.dart';
import '../bloc/venta_state.dart';

class VentaDetailPage extends StatelessWidget {
  final String ventaId;
  const VentaDetailPage({super.key, required this.ventaId});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => VentaBloc(getIt<VentasRemoteDataSource>())..add(VentaLoadDetail(ventaId)),
    child: const _View(),
  );
}

class _View extends StatelessWidget {
  const _View();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle Venta')),
      body: BlocConsumer<VentaBloc, VentaState>(
        listener: (ctx, state) {
          if (state is VentaAnulada) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Venta anulada'), backgroundColor: Colors.orange));
          if (state is VentaError) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        },
        builder: (ctx, state) {
          if (state is VentaDetailLoading || state is VentaSaving) return const Center(child: CircularProgressIndicator());
          final v = switch (state) {
            VentaDetailLoaded(:final venta) => venta,
            VentaAnulada(:final venta) => venta,
            _ => null,
          };
          if (v == null) return const Center(child: CircularProgressIndicator());
          return ListView(padding: const EdgeInsets.all(16), children: [
            _row('Documento',  '${v.codigoDocumento} ${v.numeroDocumento}'),
            _row('Fecha',      v.fecha),
            _row('Cliente',    v.codigoCliente),
            _row('Almacén',    v.codigoAlmacen),
            _row('Tipo venta', v.tipoVenta.name),
            if (v.tipoVenta == TipoVenta.CREDITO) _row('Vencimiento', v.fechaVencimiento ?? '-'),
            if (v.observacion != null) _row('Observación', v.observacion!),
            _row('Estado',     v.anulado ? 'ANULADA' : 'Vigente'),
            const SizedBox(height: 16),
            Text('Detalle', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...v.detalles.map((d) => ListTile(
              dense: true,
              title: Text(d.descripcionArticulo ?? d.codigoArticulo),
              subtitle: Text('${d.codigoArticulo}  |  ${d.cantidad} × ${d.precioUnitario.toStringAsFixed(4)}${d.descuentoPct > 0 ? " (-${d.descuentoPct}%)" : ""}'),
              trailing: Text('S/ ${d.importe.toStringAsFixed(2)}'),
            )),
            const Divider(),
            _totRow('Subtotal', v.subtotal),
            _totRow('IGV',      v.igv),
            _totRow('Total',    v.total, bold: true),
            const SizedBox(height: 24),
            if (!v.anulado)
              OutlinedButton.icon(
                icon: const Icon(Icons.block),
                label: const Text('Anular venta'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _confirm(ctx, v.id),
              ),
          ]);
        },
      ),
    );
  }

  Widget _row(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
    SizedBox(width: 110, child: Text(l, style: const TextStyle(color: Colors.grey))),
    Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500))),
  ]));

  Widget _totRow(String l, double v, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
    Text(l, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    const SizedBox(width: 16),
    SizedBox(width: 90, child: Text('S/ ${v.toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
  ]));

  void _confirm(BuildContext context, String id) {
    showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Anular venta'),
      content: const Text('Se revertirán los movimientos de almacén y la CxC asociada. ¿Continuar?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Anular', style: TextStyle(color: Colors.red))),
      ],
    )).then((ok) { if (ok == true && context.mounted) context.read<VentaBloc>().add(VentaAnular(id)); });
  }
}
