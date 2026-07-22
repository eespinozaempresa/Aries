import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/unique_id.dart';
import '../../domain/entities/tabla_base.dart';
import '../bloc/tabla_bloc.dart';
import '../bloc/tabla_event.dart';
import '../bloc/tabla_state.dart';
import '../../../../core/widgets/aries_app_bar.dart';
import '../../../../core/widgets/number_form_field.dart';

/// Página de lista + formulario inline para cualquier tabla base.
class TablaListPage<T extends TablaBase> extends StatefulWidget {
  final String title;
  final TablaBloc<T> bloc;
  final List<_ExtraField> extraFields;

  const TablaListPage({
    super.key,
    required this.title,
    required this.bloc,
    this.extraFields = const [],
  });

  @override
  State<TablaListPage<T>> createState() => _TablaListPageState<T>();
}

class _ExtraField {
  final String key;
  final String label;
  final TextInputType keyboardType;
  final bool isSwitch;
  const _ExtraField(this.key, this.label, {this.keyboardType = TextInputType.text, this.isSwitch = false});
}

class _TablaListPageState<T extends TablaBase> extends State<TablaListPage<T>> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.bloc.add(TablaLoad());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openForm(BuildContext context, [T? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: widget.bloc,
        child: _TablaForm<T>(item: item, extraFields: widget.extraFields),
      ),
    ).then((_) => widget.bloc.add(TablaLoad(q: _searchCtrl.text.isEmpty ? null : _searchCtrl.text)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: Scaffold(
        appBar: AriesAppBar(title: Text(widget.title)),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openForm(context),
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Buscar...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => widget.bloc.add(TablaLoad(q: v.isEmpty ? null : v)),
              ),
            ),
            Expanded(
              child: BlocConsumer<TablaBloc<T>, TablaState>(
                listener: (ctx, state) {
                  if (state is TablaSaved<T>) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Guardado'), backgroundColor: Colors.green));
                    widget.bloc.add(TablaLoad(q: _searchCtrl.text.isEmpty ? null : _searchCtrl.text));
                  }
                  if (state is TablaError) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.red));
                  }
                },
                builder: (ctx, state) {
                  if (state is TablaLoading) return const Center(child: CircularProgressIndicator());
                  if (state is TablaError) return Center(child: Text(state.message));
                  final items = state is TablaLoaded<T> ? state.items : <T>[];
                  if (items.isEmpty) return const Center(child: Text('Sin registros'));
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final t = items[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: t.activo
                              ? Theme.of(ctx).colorScheme.primaryContainer
                              : Colors.grey.shade200,
                          child: Text(t.codigo, style: const TextStyle(fontSize: 11)),
                        ),
                        title: Text(t.descripcion),
                        subtitle: Text(t.subtitle),
                        trailing: Switch(
                          value: t.activo,
                          onChanged: (_) => widget.bloc.add(TablaToggle(t.id)),
                        ),
                        onTap: () => _openForm(ctx, t),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TablaForm<T extends TablaBase> extends StatefulWidget {
  final T? item;
  final List<_ExtraField> extraFields;
  const _TablaForm({this.item, required this.extraFields});
  @override
  State<_TablaForm<T>> createState() => _TablaFormState<T>();
}

class _TablaFormState<T extends TablaBase> extends State<_TablaForm<T>> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _descCtrl;
  final Map<String, TextEditingController> _extraCtrl = {};
  final Map<String, bool> _switchValues = {};

  @override
  void initState() {
    super.initState();
    _codigoCtrl = TextEditingController(
        text: widget.item?.codigo ?? uniqueId(5));
    _descCtrl   = TextEditingController(text: widget.item?.descripcion ?? '');
    for (final f in widget.extraFields) {
      if (f.isSwitch) {
        _switchValues[f.key] = _getExtraValue<bool>(f.key) ?? false;
      } else {
        _extraCtrl[f.key] = TextEditingController(text: _getExtraValue<String>(f.key)?.toString() ?? '');
      }
    }
  }

  V? _getExtraValue<V>(String key) {
    final item = widget.item;
    if (item == null) return null;
    try {
      switch (key) {
        case 'abreviatura':     return (item as dynamic).abreviatura as V?;
        case 'serie':           return (item as dynamic).serie?.toString() as V?;
        case 'numeroSiguiente': return (item as dynamic).numeroSiguiente?.toString() as V?;
        case 'tipo':            return (item as dynamic).tipo as V?;
        case 'aplicaIgv':       return (item as dynamic).aplicaIgv as V?;
        case 'dsctoPct':          return (item as dynamic).dsctoPct?.toString() as V?;
        case 'dctoMto':           return (item as dynamic).dctoMto?.toString() as V?;
        case 'requiereOperacion': return (item as dynamic).requiereOperacion as V?;
        default:                  return null;
      }
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _extraCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final data = <String, dynamic>{
      if (widget.item == null) 'codigo': _codigoCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
    };
    for (final f in widget.extraFields) {
      if (f.isSwitch) {
        data[f.key] = _switchValues[f.key] ?? false;
      } else {
        final v = _extraCtrl[f.key]!.text.trim();
        if (v.isNotEmpty) {
          if (f.keyboardType == TextInputType.number) {
            data[f.key] = int.tryParse(v) ?? v;
          } else if (f.keyboardType == const TextInputType.numberWithOptions(decimal: true)) {
            data[f.key] = double.tryParse(v) ?? v;
          } else {
            data[f.key] = v;
          }
        }
      }
    }
    context.read<TablaBloc<T>>().add(TablaSave(data, id: widget.item?.id));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.item == null ? 'Nuevo registro' : 'Editar registro',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codigoCtrl,
              decoration: const InputDecoration(
                  labelText: 'Código', filled: true),
              enabled: false,
              validator: (v) => (v ?? '').isEmpty ? 'Requerido' : null,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              validator: (v) => (v ?? '').isEmpty ? 'Requerido' : null,
            ),
            ...widget.extraFields.map((f) {
              if (f.isSwitch) {
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(f.label),
                  value: _switchValues[f.key] ?? false,
                  onChanged: (v) => setState(() => _switchValues[f.key] = v),
                );
              }
              final isDecimal = f.keyboardType == const TextInputType.numberWithOptions(decimal: true);
              final isInteger = f.keyboardType == TextInputType.number;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: (isDecimal || isInteger)
                    ? NumberFormField(
                        controller: _extraCtrl[f.key],
                        decoration: InputDecoration(labelText: f.label),
                        allowDecimal: isDecimal,
                      )
                    : TextFormField(
                        controller: _extraCtrl[f.key],
                        decoration: InputDecoration(labelText: f.label),
                        keyboardType: f.keyboardType,
                      ),
              );
            }),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Páginas concretas ────────────────────────────────────────────────────────

