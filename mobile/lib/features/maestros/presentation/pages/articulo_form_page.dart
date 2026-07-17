import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/unique_id.dart';
import '../../domain/entities/articulo.dart';
import '../../domain/entities/lista_precio.dart';
import '../../domain/repositories/articulo_repository.dart';
import '../../data/datasources/maestros_remote_datasource.dart';
import '../../../tablas/data/datasources/tablas_remote_datasource.dart';
import '../../../tablas/data/models/tabla_model.dart';
import '../../../tablas/domain/entities/tabla_base.dart';

class ArticuloFormPage extends StatefulWidget {
  final String? articuloId;
  const ArticuloFormPage({super.key, this.articuloId});

  bool get isEdit => articuloId != null;

  @override
  State<ArticuloFormPage> createState() => _ArticuloFormPageState();
}

class _ArticuloFormPageState extends State<ArticuloFormPage> {
  final _formKey   = GlobalKey<FormState>();
  final _repo      = getIt<ArticuloRepository>();
  final _tablasDs  = getIt<TablasRemoteDataSource>();
  final _maestroDs = getIt<MaestrosRemoteDataSource>();

  bool _loading = true;
  bool _saving  = false;

  final _codigoCtrl     = TextEditingController();
  final _descCtrl       = TextEditingController();
  final _barrasCtrl     = TextEditingController();
  final _pCompraBaseCtrl = TextEditingController(text: '0.0000');
  final _pCompraCtrl    = TextEditingController(text: '0.0000');
  final _pVentaBaseCtrl = TextEditingController(text: '0.0000');
  final _pVentaCtrl     = TextEditingController(text: '0.0000');
  final _utilidadCtrl   = TextEditingController(text: '0.00');
  final _stMinCtrl      = TextEditingController(text: '0');
  final _stMaxCtrl      = TextEditingController(text: '0');
  bool _activo = true;

  String? _selectedLinea;
  String? _selectedMedida;
  String? _selectedMarca;

  List<Linea>     _lineas     = [];
  List<Medida>    _medidas    = [];
  List<Marca>     _marcas     = [];
  List<TipoLista> _tiposLista = [];

  List<ListaPrecio> _listaPrecios = [];
  // Operaciones pendientes de lista_precios (solo se ejecutan al guardar)
  final List<_PrecioOp> _pendingOps = [];

  @override
  void initState() {
    super.initState();
    _initForm();
  }

