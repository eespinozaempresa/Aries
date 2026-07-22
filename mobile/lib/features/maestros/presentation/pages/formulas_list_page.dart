import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/formula.dart';
import '../../domain/repositories/formula_repository.dart';
import '../bloc/formulas_bloc.dart';
import '../bloc/maestro_list_event.dart';
import '../bloc/maestro_list_state.dart';
import '../../../../core/widgets/aries_app_bar.dart';

class FormulasListPage extends StatelessWidget {
  const FormulasListPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => FormulasBloc(getIt<FormulaRepository>())..add(MaestroListLoad()),
        child: const _FormulasView(),
      );
}

class _FormulasView extends StatefulWidget {
  const _FormulasView();
  @override
  State<_FormulasView> createState() => _FormulasViewState();
}

class _FormulasViewState extends State<_FormulasView> {
  final _searchCtrl = TextEditingController();
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AriesAppBar(
        title: const Text('Fórmulas'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por código o descripción del Principal...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<FormulasBloc>().add(MaestroListLoad());
                        },
                      )
                    : null,
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              onChanged: (v) => context.read<FormulasBloc>().add(MaestroListLoad(q: v)),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await context.push<bool>('/maestros/formulas/nuevo');
          if (saved == true && context.mounted) {
            context.read<FormulasBloc>().add(const MaestroListRefresh());
          }
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<FormulasBloc, MaestroListState<Formula>>(
        builder: (ctx, state) {
          if (state is MaestroListLoading<Formula>) return const Center(child: CircularProgressIndicator());
          if (state is MaestroListError<Formula>) return Center(child: Text(state.message, style: TextStyle(color: cs.error)));

          final items = state is MaestroListLoaded<Formula> ? state.items : <Formula>[];
          if (items.isEmpty) {
            return Center(child: Text('Sin fórmulas', style: TextStyle(color: cs.onSurfaceVariant)));
          }
          return RefreshIndicator(
            onRefresh: () async => ctx.read<FormulasBloc>().add(const MaestroListRefresh()),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final f = items[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: f.activo ? cs.primaryContainer : cs.surfaceContainerHighest,
                    child: Icon(Icons.precision_manufacturing_outlined,
                        size: 18, color: f.activo ? cs.primary : cs.onSurfaceVariant),
                  ),
                  title: Text(f.descripcionArticulo ?? f.codigoArticulo,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('${f.codigoArticulo}  |  ${f.detalle.length} parte(s)',
                      style: const TextStyle(fontSize: 12)),
                  trailing: !f.activo
                      ? const Chip(
                          label: Text('Inactivo'),
                          labelStyle: TextStyle(fontSize: 10),
                          padding: EdgeInsets.zero,
                        )
                      : null,
                  onTap: () async {
                    final saved = await ctx.push<bool>('/maestros/formulas/${f.id}');
                    if (saved == true && ctx.mounted) ctx.read<FormulasBloc>().add(const MaestroListRefresh());
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