class TiposPagoPage extends StatelessWidget {
  final TablaBloc<TipoPago> bloc;
  const TiposPagoPage({super.key, required this.bloc});
  @override
  Widget build(BuildContext context) => TablaListPage<TipoPago>(
        title: 'Tipos de Pago',
        bloc: bloc,
        extraFields: const [
          _ExtraField('requiereOperacion', 'Requiere N° Operación', isSwitch: true),
        ],
      );
}

class TiposListaPage extends StatelessWidget {
  final TablaBloc<TipoLista> bloc;
  const TiposListaPage({super.key, required this.bloc});
  @override
  Widget build(BuildContext context) => TablaListPage<TipoLista>(
        title: 'Tipos de Lista',
        bloc: bloc,
        extraFields: const [
          _ExtraField('dsctoPct', 'Descuento %',  keyboardType: TextInputType.numberWithOptions(decimal: true)),
          _ExtraField('dctoMto',  'Descuento S/.', keyboardType: TextInputType.numberWithOptions(decimal: true)),
        ],
      );
}

class LineasPage extends StatelessWidget {
  final TablaBloc bloc;
  const LineasPage({super.key, required this.bloc});
  @override
  Widget build(BuildContext context) =>
      TablaListPage(title: 'Líneas', bloc: bloc);
}

class MedidasPage extends StatelessWidget {
  final TablaBloc bloc;
  const MedidasPage({super.key, required this.bloc});
  @override
  Widget build(BuildContext context) =>
      TablaListPage(title: 'Unidades de medida', bloc: bloc);
}

class BancosPage extends StatelessWidget {
  final TablaBloc bloc;
  const BancosPage({super.key, required this.bloc});
  @override
  Widget build(BuildContext context) =>
      TablaListPage(title: 'Bancos', bloc: bloc);
}

class MarcasPage extends StatelessWidget {
  final TablaBloc bloc;
  const MarcasPage({super.key, required this.bloc});
  @override
  Widget build(BuildContext context) =>
      TablaListPage(title: 'Marcas', bloc: bloc);
}

class DocumentosPage extends StatelessWidget {
  final TablaBloc bloc;
  const DocumentosPage({super.key, required this.bloc});
  @override
  Widget build(BuildContext context) => TablaListPage(
        title: 'Tipos de documento',
        bloc: bloc,
        extraFields: const [
          _ExtraField('abreviatura', 'Abreviatura'),
          _ExtraField('serie', 'Serie (ej: 0001)'),
          _ExtraField('numeroSiguiente', 'N.º siguiente', keyboardType: TextInputType.number),
          _ExtraField('tipo', 'Tipo'),
          _ExtraField('aplicaIgv', 'Aplica IGV', isSwitch: true),
        ],
      );
}
