import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../../domain/repositories/proveedor_repository.dart';

enum PersonaTipo { cliente, proveedor }

class PersonaFormPage extends StatefulWidget {
  final PersonaTipo tipo;
  final String? personaId;
  const PersonaFormPage({super.key, required this.tipo, this.personaId});

  bool get isEdit => personaId != null;

  @override
  State<PersonaFormPage> createState() => _PersonaFormPageState();
}

class _PersonaFormPageState extends State<PersonaFormPage> {
  final _formKey  = GlobalKey<FormState>();
  bool _loading   = false;
  bool _saving    = false;
  bool _activo    = true;

  final _codigoCtrl   = TextEditingController();
  final _razonCtrl    = TextEditingController();
  final _dirCtrl      = TextEditingController();
  final _rucCtrl      = TextEditingController();
  final _telCtrl      = TextEditingController();
  final _celCtrl      = TextEditingController();
  final _emailCtrl    = TextEditingController();

  @override
  void dispose() {
    for (final c in [_codigoCtrl, _razonCtrl, _dirCtrl, _rucCtrl, _telCtrl, _celCtrl, _emailCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'codigo'     : _codigoCtrl.text.toUpperCase(),
      'razonSocial': _razonCtrl.text,
      'direccion'  : _dirCtrl.text.isEmpty ? null : _dirCtrl.text,
      'rucDni'     : _rucCtrl.text.isEmpty ? null : _rucCtrl.text,
      'telefono'   : _telCtrl.text.isEmpty ? null : _telCtrl.text,
      'celular'    : _celCtrl.text.isEmpty ? null : _celCtrl.text,
      'email'      : _emailCtrl.text.isEmpty ? null : _emailCtrl.text,
      'activo'     : _activo,
    };

    final result = widget.tipo == PersonaTipo.cliente
        ? await getIt<ClienteRepository>().save(data, id: widget.personaId)
        : await getIt<ProveedorRepository>().save(data, id: widget.personaId);

    setState(() => _saving = false);
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Theme.of(context).colorScheme.error),
      ),
      (_) => context.pop(true),
    );
  }

  String get _tipoLabel => widget.tipo == PersonaTipo.cliente ? 'Cliente' : 'Proveedor';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar $_tipoLabel' : 'Nuevo $_tipoLabel'),
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(onPressed: _save, child: const Text('Guardar')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(flex: 2,
                child: _field(_codigoCtrl, 'Código *', required: true, enabled: !widget.isEdit, maxLength: 10, caps: true)),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: _field(_rucCtrl, 'RUC / DNI', maxLength: 15)),
            ]),
            _field(_razonCtrl, 'Razón Social *', required: true, maxLength: 100),
            _field(_dirCtrl, 'Dirección', maxLength: 100),
            Row(children: [
              Expanded(child: _field(_telCtrl, 'Teléfono', maxLength: 20)),
              const SizedBox(width: 12),
              Expanded(child: _field(_celCtrl, 'Celular', maxLength: 20)),
            ]),
            _field(_emailCtrl, 'Email', maxLength: 100),
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
  }

  Widget _field(TextEditingController ctrl, String label, {
    bool required = false, bool enabled = true,
    int? maxLength, bool caps = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          enabled: enabled,
          maxLength: maxLength,
          textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder(),
            isDense: true, counterText: '',
          ),
          validator: required ? (v) => (v == null || v.isEmpty) ? 'Requerido' : null : null,
        ),
      );
}
