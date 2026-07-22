import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../maestros/domain/repositories/cliente_repository.dart';
import '../../../maestros/domain/repositories/articulo_repository.dart';
import '../../../maestros/domain/repositories/almacen_repository.dart' as maestro;
import '../../../maestros/domain/entities/cliente.dart';
import '../../../maestros/domain/entities/articulo.dart';
import '../../../maestros/domain/entities/almacen.dart' as mae;
import '../../../maestros/data/datasources/maestros_remote_datasource.dart';
import '../../../maestros/presentation/widgets/maestro_picker.dart';
import '../../../tablas/data/datasources/tablas_remote_datasource.dart';
import '../../../tablas/data/models/tabla_model.dart';
import '../../../tablas/domain/entities/tabla_base.dart';
import '../../../tipo_cambio/data/datasources/tipo_cambio_remote_datasource.dart';
import '../../data/datasources/ventas_remote_datasource.dart';
import '../../domain/entities/venta.dart';
import '../bloc/venta_bloc.dart';
import '../bloc/venta_event.dart';
import '../bloc/venta_state.dart';
import '../../../../core/widgets/aries_app_bar.dart';
import '../../../../core/widgets/number_form_field.dart';

class VentaFormPage extends StatelessWidget {
  const VentaFormPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => VentaBloc(getIt<VentasRemoteDataSource>()),
    child: const _Form(),
  );
}

class _Linea {
  final String codigo;
  final String descripcion;
  double cantidad;
  double precio;   // siempre en la moneda seleccionada
  double descPct;
  _Linea({required this.codigo, required this.descripcion,
          required this.cantidad, required this.precio, this.descPct = 0});
  double get base    => cantidad * precio;
  double get importe => base * (1 - descPct / 100);
}

class _Form extends StatefulWidget {
  const _Form();
  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _formKey = GlobalKey<FormState>();
  final _obsCtrl = TextEditingController();
  final _tcCtrl  = TextEditingController(text: '1.0000');

  List<Documento> _documentos = [];
  Documento? _documento;
  String _fecha  = DateTime.now().toIso8601String().substring(0, 10);
  TipoVenta _tipo = TipoVenta.CONTADO;
  int _plazo      = 30;
  String _moneda  = 'PEN';
  double _tipoCambio = 1.0;

  String? _almacen, _almNombre, _clienteCodigo, _cliNombre;
  String? _clienteTipoLista;

  final List<_Linea> _lineas = [];

  double _igvPct    = 18.0;
  bool   _aplicaIgv = true;

  @override
  void initState() {
    super.initState();
    _loadConfiguracion();
  }

  @override
  void dispose() { _obsCtrl.dispose(); _tcCtrl.dispose(); super.dispose(); }

  Future<void> _loadConfiguracion() async {
    try {
      final results = await Future.wait([
        getIt<VentasRemoteDataSource>().getParametros(),
        getIt<TablasRemoteDataSource>().list('documentos', activo: true, tipo: 'VENTA'),
      ]);
      final params = results[0] as Map<String, dynamic>;
      final docs   = (results[1] as List<Map<String, dynamic>>)
          .map(TablaModel.documentoFromJson).toList();
      if (mounted) {
        setState(() {
          _igvPct    = (params['igv'] as num?)?.toDouble() ?? 18.0;
          _documentos = docs;
          if (docs.length == 1) {
            _documento = docs.first;
            _aplicaIgv = docs.first.aplicaIgv;
          }
        });
      }
    } catch (_) {}
    await _fetchTipoCambio();
  }

  Future<void> _fetchTipoCambio() async {
    try {
      final tc = await getIt<TipoCambioRemoteDataSource>().getByFecha(_fecha);
      if (tc != null && mounted) {
        setState(() {
          _tipoCambio = tc.tipoCambio;
          _tcCtrl.text = tc.tipoCambio.toStringAsFixed(4);
        });
      }
    } catch (_) {}
  }

