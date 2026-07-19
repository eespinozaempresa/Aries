import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/export_service.dart';
import '../../../maestros/domain/repositories/almacen_repository.dart' as maestro_alm;
import '../../../maestros/domain/entities/almacen.dart' as maestro_alm_ent;
import '../../../maestros/presentation/widgets/maestro_picker.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/movimiento_repository.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  String? _almacen;
  String? _almacenNombre;
  final _qCtrl = TextEditingController();
  bool _soloConStock = true;

  List<StockItem>? _items;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAlmacen() async {
    final repo = getIt<maestro_alm.AlmacenRepository>();
    final result = await MaestroPicker.show<maestro_alm_ent.Almacen>(
      context,
      title: 'Filtrar por almacén',
      onSearch: (q) async {
        final res = await repo.findAll();
        return res.fold((_) => [], (l) => l.where((a) =>
          a.descripcion.toLowerCase().contains(q.toLowerCase()) ||
          a.codigo.toLowerCase().contains(q.toLowerCase())).toList());
      },
      itemTitle: (a) => a.descripcion,
      itemSubtitle: (a) => a.codigo,
    );
    if (result != null) {
      setState(() { _almacen = result.codigo; _almacenNombre = result.descripcion; });
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final repo = getIt<MovimientoRepository>();
    final result = await repo.getStock(
      codigoAlmacen: _almacen,
      q: _qCtrl.text.trim().isEmpty ? null : _qCtrl.text.trim(),
      soloConStock: _soloConStock,
    );
    result.fold(
      (e) => setState(() { _error = e.message; _loading = false; }),
      (list) => setState(() { _items = list; _loading = false; }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
        actions: [
          if (_items != null && _items!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Exportar',
              onPressed: () => ExportService.showExportDialog(
                context: context,
                title: 'Stock',
                columns: const ['Artículo', 'Almacén', 'Stock', 'Costo Prom.'],
                rows: _items!.map((s) => [
                  s.descripcionArticulo ?? s.codigoArticulo,
                  s.descripcionAlmacen ?? s.codigoAlmacen,
                  s.stockActual.toStringAsFixed(2),
                  s.costoPromedio.toStringAsFixed(4),
                ]).toList(),
                subtitle: _almacenNombre != null ? 'Almacén: $_almacenNombre' : null,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.warehouse, size: 18),
                    label: Text(_almacenNombre ?? 'Todos los almacenes', overflow: TextOverflow.ellipsis),
                    onPressed: _pickAlmacen,
                  ),
                ),
                const SizedBox(width: 8),
                if (_almacen != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Quitar filtro almacén',
                    onPressed: () => setState(() { _almacen = null; _almacenNombre = null; }),
                  ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _qCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Buscar artículo...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _load, child: const Text('Buscar')),
              ]),
              Row(children: [
                Checkbox(
                  value: _soloConStock,
                  onChanged: (v) => setState(() => _soloConStock = v ?? true),
                ),
                const Text('Solo con stock'),
              ]),
            ]),
          ),
          const Divider(height: 0),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_error != null) Expanded(child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))),
          if (_items != null && !_loading)
            Expanded(
              child: _items!.isEmpty
                  ? const Center(child: Text('Sin resultados'))
                  : ListView.builder(
                      itemCount: _items!.length,
                      itemBuilder: (ctx, i) {
                        final s = _items![i];
                        return ListTile(
                          dense: true,
                          title: Text(s.descripcionArticulo ?? s.codigoArticulo),
                          subtitle: Text('Almacén: ${s.descripcionAlmacen ?? s.codigoAlmacen}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(s.stockActual.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: s.stockActual > 0 ? null : Colors.red,
                                  )),
                              Text('Costo: ${s.costoPromedio.toStringAsFixed(4)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
