import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/ventas_remote_datasource.dart';
import '../../domain/entities/venta.dart';
import '../bloc/venta_bloc.dart';
import '../bloc/venta_event.dart';
import '../bloc/venta_state.dart';
import '../../../../core/widgets/aries_app_bar.dart';

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
      appBar: AriesAppBar(title: const Text('Detalle Venta')),
      body: BlocConsumer<VentaBloc, VentaState>(
        listener: (ctx, state) {
          if (state is VentaAnulada) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Venta anulada'), backgroundColor: Colors.orange));
          if (state is VentaEliminada) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Venta eliminada'), backgroundColor: Colors.red));
            ctx.pop(true);
          }
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
            _row('Documento',  '${v.abreviaturaDocumento ?? v.codigoDocumento}-${v.serie}-${v.numeroDocumento}'),
            _row('Fecha',      v.fecha),
            _row('Cliente',    v.razonSocialCliente ?? v.codigoCliente),
            _row('Almacén',    v.descripcionAlmacen ?? v.codigoAlmacen),
            _row('Tipo venta', v.tipoVenta.name),
            if (v.tipoVenta == TipoVenta.CREDITO) _row('Vencimiento', v.fechaVencimiento ?? '-'),
            _row('Moneda',     '${v.moneda} (T.C. ${v.tipoCambio.toStringAsFixed(4)})'),
            if (v.observacion != null) _row('Observación', v.observacion!),
            _row('Estado',     v.anulado ? 'ANULADA' : 'Vigente'),
            const SizedBox(height: 16),
            Text('Detalle', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...v.detalles.map((d) {
              final precio  = v.moneda == 'USD' ? d.precioUnitarioUsd : d.precioUnitario;
              final importe = v.moneda == 'USD' ? d.importeUsd : d.importe;
              final cur     = v.moneda == 'USD' ? 'USD' : 'S/';
              return ListTile(
                dense: true,
                title: Text(d.descripcionArticulo ?? d.codigoArticulo),
                subtitle: Text('${d.codigoArticulo}  |  ${d.cantidad} × ${precio.toStringAsFixed(4)}${d.descuentoPct > 0 ? " (-${d.descuentoPct}%)" : ""}'),
                trailing: Text('$cur ${importe.toStringAsFixed(2)}'),
              );
            }),
            const Divider(),
            if (v.moneda == 'PEN') ...[
              _totRow('Subtotal', v.subtotal, 'S/'),
              _totRow('IGV',      v.igv,      'S/'),
              _totRow('Total',    v.total,    'S/', bold: true),
              if (v.tipoCambio != 1.0) ...[
                const SizedBox(height: 4),
                _totRow('≈ Equivalente USD', v.totalUsd, 'USD', color: Colors.blue.shade700),
              ],
            ] else ...[
              _totRow('Subtotal', v.subtotalUsd, 'USD'),
              _totRow('IGV',      v.igvUsd,      'USD'),
              _totRow('Total',    v.totalUsd,    'USD', bold: true),
              const SizedBox(height: 4),
              _totRow('≈ Equivalente S/', v.total, 'S/', color: Colors.orange.shade700),
            ],
            const SizedBox(height: 24),
            if (!v.anulado)
              OutlinedButton.icon(
                icon: const Icon(Icons.block),
                label: const Text('Anular venta'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _confirm(ctx, v.id),
              ),
            if (v.anulado) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Eliminar venta'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade900),
                onPressed: () => _confirmEliminar(ctx, v.id),
              ),
            ],
          ]);
        },
      ),
    );
  }

  Widget _row(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [
    SizedBox(width: 110, child: Text(l, style: const TextStyle(color: Colors.grey))),
    Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500))),
  ]));

  Widget _totRow(String l, double v, String cur, {bool bold = false, Color? color}) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
    Text(l, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
    const SizedBox(width: 16),
    SizedBox(width: 110, child: Text('$cur ${v.toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color))),
  ]));

  void _confirm(BuildContext context, String id) {
    showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Anular venta'),
      content: const Text('Se revertirán los movimientos de almacén y la CxC asociada. ¿Continuar?'),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Anular'),
        ),
      ],
    )).then((ok) { if (ok == true && context.mounted) context.read<VentaBloc>().add(VentaAnular(id)); });
  }

  void _confirmEliminar(BuildContext context, String id) {
    showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Eliminar venta'),
      content: const Text('Esta acción es irreversible. Se eliminará permanentemente la venta y su detalle. ¿Desea continuar?'),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    )).then((ok) { if (ok == true && context.mounted) context.read<VentaBloc>().add(VentaEliminar(id)); });
  }
}