  double get _subtotalMoneda => _lineas.fold(0, (s, l) => s + l.importe);
  double get _tc => _tipoCambio > 0 ? _tipoCambio : 1;
  double get _subtotalPen => _moneda == 'USD' ? _subtotalMoneda * _tc : _subtotalMoneda;
  double get _subtotalUsd => _moneda == 'USD' ? _subtotalMoneda : _subtotalMoneda / _tc;
  double get _igvPen  => _aplicaIgv ? _subtotalPen * (_igvPct / 100) : 0;
  double get _igvUsd  => _aplicaIgv ? _subtotalUsd * (_igvPct / 100) : 0;
  double get _totalPen => _subtotalPen + _igvPen;
  double get _totalUsd => _subtotalUsd + _igvUsd;

  void _onDocChanged(Documento? doc) {
    setState(() { _documento = doc; _aplicaIgv = doc?.aplicaIgv ?? true; });
  }

  Future<void> _pickAlmacen() async {
    final r = await MaestroPicker.show<mae.Almacen>(context,
      title: 'Almacén', onSearch: (q) async {
        final res = await getIt<maestro.AlmacenRepository>().findAll();
        return res.fold((_) => [], (l) => l
            .where((a) => a.descripcion.toLowerCase().contains(q.toLowerCase()))
            .toList());
      }, itemTitle: (a) => a.descripcion);
    if (r != null) setState(() { _almacen = r.codigo; _almNombre = r.descripcion; });
  }

  Future<void> _pickCliente() async {
    final r = await MaestroPicker.show<Cliente>(context,
      title: 'Cliente', onSearch: (q) async {
        final res = await getIt<ClienteRepository>().search(q: q, activo: true, page: 1);
        return res.fold((_) => [], (p) => p.data);
      }, itemTitle: (c) => c.razonSocial, itemSubtitle: (c) => c.rucDni ?? '');
    if (r != null) {
      setState(() {
        _clienteCodigo    = r.codigo;
        _cliNombre        = r.razonSocial;
        _clienteTipoLista = r.idTipoLista;
      });
      try {
        final cli = await getIt<MaestrosRemoteDataSource>().getCliente(r.id);
        if (mounted) setState(() => _clienteTipoLista = cli.idTipoLista);
      } catch (_) {}
    }
  }

