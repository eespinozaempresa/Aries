import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/entities/proveedor.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../../domain/repositories/proveedor_repository.dart';
import '../bloc/clientes_bloc.dart';
import '../bloc/proveedores_bloc.dart';
import '../bloc/maestro_list_event.dart';
import '../bloc/maestro_list_state.dart';

// ── Clientes ──────────────────────────────────────────────────────────────────

class ClientesListPage extends StatelessWidget {
  const ClientesListPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => ClientesBloc(getIt<ClienteRepository>())..add(MaestroListLoad()),
        child: const _PersonaListView(
          tipo: 'Cliente',
          editRoute: '/maestros/clientes',
        ),
      );
}

// ── Proveedores ───────────────────────────────────────────────────────────────

class ProveedoresListPage extends StatelessWidget {
  const ProveedoresListPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => ProveedoresBloc(getIt<ProveedorRepository>())..add(MaestroListLoad()),
        child: const _PersonaListView(
          tipo: 'Proveedor',
          editRoute: '/maestros/proveedores',
        ),
      );
}

// ── Shared list view for Clientes + Proveedores ───────────────────────────────

class _PersonaListView extends StatefulWidget {
  final String tipo;
  final String editRoute;
  const _PersonaListView({required this.tipo, required this.editRoute});

  @override
  State<_PersonaListView> createState() => _PersonaListViewState();
}

class _PersonaListViewState extends State<_PersonaListView> {
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _dispatch(String? q) {
    final bloc = widget.tipo == 'Cliente'
        ? context.read<ClientesBloc>() as dynamic
        : context.read<ProveedoresBloc>() as dynamic;
    bloc.add(MaestroListLoad(q: q));
  }

  void _refresh(String? q) {
    final bloc = widget.tipo == 'Cliente'
        ? context.read<ClientesBloc>() as dynamic
        : context.read<ProveedoresBloc>() as dynamic;
    bloc.add(MaestroListRefresh(q: q));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tipo}s'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Buscar por razón social, código o RUC...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _ctrl.clear(); _dispatch(null); })
                    : null,
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              onChanged: _dispatch,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await context.push<bool>('${widget.editRoute}/nuevo');
          if (saved == true && context.mounted) _refresh(_ctrl.text);
        },
        child: const Icon(Icons.add),
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (widget.tipo == 'Cliente') {
      return BlocBuilder<ClientesBloc, MaestroListState<Cliente>>(
        builder: (ctx, state) => _list<Cliente>(ctx, state, cs,
          title: (c) => c.razonSocial,
          subtitle: (c) => 'RUC/DNI: ${c.rucDni ?? '-'}  |  ${c.telefono ?? ''}',
          avatarText: (c) => c.codigo.substring(0, c.codigo.length.clamp(0, 2)),
          isActive: (c) => c.activo,
        ),
      );
    }
    return BlocBuilder<ProveedoresBloc, MaestroListState<Proveedor>>(
      builder: (ctx, state) => _list<Proveedor>(ctx, state, cs,
        title: (p) => p.razonSocial,
        subtitle: (p) => 'RUC/DNI: ${p.rucDni ?? '-'}  |  ${p.telefono ?? ''}',
        avatarText: (p) => p.codigo.substring(0, p.codigo.length.clamp(0, 2)),
        isActive: (p) => p.activo,
      ),
    );
  }

  Widget _list<T>(
    BuildContext context,
    MaestroListState<T> state,
    ColorScheme cs, {
    required String Function(T) title,
    required String Function(T) subtitle,
    required String Function(T) avatarText,
    required bool Function(T) isActive,
  }) {
    if (state is MaestroListInitial<T> || (state is MaestroListLoading<T> && state.previousItems.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is MaestroListError<T>) {
      return Center(child: Text(state.message, style: TextStyle(color: cs.error)));
    }
    final items = switch (state) {
      MaestroListLoaded<T> s => s.items,
      MaestroListLoading<T> s => s.previousItems,
      _ => <T>[],
    };
    return RefreshIndicator(
      onRefresh: () async => _refresh(_ctrl.text),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          final active = isActive(item);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: active ? cs.primaryContainer : cs.surfaceContainerHighest,
              child: Text(avatarText(item),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      color: active ? cs.primary : cs.onSurfaceVariant)),
            ),
            title: Text(title(item), style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(subtitle(item), style: const TextStyle(fontSize: 12)),
            onTap: () async {
              final saved = await context.push<bool>('${widget.editRoute}/${_idOf(item)}');
              if (saved == true && context.mounted) _refresh(_ctrl.text);
            },
          );
        },
      ),
    );
  }

  String _idOf(dynamic item) => item.id as String;
}
