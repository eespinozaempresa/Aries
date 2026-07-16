import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/articulo.dart';
import '../../domain/repositories/articulo_repository.dart';

class ArticuloFormPage extends StatefulWidget {
  final String? articuloId;
  const ArticuloFormPage({super.key, this.articuloId});

  bool get isEdit => articuloId != null;

  @override
  State<ArticuloFormPage> createState() => _ArticuloFormPageState();
}

class _ArticuloFormPageState extends State<ArticuloFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = getIt<ArticuloRepository>();

  bool _loading = true;
  bool _saving = false;
  Articulo? _current;

  final _codigoCtrl    = TextEditingController();
  final _descCtrl      = TextEditingController();
  final _barrasCtrl    = TextEditingController();
  final _lineaCtrl     = TextEditingController();
  final _medidaCtrl    = TextEditingController();
  final _marcaCtrl     = TextEditingController();
  final _pCompraCtrl   = TextEditingController();
  final _pVentaCtrl    = TextEditingController();
  final _utilidadCtrl  = TextEditingController();
  final _stMinCtrl     = TextEditingController(text: '0');
  final _stMaxCtrl     = TextEditingController(text: '0');
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadArticulo();
    else setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [_codigoCtrl, _descCtrl, _barrasCtrl, _lineaCtrl, _medidaCtrl,
                     _marcaCtrl, _pCompraCtrl, _pVentaCtrl, _utilidadCtrl, _stMinCtrl, _stMaxCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadArticulo() async {
    final result = await _repo.search(q: widget.articuloId, limit: 1);
    result.fold(
      (e) { setState(() => _loading = false); },
      (page) {
        final a = page.data.isNotEmpty ? page.data.first : null;
        if (a != null) _populate(a);
        setState(() { _loading = false; _current = a; });
      },
    );
  }

  void _populate(Articulo a) {
    _codigoCtrl.text   = a.codigo;
    _descCtrl.text     = a.descripcion;
    _barrasCtrl.text   = a.codigoBarras ?? '';
    _lineaCtrl.text    = a.codigoLinea ?? '';
    _medidaCtrl.text   = a.codigoMedida ?? '';
    _marcaCtrl.text    = a.codigoMarca ?? '';
    _pCompraCtrl.text  = a.precioCompra.toStringAsFixed(4);
    _pVentaCtrl.text   = a.precioVenta.toStringAsFixed(4);
    _utilidadCtrl.text = a.utilidadPct.toStringAsFixed(2);
    _stMinCtrl.text    = a.stockMinimo.toStringAsFixed(2);
    _stMaxCtrl.text    = a.stockMaximo.toStringAsFixed(2);
    _activo            = a.activo;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'codigo'         : _codigoCtrl.text.toUpperCase(),
      'descripcion'    : _descCtrl.text,
      'codigoBarras'   : _barrasCtrl.text.isEmpty ? null : _barrasCtrl.text,
      'codigoLinea'    : _lineaCtrl.text.isEmpty ? null : _lineaCtrl.text.toUpperCase(),
      'codigoMedida'   : _medidaCtrl.text.isEmpty ? null : _medidaCtrl.text.toUpperCase(),
      'codigoMarca'    : _marcaCtrl.text.isEmpty ? null : _marcaCtrl.text.toUpperCase(),
      'precioCompra'   : double.tryParse(_pCompraCtrl.text) ?? 0,
      'precioVenta'    : double.tryParse(_pVentaCtrl.text) ?? 0,
      'utilidadPct'    : double.tryParse(_utilidadCtrl.text) ?? 0,
      'stockMinimo'    : double.tryParse(_stMinCtrl.text) ?? 0,
      'stockMaximo'    : double.tryParse(_stMaxCtrl.text) ?? 0,
      'activo'         : _activo,
    };
    final result = await _repo.save(data, id: widget.articuloId);
    setState(() => _saving = false);
    result.fold(
      (e) => _showError(e.message),
      (_)  => context.pop(true),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar Artículo' : 'Nuevo Artículo'),
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
            _section('Identificación'),
            Row(children: [
              Expanded(flex: 2, child: _field(_codigoCtrl, 'Código *', enabled: !widget.isEdit, maxLength: 10, caps: true)),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: _field(_barrasCtrl, 'Cód. Barras', maxLength: 50)),
            ]),
            _field(_descCtrl, 'Descripción *', maxLength: 150, required: true),
            _section('Clasificación'),
            Row(children: [
              Expanded(child: _field(_lineaCtrl, 'Línea', maxLength: 5, caps: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_medidaCtrl, 'Medida', maxLength: 5, caps: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_marcaCtrl, 'Marca', maxLength: 5, caps: true)),
            ]),
            _section('Precios'),
            Row(children: [
              Expanded(child: _numField(_pCompraCtrl, 'P. Compra')),
              const SizedBox(width: 12),
              Expanded(child: _numField(_utilidadCtrl, 'Utilidad %')),
              const SizedBox(width: 12),
              Expanded(child: _numField(_pVentaCtrl, 'P. Venta')),
            ]),
            _section('Stock'),
            Row(children: [
              Expanded(child: _numField(_stMinCtrl, 'Stock Mínimo')),
              const SizedBox(width: 12),
              Expanded(child: _numField(_stMaxCtrl, 'Stock Máximo')),
            ]),
            if (widget.isEdit) ...[
              _section('Estado'),
              SwitchListTile(
                title: const Text('Activo'),
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    bool enabled = true,
    int? maxLength,
    bool caps = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          enabled: enabled,
          maxLength: maxLength,
          textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
            counterText: '',
          ),
          validator: required ? (v) => (v == null || v.isEmpty) ? 'Requerido' : null : null,
        ),
      );

  Widget _numField(TextEditingController ctrl, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        ),
      );
}