  Future<void> _addLinea() async {
    final art = await MaestroPicker.show<Articulo>(context,
      title: 'Artículo', onSearch: (q) async {
        final res = await getIt<ArticuloRepository>().search(q: q, activo: true, page: 1);
        return res.fold((_) => [], (p) => p.data);
      }, itemTitle: (a) => a.descripcion);
    if (art == null || !mounted) return;

    double precioSugerido = art.precioVentaBase > 0 ? art.precioVentaBase : art.precioVenta;
    // Si moneda es USD, convertir precio sugerido
    if (_moneda == 'USD' && _tipoCambio > 0) {
      precioSugerido = precioSugerido / _tipoCambio;
    }

    if (_clienteTipoLista != null) {
      try {
        final lp = await getIt<MaestrosRemoteDataSource>()
            .getPrecioParaCliente(art.id, _clienteTipoLista!);
        if (lp != null && lp.precioVenta > 0) {
          precioSugerido = _moneda == 'USD' ? lp.precioVenta / _tipoCambio : lp.precioVenta;
        }
      } catch (_) {}
    }

    final qCtrl   = TextEditingController(text: '1');
    final pCtrl   = TextEditingController(text: precioSugerido.toStringAsFixed(4));
    final dscCtrl = TextEditingController(text: '0');
    if (!mounted) return;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(art.descripcion),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        NumberFormField(controller: qCtrl,
            decoration: const InputDecoration(labelText: 'Cantidad')),
        const SizedBox(height: 8),
        NumberFormField(controller: pCtrl,
            decoration: InputDecoration(labelText: 'Precio unitario ($_moneda)')),
        const SizedBox(height: 8),
        NumberFormField(controller: dscCtrl,
            decoration: const InputDecoration(labelText: 'Descuento %')),
      ]),
      actions: [
        OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Agregar')),
      ],
    ));
    if (ok == true) {
      setState(() => _lineas.add(_Linea(
        codigo: art.codigo, descripcion: art.descripcion,
        cantidad: double.tryParse(qCtrl.text) ?? 1,
        precio:   double.tryParse(pCtrl.text) ?? 0,
        descPct:  double.tryParse(dscCtrl.text) ?? 0,
      )));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_documento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione el tipo de documento')));
      return;
    }
    if (_almacen == null || _clienteCodigo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione almacén y cliente')));
      return;
    }
    if (_lineas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agregue artículos')));
      return;
    }
    context.read<VentaBloc>().add(VentaRegistrar({
      'codigoDocumento': _documento!.codigo,
      'serie'          : _documento!.serie,
      'fecha'          : _fecha,
      'tipoVenta'      : _tipo.name,
      if (_tipo == TipoVenta.CREDITO) 'plazoDias': _plazo,
      if (_obsCtrl.text.trim().isNotEmpty) 'observacion': _obsCtrl.text.trim(),
      'codigoAlmacen'  : _almacen,
      'codigoCliente'  : _clienteCodigo,
      'moneda'         : _moneda,
      'tipoCambio'     : _tipoCambio,
      'lineas': _lineas.map((l) => {
        'codigoArticulo': l.codigo,
        'cantidad'      : l.cantidad,
        'precioUnitario': l.precio,
        if (l.descPct > 0) 'descuentoPct': l.descPct,
      }).toList(),
    }));
  }

  @override
  Widget build(BuildContext context) {
    final currLabel = _moneda == 'USD' ? 'USD' : 'S/';
    return Scaffold(
      appBar: AriesAppBar(title: const Text('Nueva Venta')),
      body: BlocConsumer<VentaBloc, VentaState>(
        listener: (ctx, state) {
          if (state is VentaSaved) {
            final docLabel = _documento?.abreviatura ?? state.venta.codigoDocumento;
            final nro = '$docLabel-${state.venta.serie}-${state.venta.numeroDocumento}';
            ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Venta registrada · $nro'), backgroundColor: Colors.green));
            ctx.pop(true);
          }
          if (state is VentaError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (ctx, state) {
          final saving = state is VentaSaving;
          return Stack(children: [
            Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
              // Documento
              DropdownButtonFormField<Documento>(
                value: _documento,
                decoration: const InputDecoration(labelText: 'Documento *', border: OutlineInputBorder(), isDense: true),
                items: _documentos.map((d) => DropdownMenuItem(
                  value: d,
                  child: Text('${d.descripcion}  [${d.serie}]', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: _onDocChanged,
                validator: (v) => v == null ? 'Seleccione un documento' : null,
              ),
              const SizedBox(height: 12),
              // Fecha
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Fecha: $_fecha'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.parse(_fecha),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now());
                  if (d != null) {
                    setState(() => _fecha = d.toIso8601String().substring(0, 10));
                    await _fetchTipoCambio();
                  }
                },
              ),
              const Divider(),
              // Tipo venta
              Row(children: [
                const Text('Tipo venta:'),
                const SizedBox(width: 12),
                ChoiceChip(label: const Text('Contado'), selected: _tipo == TipoVenta.CONTADO,
                    onSelected: (_) => setState(() => _tipo = TipoVenta.CONTADO)),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Crédito'), selected: _tipo == TipoVenta.CREDITO,
                    onSelected: (_) => setState(() => _tipo = TipoVenta.CREDITO)),
                if (_tipo == TipoVenta.CREDITO) ...[
                  const SizedBox(width: 12),
                  SizedBox(width: 60, child: NumberFormField(
                      initialValue: _plazo.toString(),
                      decoration: const InputDecoration(labelText: 'Días'),
                      allowDecimal: false,
                      onChanged: (v) => _plazo = int.tryParse(v ?? '') ?? 30)),
                ],
              ]),
              const SizedBox(height: 12),
              // Moneda y Tipo de Cambio
              Row(children: [
                const Text('Moneda:'),
                const SizedBox(width: 12),
                ChoiceChip(label: const Text('PEN'), selected: _moneda == 'PEN',
                    onSelected: (_) => setState(() => _moneda = 'PEN')),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('USD'), selected: _moneda == 'USD',
                    onSelected: (_) => setState(() => _moneda = 'USD')),
                const SizedBox(width: 12),
                Expanded(child: NumberFormField(
                  controller: _tcCtrl,
                  decoration: const InputDecoration(labelText: 'Tipo de Cambio', isDense: true),
                  onChanged: (v) => setState(() => _tipoCambio = double.tryParse(v ?? '') ?? 1.0),
                )),
              ]),
              const Divider(),
              // Almacén y cliente
              ListTile(contentPadding: EdgeInsets.zero,
                  title: Text(_almNombre ?? 'Seleccionar almacén'),
                  trailing: const Icon(Icons.warehouse), onTap: _pickAlmacen),
              ListTile(contentPadding: EdgeInsets.zero,
                  title: Text(_cliNombre ?? 'Seleccionar cliente'),
                  trailing: const Icon(Icons.person), onTap: _pickCliente),
              TextFormField(controller: _obsCtrl,
                  decoration: const InputDecoration(labelText: 'Observación (opcional)')),
              const Divider(),
              // Artículos
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Artículos', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(onPressed: _addLinea, icon: const Icon(Icons.add), label: const Text('Agregar')),
              ]),
              ..._lineas.asMap().entries.map((e) => ListTile(
                dense: true,
                title: Text(e.value.descripcion),
                subtitle: Text(
                  '${e.value.cantidad} × $currLabel ${e.value.precio.toStringAsFixed(4)}'
                  '${e.value.descPct > 0 ? " (-${e.value.descPct}%)" : ""}'
                  ' = $currLabel ${e.value.importe.toStringAsFixed(2)}',
                ),
                trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => setState(() => _lineas.removeAt(e.key))),
              )),
              const Divider(),
              // Totales en la moneda seleccionada
              if (_moneda == 'PEN') ...[
                _TRow('Subtotal', _subtotalPen, 'S/'),
                if (_aplicaIgv)
                  _TRow('IGV (${_igvPct.toStringAsFixed(0)}%)', _igvPen, 'S/')
                else
                  const Padding(padding: EdgeInsets.symmetric(vertical: 2),
                      child: Row(mainAxisAlignment: MainAxisAlignment.end,
                          children: [Text('Sin IGV', style: TextStyle(color: Colors.grey))])),
                _TRow('Total', _totalPen, 'S/', bold: true),
                if (_tc != 1.0) ...[
                  const SizedBox(height: 4),
                  _TRow('≈ Equivalente USD', _totalUsd, 'USD', color: Colors.blue.shade700),
                ],
              ] else ...[
                _TRow('Subtotal', _subtotalUsd, 'USD'),
                if (_aplicaIgv)
                  _TRow('IGV (${_igvPct.toStringAsFixed(0)}%)', _igvUsd, 'USD')
                else
                  const Padding(padding: EdgeInsets.symmetric(vertical: 2),
                      child: Row(mainAxisAlignment: MainAxisAlignment.end,
                          children: [Text('Sin IGV', style: TextStyle(color: Colors.grey))])),
                _TRow('Total', _totalUsd, 'USD', bold: true),
                const SizedBox(height: 4),
                _TRow('≈ Equivalente S/', _totalPen, 'S/', color: Colors.orange.shade700),
              ],
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : () => ctx.pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: saving ? null : _submit, child: const Text('Registrar Venta')),
                ),
              ]),
              const SizedBox(height: 40),
            ])),
            if (saving) const Positioned.fill(
                child: ColoredBox(color: Colors.black26,
                    child: Center(child: CircularProgressIndicator()))),
          ]);
        },
      ),
    );
  }
}

class _TRow extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final bool bold;
  final Color? color;
  const _TRow(this.label, this.value, this.currency, {this.bold = false, this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(label, style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color)),
      const SizedBox(width: 16),
      SizedBox(width: 110, child: Text('$currency ${value.toStringAsFixed(2)}',
          textAlign: TextAlign.right,
          style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color))),
    ]),
  );
}
