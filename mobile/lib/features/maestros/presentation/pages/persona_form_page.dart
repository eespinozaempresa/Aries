import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/unique_id.dart';
import '../../data/datasources/maestros_remote_datasource.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../../domain/repositories/proveedor_repository.dart';
import '../../../tablas/data/datasources/tablas_remote_datasource.dart';
import '../../../tablas/data/models/tabla_model.dart';
import '../../../tablas/domain/entities/tabla_base.dart';
import '../../../../core/widgets/aries_app_bar.dart';

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
  final _formKey   = GlobalKey<FormState>();
  final _tablasDs  = getIt<TablasRemoteDataSource>();
  final _maestroDs = getIt<MaestrosRemoteDataSource>();

  bool _loading = false;
  bool _saving  = false;
  bool _activo  = true;

  final _codigoCtrl = TextEditingController();
  final _razonCtrl  = TextEditingController();
  final _dirCtrl    = TextEditingController();
  final _rucCtrl    = TextEditingController();
  final _telCtrl    = TextEditingController();
  final _celCtrl    = TextEditingController();
  final _emailCtrl  = TextEditingController();

  List<TipoLista> _tiposLista   = [];
  String?         _selectedTipoLista;

  bool get _isCliente => widget.tipo == PersonaTipo.cliente;
  String get _tipoLabel => _isCliente ? 'Cliente' : 'Proveedor';

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  @override
  void dispose() {
    for (final c in [_codigoCtrl, _razonCtrl, _dirCtrl, _rucCtrl,
                     _telCtrl, _celCtrl, _emailCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _initForm() async {
    setState(() => _loading = true);

    if (_isCliente) {
      try {
        final rows = await _tablasDs.list('tipos-lista', activo: true);
        if (mounted) {
          setState(() => _tiposLista = rows.map(TablaModel.tipoListaFromJson).toList());
        }
      } catch (_) {}
    }

    if (widget.isEdit && _isCliente) {
      try {
        final cliente = await _maestroDs.getCliente(widget.personaId!);
        if (mounted) {
          _codigoCtrl.text = cliente.codigo;
          _razonCtrl.text  = cliente.razonSocial;
          _dirCtrl.text    = cliente.direccion ?? '';
          _rucCtrl.text    = cliente.rucDni ?? '';
          _telCtrl.text    = cliente.telefono ?? '';
          _celCtrl.text    = cliente.celular ?? '';
          _emailCtrl.text  = cliente.email ?? '';
          _activo          = cliente.activo;
          _selectedTipoLista = _tiposLista.any((t) => t.id == cliente.idTipoLista)
              ? cliente.idTipoLista
              : null;
        }
      } catch (_) {}
    } else if (widget.isEdit && !_isCliente) {
      final result = await getIt<ProveedorRepository>().getById(widget.personaId!);
      if (mounted) {
        result.fold(
          (e) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message),
                backgroundColor: Theme.of(context).colorScheme.error),
          ),
          (p) {
            _codigoCtrl.text = p.codigo;
            _razonCtrl.text  = p.razonSocial;
            _dirCtrl.text    = p.direccion ?? '';
            _rucCtrl.text    = p.rucDni ?? '';
            _telCtrl.text    = p.telefono ?? '';
            _celCtrl.text    = p.celular ?? '';
            _emailCtrl.text  = p.email ?? '';
            _activo          = p.activo;
          },
        );
      }
    } else if (!widget.isEdit) {
      _codigoCtrl.text = uniqueId(8);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{
      if (!widget.isEdit) 'codigo': _codigoCtrl.text.toUpperCase(),
      'razonSocial': _razonCtrl.text,
      'activo'     : _activo,
      if (_dirCtrl.text.isNotEmpty)   'direccion': _dirCtrl.text,
      if (_rucCtrl.text.isNotEmpty)   'rucDni'   : _rucCtrl.text,
      if (_telCtrl.text.isNotEmpty)   'telefono' : _telCtrl.text,
      if (_celCtrl.text.isNotEmpty)   'celular'  : _celCtrl.text,
      if (_emailCtrl.text.isNotEmpty) 'email'    : _emailCtrl.text,
      if (_isCliente) 'idTipoLista': _selectedTipoLista,
    };

    final result = _isCliente
        ? await getIt<ClienteRepository>().save(data, id: widget.personaId)
        : await getIt<ProveedorRepository>().save(data, id: widget.personaId);

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
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AriesAppBar(
        title: Text(widget.isEdit ? 'Editar $_tipoLabel' : 'Nuevo $_tipoLabel'),
        actions: [
          if (_saving)
            const Padding(
                padding: EdgeInsets.all(12),
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
              Expanded(flex: 2, child: _field(_codigoCtrl, 'Código', enabled: false)),
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
            if (_isCliente && _tiposLista.isNotEmpty) ...[
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _selectedTipoLista,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Lista de precios',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('— Sin lista asignada —')),
                  ..._tiposLista.map((t) => DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(t.descripcion, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (v) => setState(() => _selectedTipoLista = v),
              ),
              const SizedBox(height: 12),
            ],
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
    bool required  = false,
    bool enabled   = true,
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
