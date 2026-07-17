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
import '../../data/datasources/ventas_remote_datasource.dart';
import '../../domain/entities/venta.dart';
import '../bloc/venta_bloc.dart';
import '../bloc/venta_event.dart';
import '../bloc/venta_state.dart';

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
  double precio;
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

  String _codDoc = 'BOL';
  String _serie  = '0001';
  String _fecha  = DateTime.now().toIso8601String().substring(0, 10);
  TipoVenta _tipo = TipoVenta.CONTADO;
  int _plazo      = 30;

  String? _almacen, _almNombre, _clienteCodigo, _cliNombre;
  String? _clienteTipoLista;

  final List<_Linea> _lineas = [];

  // IGV dinámico
  double _igvPct    = 18.0;
  bool   _aplicaIgv = true;
  Map<String, bool> _docAplicaIgv = {};

  @override
  void initState() {
    super.initState();
    _loadConfiguracion();
  }

  @override
  void dispose() { _obsCtrl.dispose(); super.dispose(); }

  Future<void> _loadConfiguracion() async {
    final ds = getIt<VentasRemoteDataSource>();
    try {
      final results = await Future.wait([
        ds.getParametros(),
        ds.getDocumentos(),
      ]);
      final params = results[0] as Map<String, dynamic>;
      final docs   = results[1] as List<Map<String, dynamic>>;
      if (mounted) {
        setState(() {
          _igvPct = (params['igv'] as num?)?.toDouble() ?? 18.0;
          _docAplicaIgv = {
            for (final d in docs)
              (d['codigo'] as String? ?? ''): d['aplicaIgv'] as bool? ?? true,
          };
          _aplicaIgv = _docAplicaIgv[_codDoc] ?? true;
        });
      }
    } catch (_) {}
  }

  double get _subtotal => _lineas.fold(0, (s, l) => s + l.importe);
  double get _igv      => _aplicaIgv ? _subtotal * (_igvPct / 100) : 0;
  double get _total    => _subtotal + _igv;

  void _onDocChanged(String v) {
    setState(() {
      _codDoc    = v;
      _aplicaIgv = _docAplicaIgv[v] ?? true;
    });
  }

  Future<void> _pickAlmacen() async {
    final r = await MaestroPicker.show<mae.Almacen>(context,
      title: 'Almacén', onSearch: (q) async {
        final res = await getIt<maestro.AlmacenRepository>().findAll();
        return res.fold((_) => [], (l) => l
            .where((a) => a.descripcion.toLowerCase().contains(q.toLowerCase()))
            .toList());
      }, itemTitle: (a) => a.descripcion, itemSubtitle: (a) => a.codigo);
    if (r != null) setState(() { _almacen = r.codigo; _almNombre = r.descripcion; });
  }

  Future<void> _pickCliente() async {
    final r = await MaestroPicker.show<Cliente>(context,
      title: 'Cliente', onSearch: (q) async {
        final res = await getIt<ClienteRepository>().search(q: q, page: 1);
        return res.fold((_) => [], (p) => p.data);
      }, itemTitle: (c) => c.razonSocial, itemSubtitle: (c) => c.rucDni ?? c.codigo);
    if (r != null) {
      setState(() {
        _clienteCodigo    = r.codigo;
        _cliNombre        = r.razonSocial;
        _clienteTipoLista = r.idTipoLista;
      });
      // Recargar cliente completo para obtener idTipoLista
      try {
        final cli = await getIt<MaestrosRemoteDataSource>().getCliente(r.id);
        if (mounted) setState(() => _clienteTipoLista = cli.idTipoLista);
      } catch (_) {}
    }
  }

  Future<void> _addLinea() async {
    final art = await MaestroPicker.show<Articulo>(context,
      title: 'Artículo', onSearch: (q) async {
        final res = await getIt<ArticuloRepository>().search(q: q, page: 1);
        return res.fold((_) => [], (p) => p.data);
      }, itemTitle: (a) => a.descripcion, itemSubtitle: (a) => a.codigo);
    if (art == null || !mounted) return;

    // Intentar obtener precio desde lista del cliente
    double precioSugerido = art.precioVentaBase > 0
        ? art.precioVentaBase
        : art.precioVenta;

    if (_clienteTipoLista != null) {
      try {
        final lp = await getIt<MaestrosRemoteDataSource>()
            .getPrecioParaCliente(art.id, _clienteTipoLista!);
        if (lp != null && lp.precioVenta > 0) {
          precioSugerido = lp.precioVenta;
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
        TextFormField(controller: qCtrl,   keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cantidad')),
        const SizedBox(height: 8),
        TextFormField(controller: pCtrl,   keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Precio unitario')),
        const SizedBox(height: 8),
        TextFormField(controller: dscCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Descuento %')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Agregar')),
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
      'codigoDocumento': _codDoc,
      'serie'          : _serie,
      'fecha'          : _fecha,
      'tipoVenta'      : _tipo.name,
      if (_tipo == TipoVenta.CREDITO) 'plazoDias': _plazo,
      if (_obsCtrl.text.trim().isNotEmpty) 'observacion': _obsCtrl.text.trim(),
      'codigoAlmacen': _almacen,
      'codigoCliente': _clienteCodigo,
      'lineas': _lineas.map((l) => {
        'codigoArticulo': l.codigo,
        'cantidad'       : l.cantidad,
        'precioUnitario' : l.precio,
        if (l.descPct > 0) 'descuentoPct': l.descPct,
      }).toList(),
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Venta')),
      body: BlocConsumer<VentaBloc, VentaState>(
        listener: (ctx, state) {
          if (state is VentaSaved) {
            final nro = '${state.venta.codigoDocumento}-${state.venta.serie}-${state.venta.numeroDocumento}';
            ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Venta registrada · $nro'), backgroundColor: Colors.green));
            ctx.pop();
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
              Row(children: [
                SizedBox(width: 80, child: TextFormField(
                    initialValue: _codDoc,
                    decoration: const InputDecoration(labelText: 'Doc'),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: _onDocChanged)),
                const SizedBox(width: 12),
                SizedBox(width: 90, child: TextFormField(
                    initialValue: _serie,
                    decoration: const InputDecoration(labelText: 'Serie'),
                    onChanged: (v) => _serie = v.isEmpty ? '0001' : v)),
                const SizedBox(width: 12),
                const Expanded(child: Text('N.º: Auto', style: TextStyle(color: Colors.grey))),
              ]),
              const SizedBox(height: 12),
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
                  if (d != null) setState(() => _fecha = d.toIso8601String().substring(0, 10));
                },
              ),
              const Divider(),
              Row(children: [
                const Text('Tipo venta:'),
                const SizedBox(width: 12),
                ChoiceChip(
                    label: const Text('Contado'),
                    selected: _tipo == TipoVenta.CONTADO,
                    onSelected: (_) => setState(() => _tipo = TipoVenta.CONTADO)),
                const SizedBox(width: 8),
                ChoiceChip(
                    label: const Text('Crédito'),
                    selected: _tipo == TipoVenta.CREDITO,
                    onSelected: (_) => setState(() => _tipo = TipoVenta.CREDITO)),
                if (_tipo == TipoVenta.CREDITO) ...[
                  const SizedBox(width: 12),
                  SizedBox(width: 60, child: TextFormField(
                      initialValue: _plazo.toString(),
                      decoration: const InputDecoration(labelText: 'Días'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _plazo = int.tryParse(v) ?? 30)),
                ],
              ]),
              const Divider(),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_almNombre ?? 'Seleccionar almacén'),
                  trailing: const Icon(Icons.warehouse),
                  onTap: _pickAlmacen),
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_cliNombre ?? 'Seleccionar cliente'),
                  trailing: const Icon(Icons.person),
                  onTap: _pickCliente),
              TextFormField(
                  controller: _obsCtrl,
                  decoration: const InputDecoration(labelText: 'Observación (opcional)')),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Artículos', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                    onPressed: _addLinea,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar')),
              ]),
              ..._lineas.asMap().entries.map((e) => ListTile(
                dense: true,
                title: Text(e.value.descripcion),
                subtitle: Text('${e.value.cantidad} × ${e.value.precio.toStringAsFixed(4)}'
                    '${e.value.descPct > 0 ? " (-${e.value.descPct}%)" : ""}'
                    ' = S/ ${e.value.importe.toStringAsFixed(2)}'),
                trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => setState(() => _lineas.removeAt(e.key))),
              )),
              const Divider(),
              _TRow('Subtotal', _subtotal),
              if (_aplicaIgv)
                _TRow('IGV (${_igvPct.toStringAsFixed(0)}%)', _igv)
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end,
                      children: [Text('Sin IGV', style: TextStyle(color: Colors.grey))]),
                ),
              _TRow('Total', _total, bold: true),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: saving ? null : _submit,
                  child: const Text('Registrar Venta')),
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
  final String label; final double value; final bool bold;
  const _TRow(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      const SizedBox(width: 16),
      SizedBox(width: 90, child: Text('S/ ${value.toStringAsFixed(2)}',
          textAlign: TextAlign.right,
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
    ]),
  );
}