  @override
  void dispose() {
    for (final c in [_codigoCtrl, _descCtrl, _barrasCtrl,
                     _pCompraBaseCtrl, _pCompraCtrl, _pVentaBaseCtrl,
                     _pVentaCtrl, _utilidadCtrl, _stMinCtrl, _stMaxCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _initForm() async {
    final results = await Future.wait([
      _tablasDs.list('lineas',      activo: true),
      _tablasDs.list('medidas',     activo: true),
      _tablasDs.list('marcas',      activo: true),
      _tablasDs.list('tipos-lista', activo: true),
    ]);

    if (!mounted) return;
    setState(() {
      _lineas     = results[0].map(TablaModel.lineaFromJson).toList();
      _medidas    = results[1].map(TablaModel.medidaFromJson).toList();
      _marcas     = results[2].map(TablaModel.marcaFromJson).toList();
      _tiposLista = results[3].map(TablaModel.tipoListaFromJson).toList();
    });

    if (widget.isEdit) {
      await _loadArticulo();
    } else {
      _codigoCtrl.text = uniqueId(8);
      setState(() => _loading = false);
    }
  }

  Future<void> _loadArticulo() async {
    try {
      final a = await _maestroDs.getArticulo(widget.articuloId!);
      if (!mounted) return;
      _populate(a);
      try {
        final lp = await _maestroDs.listPrecios(a.id);
        if (mounted) setState(() => _listaPrecios = lp);
      } catch (_) {}
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _populate(Articulo a) {
    _codigoCtrl.text      = a.codigo;
    _descCtrl.text        = a.descripcion;
    _barrasCtrl.text      = a.codigoBarras ?? '';
    _pCompraBaseCtrl.text = a.precioCompraBase.toStringAsFixed(4);
    _pCompraCtrl.text     = a.precioCompra.toStringAsFixed(4);
    _pVentaBaseCtrl.text  = a.precioVentaBase.toStringAsFixed(4);
    _pVentaCtrl.text      = a.precioVenta.toStringAsFixed(4);
    _utilidadCtrl.text    = a.utilidadPct.toStringAsFixed(2);
    _stMinCtrl.text       = a.stockMinimo.toStringAsFixed(2);
    _stMaxCtrl.text       = a.stockMaximo.toStringAsFixed(2);
    _activo               = a.activo;
    _selectedLinea  = _lineas.any((l) => l.codigo == a.codigoLinea)   ? a.codigoLinea  : null;
    _selectedMedida = _medidas.any((m) => m.codigo == a.codigoMedida) ? a.codigoMedida : null;
    _selectedMarca  = _marcas.any((m) => m.codigo == a.codigoMarca)   ? a.codigoMarca  : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      if (!widget.isEdit) 'codigo': _codigoCtrl.text.toUpperCase(),
      'descripcion'     : _descCtrl.text,
      'activo'          : _activo,
      if (_barrasCtrl.text.isNotEmpty) 'codigoBarras': _barrasCtrl.text,
      if (_selectedLinea  != null) 'codigoLinea' : _selectedLinea,
      if (_selectedMedida != null) 'codigoMedida': _selectedMedida,
      if (_selectedMarca  != null) 'codigoMarca' : _selectedMarca,
      'precioCompraBase': double.tryParse(_pCompraBaseCtrl.text) ?? 0,
      'precioCompra'    : double.tryParse(_pCompraCtrl.text)     ?? 0,
      'precioVentaBase' : double.tryParse(_pVentaBaseCtrl.text)  ?? 0,
      'precioVenta'     : double.tryParse(_pVentaCtrl.text)      ?? 0,
      'utilidadPct'     : double.tryParse(_utilidadCtrl.text)    ?? 0,
      'stockMinimo'     : double.tryParse(_stMinCtrl.text)       ?? 0,
      'stockMaximo'     : double.tryParse(_stMaxCtrl.text)       ?? 0,
    };

    final result = await _repo.save(data, id: widget.articuloId);
    if (!mounted) { setState(() => _saving = false); return; }

    await result.fold(
      (e) async {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Theme.of(context).colorScheme.error),
        );
      },
      (saved) async {
        bool precioError = false;
        for (final op in _pendingOps) {
          try {
            if (op.isDelete) {
              await _maestroDs.deleteListaPrecio(op.id!);
            } else {
              final body = {...op.data!, 'idArticulo': saved.id};
              await _maestroDs.saveListaPrecio(body, id: op.id);
            }
          } catch (_) {
            precioError = true;
          }
        }
        setState(() => _saving = false);
        if (mounted) {
          if (precioError) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Artículo guardado, pero falló guardar algún precio')),
            );
          }
          context.pop(true);
        }
      },
    );
  }

  double get _precioVentaBase => double.tryParse(_pVentaBaseCtrl.text) ?? 0;

