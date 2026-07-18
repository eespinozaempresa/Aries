import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
          if (state is CompraEliminada) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Compra eliminada'), backgroundColor: Colors.red));
            ctx.pop(true);
          }
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
            _card('Proveedor',   c.razonSocialProveedor ?? c.codigoProveedor),
            _card('Almacén',     c.descripcionAlmacen ?? c.codigoAlmacen),
            _card('Forma pago',  c.formaPago.name),
            if (c.formaPago == FormaPago.CREDITO) _card('Vencimiento', c.fechaVencimiento ?? '-'),
            _card('Moneda',      '${c.moneda} (T.C. ${c.tipoCambio.toStringAsFixed(4)})'),
            if (c.observacion != null) _card('Observación', c.observacion!),
            _card('Estado',      c.anulado ? 'ANULADA' : 'Vigente'),
            const SizedBox(height: 16),
            Text('Detalle', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...c.detalles.map((d) {
              final precio  = c.moneda == 'USD' ? d.precioUnitarioUsd : d.precioUnitario;
              final importe = c.moneda == 'USD' ? d.importeUsd : d.importe;
              final cur     = c.moneda == 'USD' ? 'USD' : 'S/';
              return ListTile(
                dense: true,
                title: Text(d.descripcionArticulo ?? d.codigoArticulo),
                subtitle: Text('${d.codigoArticulo}  |  ${d.cantidad} × ${precio.toStringAsFixed(4)}'),
                trailing: Text('$cur ${importe.toStringAsFixed(2)}'),
              );
            }),
            const Divider(),
            if (c.moneda == 'PEN') ...[
              _totRow('Subtotal', c.subtotal, 'S/'),
              _totRow('IGV',      c.igv,      'S/'),
              _totRow('Total',    c.total,    'S/', bold: true),
              if (c.tipoCambio != 1.0) ...[
                const SizedBox(height: 4),
                _totRow('≈ Equivalente USD', c.totalUsd, 'USD', color: Colors.blue.shade700),
              ],
            ] else ...[
              _totRow('Subtotal', c.subtotalUsd, 'USD'),
              _totRow('IGV',      c.igvUsd,      'USD'),
              _totRow('Total',    c.totalUsd,    'USD', bold: true),
              const SizedBox(height: 4),
              _totRow('≈ Equivalente S/', c.total, 'S/', color: Colors.orange.shade700),
            ],
            const SizedBox(height: 24),
            if (!c.anulado)
              OutlinedButton.icon(
                icon: const Icon(Icons.block),
                label: const Text('Anular compra'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _confirm(ctx, c.id),
              ),
            if (c.anulado) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text('Eliminar compra'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade900),
                onPressed: () => _confirmEliminar(ctx, c.id),
              ),
            ],
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

  Widget _totRow(String label, double v, String cur, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
      const SizedBox(width: 16),
      SizedBox(width: 110, child: Text('$cur ${v.toStringAsFixed(2)}', textAlign: TextAlign.right,
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color))),
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

  void _confirmEliminar(BuildContext context, String id) {
    showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Eliminar compra'),
      content: const Text('Esta acción es irreversible. Se eliminará permanentemente la compra y su detalle. ¿Desea continuar?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
      ],
    )).then((ok) { if (ok == true && context.mounted) context.read<CompraBloc>().add(CompraEliminar(id)); });
  }
}
