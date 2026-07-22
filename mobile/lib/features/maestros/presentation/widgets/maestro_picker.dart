import 'package:flutter/material.dart';

/// Widget de búsqueda reutilizable para seleccionar cualquier maestro
/// (artículo, cliente, proveedor, almacén) en formularios de procesos.
///
/// Uso:
///   final articulo = await MaestroPicker.show<Articulo>(
///     context,
///     title: 'Seleccionar Artículo',
///     onSearch: (q) async { ... },
///     itemTitle: (a) => a.descripcion,
///     itemSubtitle: (a) => 'S/. ${a.precioVenta.toStringAsFixed(2)}',
///   );
class MaestroPicker<T> extends StatefulWidget {
  final String title;
  final Future<List<T>> Function(String query) onSearch;
  final String Function(T item) itemTitle;
  final String Function(T item)? itemSubtitle;
  final bool Function(T item)? isActive;

  const MaestroPicker({
    super.key,
    required this.title,
    required this.onSearch,
    required this.itemTitle,
    this.itemSubtitle,
    this.isActive,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Future<List<T>> Function(String query) onSearch,
    required String Function(T item) itemTitle,
    String Function(T item)? itemSubtitle,
    bool Function(T item)? isActive,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MaestroPicker<T>(
        title: title,
        onSearch: onSearch,
        itemTitle: itemTitle,
        itemSubtitle: itemSubtitle,
        isActive: isActive,
      ),
    );
  }

  @override
  State<MaestroPicker<T>> createState() => _MaestroPickerState<T>();
}

class _MaestroPickerState<T> extends State<MaestroPicker<T>> {
  final _controller = TextEditingController();
  List<T> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search('');
    _controller.addListener(() => _search(_controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final results = await widget.onSearch(q);
      if (mounted) setState(() { _results = results; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) => Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _controller.clear())
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _results.isEmpty && !_loading
                ? Center(
                    child: Text(
                      'Sin resultados',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final item = _results[i];
                      final inactive = widget.isActive != null && !widget.isActive!(item);
                      return ListTile(
                        title: Text(
                          widget.itemTitle(item),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: inactive ? cs.onSurface.withValues(alpha: 0.4) : null,
                          ),
                        ),
                        subtitle: (widget.itemSubtitle?.call(item) ?? '').isNotEmpty
                            ? Text(widget.itemSubtitle!(item))
                            : null,
                        trailing: inactive
                            ? const Chip(
                                label: Text('Inactivo'),
                                labelStyle: TextStyle(fontSize: 10),
                                padding: EdgeInsets.zero,
                              )
                            : null,
                        onTap: inactive ? null : () => Navigator.of(context).pop(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
