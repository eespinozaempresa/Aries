import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/articulo.dart';
import '../../domain/repositories/articulo_repository.dart';
import '../bloc/articulos_bloc.dart';
import '../bloc/maestro_list_event.dart';
import '../bloc/maestro_list_state.dart';
import '../../../../core/widgets/aries_app_bar.dart';

class ArticulosListPage extends StatelessWidget {
  const ArticulosListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArticulosBloc(getIt<ArticuloRepository>())
        ..add(MaestroListLoad()),
      child: const _ArticulosView(),
    );
  }
}

class _ArticulosView extends StatefulWidget {
  const _ArticulosView();
  @override
  State<_ArticulosView> createState() => _ArticulosViewState();
}

class _ArticulosViewState extends State<_ArticulosView> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      final state = context.read<ArticulosBloc>().state;
      if (state is MaestroListLoaded<Articulo> && state.hasMore) {
        context.read<ArticulosBloc>().add(MaestroListLoad(q: _searchCtrl.text, page: state.page + 1));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AriesAppBar(
        title: const Text('Artículos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por descripción, código o barras...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<ArticulosBloc>().add(MaestroListLoad());
                        },
                      )
                    : null,
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              onChanged: (v) => context.read<ArticulosBloc>().add(MaestroListLoad(q: v)),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await context.push<bool>('/maestros/articulos/nuevo');
          if (saved == true && context.mounted) {
            context.read<ArticulosBloc>().add(MaestroListRefresh(q: _searchCtrl.text));
          }
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<ArticulosBloc, MaestroListState<Articulo>>(
        builder: (context, state) {
          if (state is MaestroListInitial<Articulo> || (state is MaestroListLoading<Articulo> && state.previousItems.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MaestroListError<Articulo>) {
            return Center(child: Text(state.message, style: TextStyle(color: cs.error)));
          }

          final items = switch (state) {
            MaestroListLoaded<Articulo> s => s.items,
            MaestroListLoading<Articulo> s => s.previousItems,
            _ => <Articulo>[],
          };
          final isLoadingMore = state is MaestroListLoading<Articulo> && state.previousItems.isNotEmpty;

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ArticulosBloc>().add(MaestroListRefresh(q: _searchCtrl.text)),
            child: ListView.builder(
              controller: _scrollCtrl,
              itemCount: items.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final a = items[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: a.activo ? cs.primaryContainer : cs.surfaceContainerHighest,
                    child: Text(
                      a.codigo.substring(0, a.codigo.length.clamp(0, 2)),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: a.activo ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  title: Text(a.descripcion, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    'Cód: ${a.codigo}  |  P.Venta: S/. ${a.precioVenta.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: (!a.conFormula && a.activo)
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (a.conFormula)
                              Tooltip(
                                message: 'Artículo con fórmula (tiene partes)',
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: cs.tertiaryContainer,
                                  child: Text(
                                    'F',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onTertiaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                            if (a.conFormula && !a.activo) const SizedBox(width: 6),
                            if (!a.activo)
                              const Chip(
                                label: Text('Inactivo', style: TextStyle(fontSize: 10)),
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                  onTap: () async {
                    final saved = await context.push<bool>('/maestros/articulos/${a.id}');
                    if (saved == true && context.mounted) {
                      context.read<ArticulosBloc>().add(MaestroListRefresh(q: _searchCtrl.text));
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
}
