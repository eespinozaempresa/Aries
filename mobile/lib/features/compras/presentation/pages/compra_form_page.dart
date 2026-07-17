import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../maestros/domain/repositories/proveedor_repository.dart';
import '../../../maestros/domain/repositories/articulo_repository.dart';
import '../../../maestros/domain/repositories/almacen_repository.dart' as maestro;
import '../../../maestros/domain/entities/proveedor.dart';
import '../../../maestros/domain/entities/articulo.dart';
import '../../../maestros/domain/entities/almacen.dart' as mae;
import '../../../maestros/presentation/widgets/maestro_picker.dart';
import '../../../tablas/data/datasources/tablas_remote_datasource.dart';
import '../../../tablas/data/models/tabla_model.dart';
import '../../../tablas/domain/entities/tabla_base.dart';
import '../../data/datasources/compras_remote_datasource.dart';
import '../../domain/entities/compra.dart';
import '../bloc/compra_bloc.dart';
import '../bloc/compra_event.dart';
import '../bloc/compra_state.dart';

class CompraFormPage extends StatelessWidget {
  const CompraFormPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CompraBloc(getIt<ComprasRemoteDataSource>()),
    child: const _Form(),
  );
}

class _LineaEntry {
  final String codigo;
  final String descripcion;
  double cantidad;
  double precio;
  _LineaEntry({required this.codigo, required this.descripcion, required this.cantidad, required this.precio});
  double get importe => cantidad * precio;
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
  FormaPago _forma  = FormaPago.CONTADO;
  int _plazo        = 30;
  String _moneda    = 'PEN';

  String? _almacen;
  String? _almacenNombre;
  String? _proveedor;
  String? _proveedorNombre;

  final List<_LineaEntry> _lineas = [];

  @override
  void initState() {
    super.initState();
    _loadDocumentos();
  }

