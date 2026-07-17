import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/unique_id.dart';
import '../../domain/repositories/almacen_repository.dart';

class AlmacenFormPage extends StatefulWidget {
  final String? almacenId;
  const AlmacenFormPage({super.key, this.almacenId});
  bool get isEdit => almacenId != null;

  @override
  State<AlmacenFormPage> createState() => _AlmacenFormPageState();
}

class _AlmacenFormPageState extends State<AlmacenFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _activo = true;
  String _tipo = 'ALMACEN';

  final _codigoCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _abrCtrl    = TextEditingController();
  final _ubCtrl     = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.isEdit) _codigoCtrl.text = uniqueId(5);
  }

  @override
  void dispose() {
    for (final c in [_codigoCtrl, _descCtrl, _abrCtrl, _ubCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await getIt<AlmacenRepository>().save({
      'codigo'     : _codigoCtrl.text.toUpperCase(),
      'descripcion': _descCtrl.text,
      'activo'     : _activo,
      'tipo'       : _tipo,
      if (_abrCtrl.text.isNotEmpty) 'abreviatura': _abrCtrl.text,
      if (_ubCtrl.text.isNotEmpty)  'ubicacion'  : _ubCtrl.text,
    }, id: widget.almacenId);
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error),
      ),
      (_) => context.pop(true),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.isEdit ? 'Editar Almacén' : 'Nuevo Almacén'),
          actions: [
            if (_saving)
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
            else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Guardar'),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(
                  flex: 1,
                  child: _field(_codigoCtrl, 'Código', enabled: false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _field(_abrCtrl, 'Abreviatura', maxLength: 15),
                ),
              ]),
              _field(_descCtrl, 'Descripción *', required: true, maxLength: 60),
              _field(_ubCtrl, 'Ubicación', maxLength: 80),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _tipo,
                  decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                      isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'ALMACEN',  child: Text('Almacén')),
                    DropdownMenuItem(value: 'TIENDA',   child: Text('Tienda')),
                    DropdownMenuItem(value: 'TRANSITO', child: Text('Tránsito')),
                  ],
                  onChanged: (v) => setState(() => _tipo = v!),
                ),
              ),
              if (widget.isEdit)
                SwitchListTile(
                  title: const Text('Activo'),
                  value: _activo,
                  onChanged: (v) => setState(() => _activo = v),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      );

  Widget _field(TextEditingController ctrl, String label, {
    bool required = false,
    bool enabled  = true,
    int? maxLength,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          enabled: enabled,
          maxLength: maxLength,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
            counterText: '',
            filled: !enabled,
          ),
          validator: required
              ? (v) => (v == null || v.isEmpty) ? 'Requerido' : null
              : null,
        ),
      );
}