  void _openPrecioDialog([ListaPrecio? lp]) {
    if (_precioVentaBase <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese el Valor de Venta')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _PrecioDialog(
        tiposLista: _tiposLista,
        precioVentaBase: _precioVentaBase,
        existing: lp,
        onSave: (data, id) {
          setState(() {
            if (id != null) {
              // Editar en lista local
              final idx = _listaPrecios.indexWhere((p) => p.id == id);
              if (idx >= 0) {
                _listaPrecios[idx] = ListaPrecio(
                  id: id,
                  codigoEmpresa: _listaPrecios[idx].codigoEmpresa,
                  idArticulo: _listaPrecios[idx].idArticulo,
                  idTipoLista: data['idTipoLista'] as String,
                  descripcionTipoLista: _tiposLista
                      .firstWhere((t) => t.id == data['idTipoLista'],
                          orElse: () => _tiposLista.first)
                      .descripcion,
                  precioVentaBase: (data['precioVentaBase'] as num).toDouble(),
                  descuentoPct: (data['descuentoPct'] as num).toDouble(),
                  descuentoMonto: (data['descuentoMonto'] as num).toDouble(),
                  precioVenta: (data['precioVenta'] as num).toDouble(),
                  activo: data['activo'] as bool? ?? true,
                );
              }
              _pendingOps.removeWhere((o) => o.id == id && !o.isDelete);
              _pendingOps.add(_PrecioOp(id: id, data: data));
            } else {
              // Nuevo (temporal, se guarda al guardar artículo)
              final tipoDesc = _tiposLista
                  .firstWhere((t) => t.id == data['idTipoLista'],
                      orElse: () => _tiposLista.first)
                  .descripcion;
              final tempId = 'tmp_${_pendingOps.length}';
              _listaPrecios.add(ListaPrecio(
                id: tempId,
                codigoEmpresa: '',
                idArticulo: '',
                idTipoLista: data['idTipoLista'] as String,
                descripcionTipoLista: tipoDesc,
                precioVentaBase: (data['precioVentaBase'] as num).toDouble(),
                descuentoPct: (data['descuentoPct'] as num).toDouble(),
                descuentoMonto: (data['descuentoMonto'] as num).toDouble(),
                precioVenta: (data['precioVenta'] as num).toDouble(),
                activo: data['activo'] as bool? ?? true,
              ));
              _pendingOps.add(_PrecioOp(data: data));
            }
          });
        },
      ),
    );
  }

  void _deletePrecio(ListaPrecio lp) {
    setState(() {
      _listaPrecios.removeWhere((p) => p.id == lp.id);
      if (lp.id.startsWith('tmp_')) {
        // Era temporal, solo remover de pending
        _pendingOps.removeLast();
      } else {
        _pendingOps.add(_PrecioOp(id: lp.id, isDelete: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar Artículo' : 'Nuevo Artículo'),
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(12),
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
            _section('Identificación'),
            Row(children: [
              Expanded(flex: 2, child: _field(_codigoCtrl, 'Código', enabled: false)),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: _field(_barrasCtrl, 'Cód. Barras', maxLength: 50)),
            ]),
            _field(_descCtrl, 'Descripción *', maxLength: 150, required: true),
            _section('Clasificación'),
            _tableDropdown<Linea>(
              label: 'Línea', items: _lineas, value: _selectedLinea,
              onChanged: (v) => setState(() => _selectedLinea = v),
            ),
            const SizedBox(height: 12),
            _tableDropdown<Medida>(
              label: 'Medida / Unidad', items: _medidas, value: _selectedMedida,
              onChanged: (v) => setState(() => _selectedMedida = v),
            ),
            const SizedBox(height: 12),
            _tableDropdown<Marca>(
              label: 'Marca', items: _marcas, value: _selectedMarca,
              onChanged: (v) => setState(() => _selectedMarca = v),
            ),
            _section('Precios'),
            Row(children: [
              Expanded(child: _numField(_pCompraBaseCtrl, 'P. Compra Base')),
              const SizedBox(width: 8),
              Expanded(child: _numField(_pCompraCtrl, 'P. Compra')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _numField(_pVentaBaseCtrl, 'P. Venta Base *', required: true)),
              const SizedBox(width: 8),
              Expanded(child: _numField(_utilidadCtrl, 'Utilidad %')),
              const SizedBox(width: 8),
              Expanded(child: _numField(_pVentaCtrl, 'P. Venta')),
            ]),
            _section('Stock'),
            Row(children: [
              Expanded(child: _numField(_stMinCtrl, 'Stock Mín.')),
              const SizedBox(width: 12),
              Expanded(child: _numField(_stMaxCtrl, 'Stock Máx.')),
            ]),
            _section('Lista de Precios'),
            ..._listaPrecios.map((lp) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: lp.activo
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.grey.shade300,
                  child: Icon(Icons.price_change,
                      size: 16,
                      color: lp.activo
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Colors.grey),
                ),
                title: Text(lp.descripcionTipoLista,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Base: ${lp.precioVentaBase.toStringAsFixed(2)}'
                  '${lp.descuentoPct > 0 ? "  Dscto: ${lp.descuentoPct.toStringAsFixed(1)}%" : ""}'
                  '${lp.descuentoMonto > 0 ? "  Dscto: S/${lp.descuentoMonto.toStringAsFixed(2)}" : ""}'
                  '  →  S/${lp.precioVenta.toStringAsFixed(2)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _openPrecioDialog(lp),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: () => _deletePrecio(lp),
                    ),
                  ],
                ),
              ),
            )),
            OutlinedButton.icon(
              onPressed: () => _openPrecioDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar precio'),
            ),
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
        child: Text(title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
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
          validator: required ? (v) => (v == null || v.isEmpty) ? 'Requerido' : null : null,
        ),
      );

  Widget _numField(TextEditingController ctrl, String label, {bool required = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder(), isDense: true),
          validator: required
              ? (v) {
                  final d = double.tryParse(v ?? '');
                  if (d == null || d <= 0) return 'Debe ser > 0';
                  return null;
                }
              : null,
        ),
      );

  Widget _tableDropdown<T extends TablaBase>({
    required String label,
    required List<T> items,
    required String? value,
    required void Function(String?) onChanged,
  }) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('— Sin selección —')),
          ...items.map((t) => DropdownMenuItem<String>(
                value: t.codigo,
                child: Text('${t.codigo}  ${t.descripcion}', overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged: onChanged,
      );
}

// ── Operación pendiente de lista_precios ─────────────────────────────────────

class _PrecioOp {
  final String? id;
  final Map<String, dynamic>? data;
  final bool isDelete;
  const _PrecioOp({this.id, this.data, this.isDelete = false});
}

// ── Diálogo agregar/editar precio ────────────────────────────────────────────

class _PrecioDialog extends StatefulWidget {
  final List<TipoLista> tiposLista;
  final double precioVentaBase;
  final ListaPrecio? existing;
  final void Function(Map<String, dynamic> data, String? id) onSave;

  const _PrecioDialog({
    required this.tiposLista,
    required this.precioVentaBase,
    this.existing,
    required this.onSave,
  });

  @override
  State<_PrecioDialog> createState() => _PrecioDialogState();
}

class _PrecioDialogState extends State<_PrecioDialog> {
  final _formKey   = GlobalKey<FormState>();
  final _pctCtrl   = TextEditingController(text: '0');
  final _montoCtrl = TextEditingController(text: '0');

  TipoLista? _selectedTipo;
  double _precioVenta = 0;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _selectedTipo = widget.tiposLista.where((t) => t.id == ex.idTipoLista).firstOrNull;
      _pctCtrl.text   = ex.descuentoPct.toStringAsFixed(2);
      _montoCtrl.text = ex.descuentoMonto.toStringAsFixed(2);
      _activo         = ex.activo;
      _calcPrecio();
    } else {
      _precioVenta = widget.precioVentaBase;
    }
    _pctCtrl.addListener(_calcPrecio);
    _montoCtrl.addListener(_calcPrecio);
  }

  @override
  void dispose() {
    _pctCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  void _onTipoChanged(TipoLista? tipo) {
    setState(() {
      _selectedTipo = tipo;
      if (tipo != null) {
        _pctCtrl.text   = tipo.dsctoPct.toStringAsFixed(2);
        _montoCtrl.text = tipo.dctoMto.toStringAsFixed(2);
      }
    });
    _calcPrecio();
  }

  void _calcPrecio() {
    final base  = widget.precioVentaBase;
    final pct   = double.tryParse(_pctCtrl.text)   ?? 0;
    final monto = double.tryParse(_montoCtrl.text)  ?? 0;
    double precio;
    if (pct > 0) {
      precio = base * (1 - pct / 100);
    } else if (monto > 0) {
      precio = base - monto;
    } else {
      precio = base;
    }
    setState(() => _precioVenta = precio < 0 ? 0 : precio);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final data = <String, dynamic>{
      'idTipoLista'   : _selectedTipo!.id,
      'precioVentaBase': widget.precioVentaBase,
      'descuentoPct'  : double.tryParse(_pctCtrl.text)   ?? 0,
      'descuentoMonto': double.tryParse(_montoCtrl.text)  ?? 0,
      'precioVenta'   : _precioVenta,
      'activo'        : _activo,
    };
    widget.onSave(data, widget.existing?.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Editar precio' : 'Agregar precio'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<TipoLista>(
                initialValue: _selectedTipo,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de lista *',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: widget.tiposLista.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.descripcion, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: _onTipoChanged,
                validator: (v) => v == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              Text('P. Venta Base: S/${widget.precioVentaBase.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pctCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Descuento %',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _montoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Descuento S/.',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Precio de venta: S/${_precioVenta.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activo'),
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}
