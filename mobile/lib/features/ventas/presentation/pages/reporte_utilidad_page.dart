import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/export_service.dart';
import '../../data/datasources/ventas_remote_datasource.dart';
import '../../../../core/widgets/aries_app_bar.dart';

class ReporteUtilidadPage extends StatefulWidget {
  const ReporteUtilidadPage({super.key});
  @override
  State<ReporteUtilidadPage> createState() => _State();
}

class _State extends State<ReporteUtilidadPage> {
  String? _desde, _hasta;
  List<Map<String, dynamic>>? _items;
  bool _loading = false;
  String? _error;

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await getIt<VentasRemoteDataSource>()
          .reporteUtilidad(desde: _desde, hasta: _hasta);
      setState(() { _items = list.cast<Map<String, dynamic>>(); _loading = false; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  Future<void> _pickFecha(bool isDesde) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() {
      final s = d.toIso8601String().substring(0, 10);
      if (isDesde) {
        _desde = s;
      } else {
        _hasta = s;
      }
    });
    }
  }

  double get _totalUtilidad => (_items ?? []).fold(0.0, (s, i) => s + ((i['utilidadTotal'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AriesAppBar(
        title: const Text('Reporte Utilidad'),
        actions: [
          if (_items != null && _items!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Exportar',
              onPressed: () => ExportService.showExportDialog(
                context: context,
                title: 'Reporte Utilidad',
                columns: const ['Artículo', 'Descripción', 'Cant.', 'P.Venta', 'Costo', 'Util/u', 'Utilidad', 'Margen%'],
                rows: _items!.map((i) => <String>[
                  '${i['codigoArticulo'] ?? ''}',
                  '${i['descripcion'] ?? ''}',
                  (i['cantidadVendida'] as num).toStringAsFixed(2),
                  (i['precioPromVenta'] as num).toStringAsFixed(4),
                  (i['costoPromedio'] as num).toStringAsFixed(4),
                  (i['utilidadUnit'] as num).toStringAsFixed(4),
                  (i['utilidadTotal'] as num).toStringAsFixed(2),
                  '${(i['margenPct'] as num).toStringAsFixed(1)}%',
                ]).toList(),
                subtitle: _desde != null && _hasta != null ? 'Período: $_desde a $_hasta' : null,
              ),
            ),
        ],
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => _pickFecha(true),
            child: Text(_desde != null ? 'Desde: $_desde' : 'Fecha inicio'),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(
            onPressed: () => _pickFecha(false),
            child: Text(_hasta != null ? 'Hasta: $_hasta' : 'Fecha fin'),
          )),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _load, child: const Text('Ver')),
        ])),
        const Divider(height: 0),
        if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
        if (_error != null) Expanded(child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))),
        if (_items != null && !_loading) ...[
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${_items!.length} artículos', style: const TextStyle(color: Colors.grey)),
            Text('Utilidad total: S/ ${_totalUtilidad.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ])),
          Expanded(child: _items!.isEmpty
            ? const Center(child: Text('Sin datos'))
            : SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
                columnSpacing: 12,
                headingRowHeight: 36,
                dataRowMinHeight: 28,
                dataRowMaxHeight: 36,
                columns: const [
                  DataColumn(label: Text('Artículo')),
                  DataColumn(label: Text('Descripción')),
                  DataColumn(label: Text('Cant.'), numeric: true),
                  DataColumn(label: Text('P.Venta'), numeric: true),
                  DataColumn(label: Text('Costo'), numeric: true),
                  DataColumn(label: Text('Util/u'), numeric: true),
                  DataColumn(label: Text('Utilidad'), numeric: true),
                  DataColumn(label: Text('Margen%'), numeric: true),
                ],
                rows: _items!.map((item) {
                  final util = (item['utilidadTotal'] as num).toDouble();
                  return DataRow(cells: [
                    DataCell(Text(item['codigoArticulo'] as String? ?? '')),
                    DataCell(SizedBox(width: 140, child: Text(item['descripcion'] as String? ?? '', overflow: TextOverflow.ellipsis))),
                    DataCell(Text((item['cantidadVendida'] as num).toStringAsFixed(2))),
                    DataCell(Text((item['precioPromVenta'] as num).toStringAsFixed(4))),
                    DataCell(Text((item['costoPromedio'] as num).toStringAsFixed(4))),
                    DataCell(Text((item['utilidadUnit'] as num).toStringAsFixed(4), style: TextStyle(color: util >= 0 ? Colors.green : Colors.red))),
                    DataCell(Text(util.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold, color: util >= 0 ? Colors.green : Colors.red))),
                    DataCell(Text('${(item['margenPct'] as num).toStringAsFixed(1)}%')),
                  ]);
                }).toList(),
              )),
          ),
        ],
      ]),
    );
  }
}
