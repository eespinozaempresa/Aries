import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/export_service.dart';
import '../../../maestros/domain/repositories/articulo_repository.dart';
import '../../../maestros/domain/repositories/almacen_repository.dart' as maestro_alm;
import '../../../maestros/domain/entities/articulo.dart';
import '../../../maestros/domain/entities/almacen.dart' as maestro_alm_ent;
import '../../../maestros/presentation/widgets/maestro_picker.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/movimiento_repository.dart';
import '../../../../core/widgets/aries_app_bar.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  List<maestro_alm_ent.Almacen> _almacenes = [];
  List<Articulo> _articulos = [];
  bool _soloConStock = true;

  List<StockItem>? _items;
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
    final result = await repo.getStock(
      codigosAlmacen: _almacenes.map((a) => a.codigo).toList(),
      codigosArticulo: _articulos.map((a) => a.codigo).toList(),
      soloConStock: _soloConStock,
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
        title: const Text('Stock'),
        actions: [
          if (_items != null && _items!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Exportar',
              onPressed: () => ExportService.showExportDialog(
                context: context,
                title: 'Stock${_articulos.length == 1 ? " — ${_articulos.first.descripcion}" : ""}',
                columns: [
                  if (showAlmacenCol) 'Almacén',
                  if (showArticuloCol) 'Artículo',
                  'Stock', 'Costo Prom.',
                ],
                rows: _items!.map((s) => [
                  if (showAlmacenCol) s.descripcionAlmacen ?? s.codigoAlmacen,
                  if (showArticuloCol) s.descripcionArticulo ?? s.codigoArticulo,
                  s.stockActual.toStringAsFixed(2),
                  s.costoPromedio.toStringAsFixed(4),
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
                // Fila artículo + botón Ver
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
                // Fila solo con stock
                Row(children: [
                  Checkbox(
                    value: _soloConStock,
                    onChanged: (v) => setState(() => _soloConStock = v ?? true),
                  ),
                  const Text('Solo con stock'),
                ]),
              ],
            ),
          ),
          const Divider(height: 0),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_error != null) Expanded(child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))),
          if (_items != null && !_loading)
            Expanded(child: _StockTable(
              items: _items!,
              showAlmacenCol: showAlmacenCol,
              showArticuloCol: showArticuloCol,
            )),
        ],
      ),
    );
  }
}

class _StockTable extends StatelessWidget {
  final List<StockItem> items;
  final bool showAlmacenCol;
  final bool showArticuloCol;
  const _StockTable({
    required this.items,
    required this.showAlmacenCol,
    required this.showArticuloCol,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Sin resultados'));
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
            const DataColumn(label: Text('Stock'), numeric: true),
            const DataColumn(label: Text('Costo Prom.'), numeric: true),
          ],
          rows: items.map((s) => DataRow(cells: [
            if (showAlmacenCol) DataCell(Text(s.descripcionAlmacen ?? s.codigoAlmacen, style: const TextStyle(fontSize: 11))),
            if (showArticuloCol) DataCell(Text(s.descripcionArticulo ?? s.codigoArticulo, style: const TextStyle(fontSize: 11))),
            DataCell(Text(
              s.stockActual.toStringAsFixed(2),
              style: TextStyle(color: s.stockActual > 0 ? null : Colors.red, fontWeight: FontWeight.bold),
            )),
            DataCell(Text(s.costoPromedio.toStringAsFixed(4))),
          ])).toList(),
        ),
      ),
    );
  }
}
