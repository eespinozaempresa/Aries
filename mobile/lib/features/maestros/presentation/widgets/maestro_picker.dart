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

  /// Variante de selección múltiple: permite marcar varios elementos con
  /// casillas de verificación y confirmarlos con "Aplicar". Retorna `null`
  /// si el usuario cierra el bottom sheet sin confirmar.
  static Future<List<T>?> showMulti<T>(
    BuildContext context, {
    required String title,
    required Future<List<T>> Function(String query) onSearch,
    required String Function(T item) itemTitle,
    required String Function(T item) itemId,
    String Function(T item)? itemSubtitle,
    bool Function(T item)? isActive,
    List<T> initialSelected = const [],
  }) {
    return showModalBottomSheet<List<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MaestroMultiPicker<T>(
        title: title,
        onSearch: onSearch,
        itemTitle: itemTitle,
        itemId: itemId,
        itemSubtitle: itemSubtitle,
        isActive: isActive,
        initialSelected: initialSelected,
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
      results.sort((a, b) =>
          widget.itemTitle(a).toLowerCase().compareTo(widget.itemTitle(b).toLowerCase()));
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

/// Variante interna de [MaestroPicker] con casillas de selección múltiple.
class _MaestroMultiPicker<T> extends StatefulWidget {
  final String title;
  final Future<List<T>> Function(String query) onSearch;
  final String Function(T item) itemTitle;
  final String Function(T item) itemId;
  final String Function(T item)? itemSubtitle;
  final bool Function(T item)? isActive;
  final List<T> initialSelected;

  const _MaestroMultiPicker({
    super.key,
    required this.title,
    required this.onSearch,
    required this.itemTitle,
    required this.itemId,
    this.itemSubtitle,
    this.isActive,
    this.initialSelected = const [],
  });

  @override
  State<_MaestroMultiPicker<T>> createState() => _MaestroMultiPickerState<T>();
}

class _MaestroMultiPickerState<T> extends State<_MaestroMultiPicker<T>> {
  final _controller = TextEditingController();
  List<T> _results = [];
  bool _loading = false;
  late final Map<String, T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {for (final item in widget.initialSelected) widget.itemId(item): item};
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
      results.sort((a, b) =>
          widget.itemTitle(a).toLowerCase().compareTo(widget.itemTitle(b).toLowerCase()));
      if (mounted) setState(() { _results = results; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggle(T item, bool? value) {
    final id = widget.itemId(item);
    setState(() {
      if (value ?? false) {
        _selected[id] = item;
      } else {
        _selected.remove(id);
      }
    });
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: _results.isEmpty
                      ? null
                      : () => setState(() {
                            for (final item in _results) {
                              final inactive = widget.isActive != null && !widget.isActive!(item);
                              if (!inactive) _selected[widget.itemId(item)] = item;
                            }
                          }),
                  child: const Text('Todos'),
                ),
                TextButton(
                  onPressed: _selected.isEmpty ? null : () => setState(() => _selected.clear()),
                  child: const Text('Ninguno'),
                ),
              ],
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
                      final id = widget.itemId(item);
                      final inactive = widget.isActive != null && !widget.isActive!(item);
                      return CheckboxListTile(
                        value: _selected.containsKey(id),
                        onChanged: inactive ? null : (v) => _toggle(item, v),
                        controlAffinity: ListTileControlAffinity.leading,
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
                        secondary: inactive
                            ? const Chip(
                                label: Text('Inactivo'),
                                labelStyle: TextStyle(fontSize: 10),
                                padding: EdgeInsets.zero,
                              )
                            : null,
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_selected.values.toList()),
                      child: Text(_selected.isEmpty ? 'Aplicar' : 'Aplicar (${_selected.length})'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