  Future<void> _loadDocumentos() async {
    try {
      final ds = getIt<TablasRemoteDataSource>();
      final raw = await ds.list('documentos', activo: true, tipo: 'COMPRA');
      if (mounted) {
        setState(() {
          _documentos = raw.map(TablaModel.documentoFromJson).toList();
          if (_documentos.length == 1) _documento = _documentos.first;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() { _obsCtrl.dispose(); _tcCtrl.dispose(); super.dispose(); }

  double get _subtotal => _lineas.fold(0, (s, l) => s + l.importe);
  double get _igv      => _subtotal * 0.18;
  double get _total    => _subtotal + _igv;

  Future<void> _pickAlmacen() async {
    final repo = getIt<maestro.AlmacenRepository>();
    final r = await MaestroPicker.show<mae.Almacen>(context,
      title: 'Almacén', onSearch: (q) async {
        final res = await repo.findAll();
        return res.fold((_) => [], (l) => l.where((a) => a.descripcion.toLowerCase().contains(q.toLowerCase())).toList());
      }, itemTitle: (a) => a.descripcion, itemSubtitle: (a) => a.codigo);
    if (r != null) setState(() { _almacen = r.codigo; _almacenNombre = r.descripcion; });
  }

  Future<void> _pickProveedor() async {
    final repo = getIt<ProveedorRepository>();
    final r = await MaestroPicker.show<Proveedor>(context,
      title: 'Proveedor', onSearch: (q) async {
        final res = await repo.search(q: q, page: 1);
        return res.fold((_) => [], (p) => p.data);
      }, itemTitle: (p) => p.razonSocial, itemSubtitle: (p) => p.rucDni ?? p.codigo);
    if (r != null) setState(() { _proveedor = r.codigo; _proveedorNombre = r.razonSocial; });
  }

  Future<void> _addLinea() async {
    final art = await MaestroPicker.show<Articulo>(context,
      title: 'Artículo', onSearch: (q) async {
        final res = await getIt<ArticuloRepository>().search(q: q, page: 1);
        return res.fold((_) => [], (p) => p.data);
      }, itemTitle: (a) => a.descripcion, itemSubtitle: (a) => a.codigo);
    if (art == null || !mounted) return;

    final qCtrl = TextEditingController(text: '1');
    final pCtrl = TextEditingController(text: art.precioCompra.toStringAsFixed(4) ?? '0.0000');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(art.descripcion),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: qCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad')),
        const SizedBox(height: 8),
        TextFormField(controller: pCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio unitario')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Agregar')),
      ],
    ));
    if (ok == true) {
      setState(() => _lineas.add(_LineaEntry(
      codigo: art.codigo, descripcion: art.descripcion,
      cantidad: double.tryParse(qCtrl.text) ?? 1,
      precio: double.tryParse(pCtrl.text) ?? 0,
    )));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_documento == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione un documento')));
      return;
    }
    if (_almacen == null || _proveedor == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione almacén y proveedor')));
      return;
    }
    if (_lineas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agregue artículos')));
      return;
    }
    context.read<CompraBloc>().add(CompraRegistrar({
      'codigoDocumento': _documento!.codigo,
      'serie': _documento!.serie,
      'fecha': _fecha,
      'formaPago': _forma.name,
      if (_forma == FormaPago.CREDITO) 'plazoDias': _plazo,
      if (_obsCtrl.text.trim().isNotEmpty) 'observacion': _obsCtrl.text.trim(),
      'codigoAlmacen': _almacen,
      'codigoProveedor': _proveedor,
      'moneda': _moneda,
      'tipoCambio': double.tryParse(_tcCtrl.text) ?? 1,
      'lineas': _lineas.map((l) => {
        'codigoArticulo': l.codigo,
        'cantidad': l.cantidad,
        'precioUnitario': l.precio,
      }).toList(),
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Compra')),
      body: BlocConsumer<CompraBloc, CompraState>(
        listener: (ctx, state) {
          if (state is CompraSaved) {
            final nro = '${state.compra.codigoDocumento}-${state.compra.serie}-${state.compra.numeroDocumento}';
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Compra registrada · $nro'), backgroundColor: Colors.green));
            ctx.pop();
          }
          if (state is CompraError) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        },
        builder: (ctx, state) {
          final saving = state is CompraSaving;
          return Stack(children: [
            Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
              // Documento
              DropdownButtonFormField<Documento>(
                value: _documento,
                decoration: const InputDecoration(labelText: 'Documento *', border: OutlineInputBorder(), isDense: true),
                items: _documentos.map((d) => DropdownMenuItem(
                  value: d,
                  child: Text('${d.codigo} · ${d.descripcion}  [${d.serie}]', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (d) => setState(() => _documento = d),
                validator: (v) => v == null ? 'Seleccione un documento' : null,
              ),
              const SizedBox(height: 12),
              // Fecha
              ListTile(contentPadding: EdgeInsets.zero, title: Text('Fecha: $_fecha'), trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.parse(_fecha), firstDate: DateTime(2000), lastDate: DateTime.now());
                  if (d != null) setState(() => _fecha = d.toIso8601String().substring(0, 10));
                }),
              const Divider(),
              // Forma de pago
              Row(children: [
                const Text('Forma pago:'),
                const SizedBox(width: 12),
                ChoiceChip(label: const Text('Contado'), selected: _forma == FormaPago.CONTADO, onSelected: (_) => setState(() => _forma = FormaPago.CONTADO)),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Crédito'), selected: _forma == FormaPago.CREDITO, onSelected: (_) => setState(() => _forma = FormaPago.CREDITO)),
                if (_forma == FormaPago.CREDITO) ...[
                  const SizedBox(width: 12),
                  SizedBox(width: 60, child: TextFormField(initialValue: _plazo.toString(), decoration: const InputDecoration(labelText: 'Días'), keyboardType: TextInputType.number, onChanged: (v) => _plazo = int.tryParse(v) ?? 30)),
                ],
              ]),
              const SizedBox(height: 12),
              // Moneda y TC
              Row(children: [
                ChoiceChip(label: const Text('PEN'), selected: _moneda == 'PEN', onSelected: (_) => setState(() => _moneda = 'PEN')),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('USD'), selected: _moneda == 'USD', onSelected: (_) => setState(() => _moneda = 'USD')),
                const SizedBox(width: 12),
                SizedBox(width: 90, child: TextFormField(controller: _tcCtrl, decoration: const InputDecoration(labelText: 'T.C.'), keyboardType: TextInputType.number)),
              ]),
              const Divider(),
              // Almacén y proveedor
              ListTile(contentPadding: EdgeInsets.zero, title: Text(_almacenNombre ?? 'Seleccionar almacén'), trailing: const Icon(Icons.warehouse), onTap: _pickAlmacen),
              ListTile(contentPadding: EdgeInsets.zero, title: Text(_proveedorNombre ?? 'Seleccionar proveedor'), trailing: const Icon(Icons.business), onTap: _pickProveedor),
              TextFormField(controller: _obsCtrl, decoration: const InputDecoration(labelText: 'Observación (opcional)')),
              const Divider(),
              // Líneas
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Artículos', style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(onPressed: _addLinea, icon: const Icon(Icons.add), label: const Text('Agregar')),
              ]),
              ..._lineas.asMap().entries.map((e) => ListTile(
                dense: true,
                title: Text(e.value.descripcion),
                subtitle: Text('${e.value.cantidad} × ${e.value.precio.toStringAsFixed(4)} = S/ ${e.value.importe.toStringAsFixed(2)}'),
                trailing: IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _lineas.removeAt(e.key))),
              )),
              const Divider(),
              // Totales
              _TotalesRow('Subtotal', _subtotal),
              _TotalesRow('IGV (18%)', _igv),
              _TotalesRow('Total', _total, bold: true),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: saving ? null : _submit, child: const Text('Registrar Compra')),
              const SizedBox(height: 40),
            ])),
            if (saving) const Positioned.fill(child: ColoredBox(color: Colors.black26, child: Center(child: CircularProgressIndicator()))),
          ]);
        },
      ),
    );
  }
}

class _TotalesRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;
  const _TotalesRow(this.label, this.value, {this.bold = false});
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
