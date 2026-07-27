import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/export_service.dart';
import '../../../maestros/domain/repositories/articulo_repository.dart';
import '../../../maestros/domain/repositories/almacen_repository.dart' as maestro_alm;
import '../../../maestros/domain/entities/articulo.dart';
import '../../../maestros/domain/entities/almacen.dart' as maestro_alm_ent;
import '../../../maestros/presentation/widgets/maestro_picker.dart';
import '../../domain/entities/kardex_item.dart';
import '../../domain/repositories/movimiento_repository.dart';
import '../../../../core/widgets/aries_app_bar.dart';

class KardexPage extends StatefulWidget {
  const KardexPage({super.key});

  @override
  State<KardexPage> createState() => _KardexPageState();
}

class _KardexPageState extends State<KardexPage> {
  List<maestro_alm_ent.Almacen> _almacenes = [];
  List<Articulo> _articulos = [];
  List<KardexItem>? _items;
  bool _loading = false;
  String? _error;

  Future<void> _pickAlmacen() async {
    final repo = getIt<maestro_alm.AlmacenRepository>();
    final result = await MaestroPicker.showMulti<maestro_alm_ent.Almacen>(
      context,
      title: 'Almacenes',
      onSearch: (q) async {
        final res = await repo.findAll();
        return res.fold((_) => [], (l) => l.where((a) =>
          a.descripcion.toLowerCase().contains(q.toLowerCase()) ||
          a.codigo.toLowerCase().contains(q.toLowerCase())).toList());
      },
      itemTitle: (a) => a.descripcion,
      itemId: (a) => a.codigo,
      initialSelected: _almacenes,
    );
    if (result != null) {
      setState(() => _almacenes = result);
    }
  }

  Future<void> _pickArticulo() async {
    final repo = getIt<ArticuloRepository>();
    final result = await MaestroPicker.showMulti<Articulo>(
      context,
      title: 'Artículos',
      onSearch: (q) async {
        final res = await repo.search(q: q, page: 1);
        return res.fold((_) => [], (page) => page.data);
      },
      itemTitle: (a) => a.descripcion,
      itemId: (a) => a.codigo,
      initialSelected: _articulos,
    );
    if (result != null) {
      setState(() => _articulos = result);
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final repo = getIt<MovimientoRepository>();
    final result = await repo.getKardex(
      codigosAlmacen: _almacenes.map((a) => a.codigo).toList(),
      codigosArticulo: _articulos.map((a) => a.codigo).toList(),
    );
    result.fold(
      (e) => setState(() { _error = e.message; _loading = false; }),
      (list) => setState(() { _items = list; _loading = false; }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAlmacenCol = _almacenes.isEmpty;
    final showArticuloCol = _articulos.isEmpty;
    final almacenLabel = _almacenes.isEmpty
        ? 'Todos los almacenes'
        : _almacenes.length == 1
            ? _almacenes.first.descripcion
            : '${_almacenes.length} almacenes seleccionados';
    final articuloLabel = _articulos.isEmpty
        ? 'Todos los artículos'
        : _articulos.length == 1
            ? _articulos.first.descripcion
            : '${_articulos.length} artículos seleccionados';

    return Scaffold(
      appBar: AriesAppBar(
        title: const Text('Kardex'),
        actions: [
          if (_items != null && _items!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Exportar',
              onPressed: () => ExportService.showExportDialog(
                context: context,
                title: 'Kardex${_articulos.length == 1 ? " — ${_articulos.first.descripcion}" : ""}',
                columns: [
                  if (showAlmacenCol) 'Almacén',
                  if (showArticuloCol) 'Artículo',
                  'Fecha', 'Doc', 'Tipo',
                  'E.Cant', 'E.Precio', 'S.Cant', 'S.Precio', 'Stock', 'Costo',
                ],
                rows: _items!.map((k) => [
                  if (showAlmacenCol) k.descripcionAlmacen ?? k.codigoAlmacen,
                  if (showArticuloCol) k.descripcionArticulo ?? k.codigoArticulo,
                  ExportService.fmtDate(k.fecha),
                  '${k.abreviaturaDocumento ?? k.codigoDocumento}-${k.serie}-${k.numeroDocumento}',
                  k.tipo,
                  k.cantEntrada > 0 ? k.cantEntrada.toStringAsFixed(2) : '-',
                  k.cantEntrada > 0 ? k.precioEntrada.toStringAsFixed(4) : '-',
                  k.cantSalida > 0 ? k.cantSalida.toStringAsFixed(2) : '-',
                  k.cantSalida > 0 ? k.precioSalida.toStringAsFixed(4) : '-',
                  k.stock.toStringAsFixed(2),
                  k.precioStock.toStringAsFixed(4),
                ]).toList(),
                subtitle: _almacenes.length == 1 ? 'Almacén: ${_almacenes.first.descripcion}' : null,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fila almacén
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.warehouse, size: 18),
                      label: Text(
                        almacenLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _almacenes.isEmpty ? Colors.grey : null),
                      ),
                      onPressed: _pickAlmacen,
                    ),
                  ),
                  if (_almacenes.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Todos los almacenes',
                      onPressed: () => setState(() => _almacenes = []),
                    ),
                  ],
                ]),
                const SizedBox(height: 6),
                // Fila artículo
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.inventory_2, size: 18),
                      label: Text(
                        articuloLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _articulos.isEmpty ? Colors.grey : null),
                      ),
                      onPressed: _pickArticulo,
                    ),
                  ),
                  if (_articulos.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Todos los artículos',
                      onPressed: () => setState(() => _articulos = []),
                    ),
                  ],
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _load, child: const Text('Ver')),
                ]),
              ],
            ),
          ),
          const Divider(height: 0),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_error != null) Expanded(child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))),
          if (_items != null && !_loading)
            Expanded(child: _KardexTable(
              items: _items!,
              showAlmacenCol: showAlmacenCol,
              showArticuloCol: showArticuloCol,
            )),
        ],
      ),
    );
  }
}

