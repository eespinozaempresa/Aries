import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/almacen.dart';
import '../../domain/repositories/almacen_repository.dart';
import '../bloc/almacenes_bloc.dart';
import '../bloc/maestro_list_event.dart';
import '../bloc/maestro_list_state.dart';

class AlmacenesListPage extends StatelessWidget {
  const AlmacenesListPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => AlmacenesBloc(getIt<AlmacenRepository>())..add(MaestroListLoad()),
        child: const _AlmacenesView(),
      );
}

class _AlmacenesView extends StatefulWidget {
  const _AlmacenesView();
  @override
  State<_AlmacenesView> createState() => _AlmacenesViewState();
}

class _AlmacenesViewState extends State<_AlmacenesView> {
  final _ctrl = TextEditingController();
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Almacenes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await context.push<bool>('/maestros/almacenes/nuevo');
          if (saved == true && context.mounted) {
            context.read<AlmacenesBloc>().add(const MaestroListRefresh());
          }
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AlmacenesBloc, MaestroListState<Almacen>>(
        builder: (ctx, state) {
          if (state is MaestroListLoading<Almacen>) return const Center(child: CircularProgressIndicator());
          if (state is MaestroListError<Almacen>) return Center(child: Text(state.message, style: TextStyle(color: cs.error)));

          final items = state is MaestroListLoaded<Almacen> ? state.items : <Almacen>[];
          return RefreshIndicator(
            onRefresh: () async => ctx.read<AlmacenesBloc>().add(const MaestroListRefresh()),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final a = items[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: a.activo ? cs.primaryContainer : cs.surfaceContainerHighest,
                    child: Text(a.codigo,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                            color: a.activo ? cs.primary : cs.onSurfaceVariant)),
                  ),
                  title: Text(a.descripcion, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('${a.tipo}${a.ubicacion != null ? '  |  ${a.ubicacion}' : ''}',
                      style: const TextStyle(fontSize: 12)),
                  onTap: () async {
                    final saved = await ctx.push<bool>('/maestros/almacenes/${a.id}');
                    if (saved == true && ctx.mounted) ctx.read<AlmacenesBloc>().add(const MaestroListRefresh());
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
