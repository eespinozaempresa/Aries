import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/tipo_cambio.dart';
import '../../domain/repositories/tipo_cambio_repository.dart';
import '../bloc/tipo_cambio_bloc.dart';
import '../bloc/tipo_cambio_event.dart';
import '../bloc/tipo_cambio_state.dart';
import '../../../../core/widgets/aries_app_bar.dart';
import '../../../../core/widgets/number_form_field.dart';

class TipoCambioListPage extends StatelessWidget {
  const TipoCambioListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TipoCambioBloc(getIt<TipoCambioRepository>())..add(TipoCambioListLoad()),
      child: const _TipoCambioListView(),
    );
  }
}

class _TipoCambioListView extends StatefulWidget {
  const _TipoCambioListView();
  @override
  State<_TipoCambioListView> createState() => _TipoCambioListViewState();
}

class _TipoCambioListViewState extends State<_TipoCambioListView> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<TipoCambioBloc>().add(TipoCambioListLoadMore());
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AriesAppBar(title: const Text('Tipo de Cambio')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<TipoCambioBloc, TipoCambioState>(
        listener: (ctx, state) {
          if (state is TipoCambioGuardado) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Guardado correctamente')),
            );
            ctx.read<TipoCambioBloc>().add(TipoCambioListLoad());
          }
          if (state is TipoCambioEliminado) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Eliminado correctamente')),
            );
            ctx.read<TipoCambioBloc>().add(TipoCambioListLoad());
          }
          if (state is TipoCambioError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Theme.of(ctx).colorScheme.error),
            );
          }
        },
        builder: (ctx, state) {
          if (state is TipoCambioListLoading && state.previous.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = switch (state) {
            TipoCambioListLoaded(:final items) => items,
            TipoCambioListLoading(:final previous) => previous,
            _ => <TipoCambio>[],
          };

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.currency_exchange, size: 64, color: Theme.of(ctx).colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('Sin registros de tipo de cambio'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ctx.read<TipoCambioBloc>().add(TipoCambioListLoad()),
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                if (i == items.length) {
                  final loading = state is TipoCambioListLoading && state.previous.isNotEmpty;
                  return loading
                      ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                      : const SizedBox.shrink();
                }
                final tc = items[i];
                return _TipoCambioTile(
                  tipoCambio: tc,
                  onEdit: () => _showForm(ctx, tc),
                  onDelete: () => _confirmDelete(ctx, tc),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showForm(BuildContext ctx, TipoCambio? existing) {
    final formKey = GlobalKey<FormState>();
    final tcCtrl = TextEditingController(
      text: existing != null ? existing.tipoCambio.toStringAsFixed(4) : '',
    );
    final fechaCtrl = TextEditingController(text: existing?.fecha ?? _hoy());

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Nuevo Tipo de Cambio' : 'Editar Tipo de Cambio'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (existing == null)
                TextFormField(
                  controller: fechaCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2099),
                    );
                    if (picked != null) {
                      fechaCtrl.text =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  },
                  validator: (v) => (v == null || v.isEmpty) ? 'Seleccione una fecha' : null,
                ),
              if (existing == null) const SizedBox(height: 16),
              NumberFormField(
                controller: tcCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Cambio',
                  prefixText: 'S/. ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese el valor';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Ingrese un valor válido mayor a 0';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final value = double.parse(tcCtrl.text.replaceAll(',', '.'));
              Navigator.pop(ctx);
              if (existing != null) {
                ctx.read<TipoCambioBloc>().add(TipoCambioActualizar(existing.id, value));
              } else {
                // Para nuevo registro usamos el evento existente (registrar crea en la fecha de hoy)
                // Si la fecha seleccionada es hoy, usar TipoCambioRegistrar
                ctx.read<TipoCambioBloc>().add(TipoCambioRegistrar(value));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, TipoCambio tc) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Eliminar el tipo de cambio del ${_formatFecha(tc.fecha)}?'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<TipoCambioBloc>().add(TipoCambioEliminar(tc.id));
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _hoy() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _formatFecha(String fecha) {
    final parts = fecha.split('-');
    if (parts.length != 3) return fecha;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}

class _TipoCambioTile extends StatelessWidget {
  final TipoCambio tipoCambio;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TipoCambioTile({
    required this.tipoCambio,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatFecha(String fecha) {
    final parts = fecha.split('-');
    if (parts.length != 3) return fecha;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(Icons.currency_exchange, color: cs.primary, size: 20),
        ),
        title: Text(
          _formatFecha(tipoCambio.fecha),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('S/. ${tipoCambio.tipoCambio.toStringAsFixed(4)} por USD'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: onEdit, tooltip: 'Editar'),
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              onPressed: onDelete,
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }
}