class _KardexTable extends StatelessWidget {
  final List<KardexItem> items;
  final bool showAlmacenCol;
  final bool showArticuloCol;
  const _KardexTable({
    required this.items,
    required this.showAlmacenCol,
    required this.showArticuloCol,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Sin movimientos'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 12,
          headingRowHeight: 36,
          dataRowMinHeight: 28,
          dataRowMaxHeight: 36,
          columns: [
            if (showAlmacenCol) const DataColumn(label: Text('Almacén')),
            if (showArticuloCol) const DataColumn(label: Text('Artículo')),
            const DataColumn(label: Text('Fecha')),
            const DataColumn(label: Text('Doc')),
            const DataColumn(label: Text('Tipo')),
            const DataColumn(label: Text('E.Cant'), numeric: true),
            const DataColumn(label: Text('E.Precio'), numeric: true),
            const DataColumn(label: Text('S.Cant'), numeric: true),
            const DataColumn(label: Text('S.Precio'), numeric: true),
            const DataColumn(label: Text('Stock'), numeric: true),
            const DataColumn(label: Text('Costo'), numeric: true),
          ],
          rows: items.map((k) => DataRow(cells: [
            if (showAlmacenCol) DataCell(Text(k.descripcionAlmacen ?? k.codigoAlmacen, style: const TextStyle(fontSize: 11))),
            if (showArticuloCol) DataCell(Text(k.descripcionArticulo ?? k.codigoArticulo, style: const TextStyle(fontSize: 11))),
            DataCell(Text(k.fecha.substring(0, 10))),
            DataCell(Text('${k.abreviaturaDocumento ?? k.codigoDocumento}-${k.serie}-${k.numeroDocumento}', style: const TextStyle(fontSize: 11))),
            DataCell(Text(k.tipo)),
            DataCell(Text(k.cantEntrada > 0 ? k.cantEntrada.toStringAsFixed(2) : '-')),
            DataCell(Text(k.cantEntrada > 0 ? k.precioEntrada.toStringAsFixed(4) : '-')),
            DataCell(Text(k.cantSalida > 0 ? k.cantSalida.toStringAsFixed(2) : '-')),
            DataCell(Text(k.cantSalida > 0 ? k.precioSalida.toStringAsFixed(4) : '-')),
            DataCell(Text(k.stock.toStringAsFixed(2))),
            DataCell(Text(k.precioStock.toStringAsFixed(4))),
          ])).toList(),
        ),
      ),
    );
  }
}
