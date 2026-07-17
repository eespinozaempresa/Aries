import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../maestros/domain/repositories/articulo_repository.dart';
import '../../../maestros/domain/repositories/almacen_repository.dart' as maestro_alm;
import '../../../maestros/domain/entities/articulo.dart';
import '../../../maestros/domain/entities/almacen.dart' as maestro_alm_ent;
import '../../../maestros/presentation/widgets/maestro_picker.dart';
import '../../../tablas/data/datasources/tablas_remote_datasource.dart';
import '../../../tablas/data/models/tabla_model.dart';
import '../../../tablas/domain/entities/tabla_base.dart';
import '../../domain/entities/movimiento.dart';
import '../../domain/repositories/movimiento_repository.dart';
import '../bloc/movimiento_bloc.dart';
import '../bloc/movimiento_event.dart';
import '../bloc/movimiento_state.dart';

class MovimientoFormPage extends StatelessWidget {
  const MovimientoFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MovimientoBloc(getIt<MovimientoRepository>()),
      child: const _MovimientoForm(),
    );
  }
}

class _LineaEntry {
  String codigoArticulo;
  String descripcionArticulo;
  double cantidad;
  double precioUnitario;

  _LineaEntry({
    required this.codigoArticulo,
    required this.descripcionArticulo,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get importe => cantidad * precioUnitario;
  Map<String, dynamic> toMap() => {
    'codigoArticulo': codigoArticulo,
    'cantidad': cantidad,
    'precioUnitario': precioUnitario,
  };
}

class _MovimientoForm extends StatefulWidget {
  const _MovimientoForm();

  @override
  State<_MovimientoForm> createState() => _MovimientoFormState();
}

class _MovimientoFormState extends State<_MovimientoForm> {
  final _formKey = GlobalKey<FormState>();

  TipoMovimiento _tipo = TipoMovimiento.INGRESO;
  List<Documento> _documentos = [];
  Documento? _documento;
  String _fecha = DateTime.now().toIso8601String().substring(0, 10);
  String? _almacenOrigen;
  String? _almacenOrigenNombre;
  String? _almacenDest;
  String? _almacenDestNombre;
  final _obsCtrl = TextEditingController();

  final List<_LineaEntry> _lineas = [];

  bool get _needsDest => _tipo == TipoMovimiento.TRASLADO;

  @override
  void initState() {
    super.initState();
    _loadDocumentos();
  }

  Future<void> _loadDocumentos() async {
    try {
      final ds = getIt<TablasRemoteDataSource>();
      final raw = await ds.list('documentos', activo: true, tipo: 'ALMACEN');
      if (mounted) {
        setState(() {
          _documentos = raw.map(TablaModel.documentoFromJson).toList();
          if (_documentos.length == 1) _documento = _documentos.first;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAlmacen({required bool isDest}) async {
    final repo = getIt<maestro_alm.AlmacenRepository>();
    final result = await MaestroPicker.show<maestro_alm_ent.Almacen>(
      context,
      title: isDest ? 'Almacén destino' : 'Almacén origen',
      onSearch: (q) async {
        final res = await repo.findAll();
        return res.fold((_) => [], (list) => list.where((a) =>
          a.descripcion.toLowerCase().contains(q.toLowerCase()) ||
          a.codigo.toLowerCase().contains(q.toLowerCase())).toList());
      },
      itemTitle: (a) => a.descripcion,
      itemSubtitle: (a) => a.codigo,
    );
    if (result != null) {
      setState(() {
        if (isDest) {
          _almacenDest = result.codigo;
          _almacenDestNombre = result.descripcion;
        } else {
          _almacenOrigen = result.codigo;
          _almacenOrigenNombre = result.descripcion;
        }
      });
    }
  }

  Future<void> _addLinea() async {
    final repo = getIt<ArticuloRepository>();
    final art = await MaestroPicker.show<Articulo>(
      context,
      title: 'Seleccionar artículo',
      onSearch: (q) async {
        final res = await repo.search(q: q, page: 1);
        return res.fold((_) => [], (page) => page.data);
      },
      itemTitle: (a) => a.descripcion,
      itemSubtitle: (a) => a.codigo,
    );
    if (art == null || !mounted) return;

    // Pedir cantidad y precio
    final qtyCtrl   = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: art.precioVenta.toStringAsFixed(4) ?? '0.0000');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(art.descripcion),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: qtyCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad')),
          const SizedBox(height: 8),
          TextFormField(controller: priceCtrl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio unitario')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Agregar')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _lineas.add(_LineaEntry(
          codigoArticulo: art.codigo,
          descripcionArticulo: art.descripcion,
          cantidad: double.tryParse(qtyCtrl.text) ?? 1,
          precioUnitario: double.tryParse(priceCtrl.text) ?? 0,
        ));
      });
    }
  }

  double get _total => _lineas.fold(0, (s, l) => s + l.importe);

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_documento == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione un documento')));
      return;
    }
    if (_almacenOrigen == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione almacén origen')));
      return;
    }
    if (_needsDest && _almacenDest == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione almacén destino')));
      return;
    }
    if (_lineas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agregue al menos un artículo')));
      return;
    }

    context.read<MovimientoBloc>().add(MovimientoRegistrar(
      codigoDocumento: _documento!.codigo,
      serie: _documento!.serie,
      fecha: _fecha,
      tipo: _tipo,
      codigoAlmacenOrigen: _almacenOrigen!,
      codigoAlmacenDest: _needsDest ? _almacenDest : null,
      observacion: _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      lineas: _lineas.map((l) => l.toMap()).toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Movimiento')),
      body: BlocConsumer<MovimientoBloc, MovimientoState>(
        listener: (ctx, state) {
          if (state is MovimientoSaved) {
            final nro = '${state.movimiento.codigoDocumento}-${state.movimiento.serie}-${state.movimiento.numeroDocumento}';
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('Movimiento registrado · $nro'), backgroundColor: Colors.green),
            );
            ctx.pop();
          }
          if (state is MovimientoError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (ctx, state) {
          final saving = state is MovimientoSaving;
          return Stack(children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tipo
                  SegmentedButton<TipoMovimiento>(
                    segments: const [
                      ButtonSegment(value: TipoMovimiento.INGRESO,  label: Text('Ingreso')),
                      ButtonSegment(value: TipoMovimiento.SALIDA,   label: Text('Salida')),
                      ButtonSegment(value: TipoMovimiento.TRASLADO, label: Text('Traslado')),
                    ],
                    selected: {_tipo},
                    onSelectionChanged: (s) => setState(() => _tipo = s.first),
                  ),
                  const SizedBox(height: 16),

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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Fecha: $_fecha'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.parse(_fecha),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _fecha = d.toIso8601String().substring(0, 10));
                    },
                  ),
                  const Divider(),

                  // Almacén origen
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_almacenOrigenNombre ?? 'Seleccionar almacén origen'),
                    subtitle: _almacenOrigen != null ? Text(_almacenOrigen!) : null,
                    trailing: const Icon(Icons.warehouse),
                    onTap: () => _pickAlmacen(isDest: false),
                  ),

                  // Almacén destino (solo traslado)
                  if (_needsDest)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_almacenDestNombre ?? 'Seleccionar almacén destino'),
                      subtitle: _almacenDest != null ? Text(_almacenDest!) : null,
                      trailing: const Icon(Icons.warehouse_outlined),
                      onTap: () => _pickAlmacen(isDest: true),
                    ),

                  const Divider(),

                  // Observación
                  TextFormField(
                    controller: _obsCtrl,
                    decoration: const InputDecoration(labelText: 'Observación (opcional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Líneas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Artículos', style: Theme.of(context).textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: _addLinea,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  ..._lineas.asMap().entries.map((e) {
                    final i = e.key;
                    final l = e.value;
                    return ListTile(
                      dense: true,
                      title: Text(l.descripcionArticulo),
                      subtitle: Text('${l.cantidad} × ${l.precioUnitario.toStringAsFixed(4)} = S/ ${l.importe.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => setState(() => _lineas.removeAt(i)),
                      ),
                    );
                  }),

                  const Divider(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('Total: S/ ${_total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: saving ? null : _submit,
                    child: const Text('Registrar'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            if (saving)
              const Positioned.fill(
                child: ColoredBox(color: Colors.black26, child: Center(child: CircularProgressIndicator())),
              ),
          ]);
        },
      ),
    );
  }
}
