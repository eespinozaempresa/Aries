import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/aries_app_bar.dart';
import '../../../../core/widgets/number_form_field.dart';
import '../../domain/entities/articulo.dart';
import '../../domain/repositories/articulo_repository.dart';
import '../../domain/repositories/formula_repository.dart';
import '../widgets/maestro_picker.dart';

class FormulaFormPage extends StatefulWidget {
  final String? formulaId;
  const FormulaFormPage({super.key, this.formulaId});
  bool get isEdit => formulaId != null;

  @override
  State<FormulaFormPage> createState() => _FormulaFormPageState();
}

class _Parte {
  final String codigoArticulo;
  final String descripcion;
  double cantidad;
  _Parte({required this.codigoArticulo, required this.descripcion, required this.cantidad});
}

class _FormulaFormPageState extends State<FormulaFormPage> {
  final _obsCtrl = TextEditingController();
  bool _saving = false;
  bool _loading = false;
  bool _activo = true;

  String? _principalCodigo;
  String? _principalDescripcion;
  final List<_Parte> _partes = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadFormula();
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFormula() async {
    setState(() => _loading = true);
    final result = await getIt<FormulaRepository>().getById(widget.formulaId!);
    if (!mounted) return;
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Theme.of(context).colorScheme.error),
      ),
      (formula) {
        _principalCodigo = formula.codigoArticulo;
        _principalDescripcion = formula.descripcionArticulo ?? formula.codigoArticulo;
        _obsCtrl.text = formula.observacion ?? '';
        _activo = formula.activo;
        _partes
          ..clear()
          ..addAll(formula.detalle.map((d) => _Parte(
                codigoArticulo: d.codigoArticulo,
                descripcion: d.descripcionArticulo ?? d.codigoArticulo,
                cantidad: d.cantidad,
              )));
      },
    );
    setState(() => _loading = false);
  }

  Future<Articulo?> _pickArticulo(String title) => MaestroPicker.show<Articulo>(
        context,
        title: title,
        onSearch: (q) async {
          final res = await getIt<ArticuloRepository>().search(q: q, activo: true, page: 1);
          return res.fold((_) => [], (p) => p.data);
        },
        itemTitle: (a) => a.descripcion,
        itemSubtitle: (a) => a.codigo,
      );

  Future<void> _pickPrincipal() async {
    final art = await _pickArticulo('Artículo Principal');
    if (art == null || !mounted) return;
    setState(() {
      _principalCodigo = art.codigo;
      _principalDescripcion = art.descripcion;
    });
  }

  Future<void> _addParte() async {
    final art = await _pickArticulo('Agregar Parte');
    if (art == null || !mounted) return;

    if (art.codigo == _principalCodigo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Una Parte no puede ser igual al artículo Principal')),
      );
      return;
    }
    if (_partes.any((p) => p.codigoArticulo == art.codigo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esa Parte ya está en la fórmula')),
      );
      return;
    }

    final qCtrl = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(art.descripcion),
        content: NumberFormField(controller: qCtrl, decoration: const InputDecoration(labelText: 'Cantidad')),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Agregar')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _partes.add(_Parte(
            codigoArticulo: art.codigo,
            descripcion: art.descripcion,
            cantidad: double.tryParse(qCtrl.text) ?? 1,
          )));
    }
  }

  Future<void> _editCantidad(_Parte parte) async {
    final qCtrl = TextEditingController(text: parte.cantidad.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(parte.descripcion),
        content: NumberFormField(controller: qCtrl, decoration: const InputDecoration(labelText: 'Cantidad')),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Actualizar')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => parte.cantidad = double.tryParse(qCtrl.text) ?? parte.cantidad);
    }
  }

  Future<void> _save() async {
    if (_principalCodigo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el artículo Principal')),
      );
      return;
    }
    if (_partes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una Parte')),
      );
      return;
    }

    setState(() => _saving = true);
    final result = await getIt<FormulaRepository>().save({
      'codigoArticulo': _principalCodigo,
      if (_obsCtrl.text.isNotEmpty) 'observacion': _obsCtrl.text,
      'activo': _activo,
      'detalle': _partes
          .asMap()
          .entries
          .map((e) => {
                'codigoArticulo': e.value.codigoArticulo,
                'cantidad': e.value.cantidad,
                'orden': e.key,
              })
          .toList(),
    }, id: widget.formulaId);
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Theme.of(context).colorScheme.error),
      ),
      (_) => context.pop(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AriesAppBar(title: Text(widget.isEdit ? 'Editar Fórmula' : 'Nueva Fórmula')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Artículo Principal', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickPrincipal,
                  child: InputDecorator(
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    child: Text(_principalDescripcion == null
                        ? 'Toca para seleccionar...'
                        : '$_principalDescripcion ($_principalCodigo)'),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _obsCtrl,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Observación',
                    border: OutlineInputBorder(),
                    isDense: true,
                    counterText: '',
                  ),
                ),
                if (widget.isEdit) ...[
                  const SizedBox(height: 4),
                  SwitchListTile(
                    title: const Text('Activo'),
                    contentPadding: EdgeInsets.zero,
                    value: _activo,
                    onChanged: (v) => setState(() => _activo = v),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Partes', style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addParte,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
                if (_partes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Sin Partes agregadas', style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                ..._partes.asMap().entries.map((e) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(e.value.descripcion),
                        subtitle: Text('${e.value.codigoArticulo}  ·  Cantidad: ${e.value.cantidad}'),
                        onTap: () => _editCantidad(e.value),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(() => _partes.removeAt(e.key)),
                        ),
                      ),
                    )),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => context.pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save, size: 18),
                      label: const Text('Guardar'),
                    ),
                  ),
                ]),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}
