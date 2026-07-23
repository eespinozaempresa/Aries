import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/export_service.dart';
import '../../domain/entities/movimiento.dart';
import '../bloc/movimiento_bloc.dart';
import '../bloc/movimiento_event.dart';
import '../bloc/movimiento_state.dart';
import '../../domain/repositories/movimiento_repository.dart';
import '../../../../core/widgets/aries_app_bar.dart';

class MovimientosListPage extends StatelessWidget {
  const MovimientosListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MovimientoBloc(getIt<MovimientoRepository>())
        ..add(MovimientoListLoad()),
      child: const _MovimientosListView(),
    );
  }
}

class _MovimientosListView extends StatefulWidget {
  const _MovimientosListView();
  @override
  State<_MovimientosListView> createState() => _MovimientosListViewState();
}

class _MovimientosListViewState extends State<_MovimientosListView> {
  final _scrollCtrl = ScrollController();
  TipoMovimiento? _tipoFiltro;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<MovimientoBloc>().add(MovimientoListLoadMore());
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Color _tipoColor(TipoMovimiento t) {
    switch (t) {
      case TipoMovimiento.INGRESO: return Colors.green;
      case TipoMovimiento.SALIDA:  return Colors.red;
      case TipoMovimiento.TRASLADO: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AriesAppBar(
        title: const Text('Movimientos'),
        actions: [
          BlocBuilder<MovimientoBloc, MovimientoState>(
            builder: (ctx, state) {
              final items = switch (state) {
                MovimientoListLoaded(:final items) => items,
                MovimientoListLoading(:final previous) => previous,
                _ => <Movimiento>[],
              };
              if (items.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Exportar',
                onPressed: () => ExportService.showExportDialog(
                  context: context,
                  title: 'Movimientos',
                  columns: const ['Doc', 'Serie', 'Número', 'Fecha', 'Tipo', 'Almacén', 'Total', 'Estado'],
                  rows: items.map((m) => [
                    m.abreviaturaDocumento ?? m.codigoDocumento, m.serie, m.numeroDocumento, ExportService.fmtDate(m.fecha),
                    m.tipo.name, m.descripcionAlmacenOrigen ?? m.codigoAlmacenOrigen,
                    m.total.toStringAsFixed(2),
                    m.anulado ? 'Anulado' : 'Vigente',
                  ]).toList(),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              final tipo = value == 'TODOS' ? null : TipoMovimiento.values.byName(value);
              setState(() => _tipoFiltro = tipo);
              context.read<MovimientoBloc>().add(MovimientoListLoad(tipo: tipo));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'TODOS',    child: Text('Todos')),
              PopupMenuItem(value: 'INGRESO',  child: Text('Ingresos')),
              PopupMenuItem(value: 'SALIDA',   child: Text('Salidas')),
              PopupMenuItem(value: 'TRASLADO', child: Text('Traslados')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await context.push<bool>('/almacen/movimientos/nuevo');
          if (saved == true && context.mounted) {
            context.read<MovimientoBloc>().add(MovimientoListLoad(tipo: _tipoFiltro));
          }
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<MovimientoBloc, MovimientoState>(
        builder: (context, state) {
          if (state is MovimientoListLoading && state.previous.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MovimientoError && state is! MovimientoListLoaded) {
            return Center(child: Text(state.message));
          }

          final items = switch (state) {
            MovimientoListLoaded(:final items) => items,
            MovimientoListLoading(:final previous) => previous,
            _ => <Movimiento>[],
          };

          if (items.isEmpty) {
            return const Center(child: Text('No hay movimientos'));
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<MovimientoBloc>().add(MovimientoListLoad(tipo: _tipoFiltro)),
            child: ListView.builder(
              controller: _scrollCtrl,
              itemCount: items.length + 1,
              itemBuilder: (ctx, i) {
                if (i == items.length) {
                  final loading = state is MovimientoListLoading && state.previous.isNotEmpty;
                  return loading
                      ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                      : const SizedBox.shrink();
                }
                final mov = items[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: mov.anulado
                        ? Colors.grey.shade200
                        : _tipoColor(mov.tipo).withValues(alpha: 0.15),
                    child: Icon(_tipoIcon(mov.tipo),
                        color: mov.anulado ? Colors.grey : _tipoColor(mov.tipo), size: 20),
                  ),
                  title: Text('${mov.abreviaturaDocumento ?? mov.codigoDocumento}-${mov.serie}-${mov.numeroDocumento}'),
                  subtitle: Text('${mov.fecha} · ${mov.descripcionAlmacenOrigen ?? mov.codigoAlmacenOrigen}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('S/ ${mov.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (mov.anulado)
                        const Text('ANULADO', style: TextStyle(color: Colors.red, fontSize: 10)),
                    ],
                  ),
                  onTap: () async {
                    final changed = await context.push<bool>('/almacen/movimientos/${mov.id}');
                    if (changed == true && context.mounted) {
                      context.read<MovimientoBloc>().add(MovimientoListLoad(tipo: _tipoFiltro));
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _tipoIcon(TipoMovimiento t) {
    switch (t) {
      case TipoMovimiento.INGRESO: return Icons.arrow_downward;
      case TipoMovimiento.SALIDA:  return Icons.arrow_upward;
      case TipoMovimiento.TRASLADO: return Icons.swap_horiz;
    }
  }
}
