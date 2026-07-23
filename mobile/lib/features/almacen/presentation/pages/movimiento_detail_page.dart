import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/movimiento.dart';
import '../bloc/movimiento_bloc.dart';
import '../bloc/movimiento_event.dart';
import '../bloc/movimiento_state.dart';
import '../../domain/repositories/movimiento_repository.dart';
import '../../../../core/widgets/aries_app_bar.dart';

class MovimientoDetailPage extends StatelessWidget {
  final String movimientoId;
  const MovimientoDetailPage({super.key, required this.movimientoId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MovimientoBloc(getIt<MovimientoRepository>())
        ..add(MovimientoLoadDetail(movimientoId)),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AriesAppBar(title: const Text('Movimiento')),
      body: BlocConsumer<MovimientoBloc, MovimientoState>(
        listener: (ctx, state) {
          if (state is MovimientoAnulado) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Movimiento anulado'), backgroundColor: Colors.orange),
            );
          }
          if (state is MovimientoEliminado) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Movimiento eliminado'), backgroundColor: Colors.red),
            );
            Navigator.pop(ctx, true);
          }
          if (state is MovimientoError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (ctx, state) {
          if (state is MovimientoDetailLoading || state is MovimientoSaving) {
            return const Center(child: CircularProgressIndicator());
          }

          final mov = switch (state) {
            MovimientoDetailLoaded(:final movimiento) => movimiento,
            MovimientoAnulado(:final movimiento) => movimiento,
            _ => null,
          };

          if (mov == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return _MovimientoBody(mov: mov);
        },
      ),
    );
  }
}

class _MovimientoBody extends StatelessWidget {
  final Movimiento mov;
  const _MovimientoBody({required this.mov});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(mov: mov),
        const SizedBox(height: 16),
        Text('Detalles', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...mov.detalles.map((d) => ListTile(
              dense: true,
              title: Text(d.descripcionArticulo ?? d.codigoArticulo),
              subtitle: Text('${d.cantidad} × ${d.precioUnitario.toStringAsFixed(4)}'),
              trailing: Text('S/ ${d.importe.toStringAsFixed(2)}'),
            )),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (!mov.anulado) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.block),
            label: const Text('Anular movimiento'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _confirmAnular(context, mov.id),
          ),
        ],
        if (mov.anulado) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: const Text('Eliminar movimiento'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade900),
            onPressed: () => _confirmEliminar(context, mov.id),
          ),
        ],
      ],
    );
  }

  void _confirmEliminar(BuildContext context, String id) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Eliminar movimiento'),
          IconButton(
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context, false),
          ),
        ]),
        content: const Text('Esta acción es irreversible. Se eliminará permanentemente el movimiento y su detalle. ¿Desea continuar?'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<MovimientoBloc>().add(MovimientoEliminar(id));
      }
    });
  }

  void _confirmAnular(BuildContext context, String id) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Anular movimiento'),
          IconButton(
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context, false),
          ),
        ]),
        content: const Text('Esta acción no puede deshacerse sin recalcular el kardex. ¿Continuar?'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<MovimientoBloc>().add(MovimientoAnular(id));
      }
    });
  }
}

class _InfoCard extends StatelessWidget {
  final Movimiento mov;
  const _InfoCard({required this.mov});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Row('Tipo', mov.tipo.name),
            _Row('Documento', '${mov.abreviaturaDocumento ?? mov.codigoDocumento} ${mov.numeroDocumento}'),
            _Row('Fecha', mov.fecha),
            _Row('Almacén origen', mov.descripcionAlmacenOrigen ?? mov.codigoAlmacenOrigen),
            if (mov.codigoAlmacenDest != null) _Row('Almacén destino', mov.descripcionAlmacenDest ?? mov.codigoAlmacenDest!),
            if (mov.observacion != null) _Row('Observación', mov.observacion!),
            if (mov.concepto != null) _Row('Concepto', mov.concepto!),
            _Row('Total', 'S/ ${mov.total.toStringAsFixed(2)}'),
            _Row('Estado', mov.anulado ? 'ANULADO' : 'Vigente'),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
