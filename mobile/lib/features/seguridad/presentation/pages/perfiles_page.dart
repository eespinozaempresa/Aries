import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/aries_app_bar.dart';

// ── Menu tree definitions ─────────────────────────────────────────────────────

class _MenuGroup {
  final String key;
  final String label;
  final List<_MenuNode> children;
  const _MenuGroup(this.key, this.label, this.children);
}

class _MenuNode {
  final String key;
  final String label;
  const _MenuNode(this.key, this.label);
}

const _menuTree = [
  _MenuGroup('tablas', 'Tablas Base', [
    _MenuNode('tablas.tipos-lista', 'Tipos de Lista'),
    _MenuNode('tablas.tipos-pago', 'Tipos de Pago'),
    _MenuNode('tablas.lineas', 'Líneas'),
    _MenuNode('tablas.medidas', 'Medidas'),
    _MenuNode('tablas.bancos', 'Bancos'),
    _MenuNode('tablas.marcas', 'Marcas'),
    _MenuNode('tablas.documentos', 'Documentos'),
  ]),
  _MenuGroup('maestros', 'Maestros', [
    _MenuNode('maestros.articulos', 'Artículos'),
    _MenuNode('maestros.clientes', 'Clientes'),
    _MenuNode('maestros.proveedores', 'Proveedores'),
    _MenuNode('maestros.almacenes', 'Almacenes'),
  ]),
  _MenuGroup('almacen', 'Almacén', [
    _MenuNode('almacen.movimientos', 'Movimientos'),
    _MenuNode('almacen.kardex', 'Kardex'),
    _MenuNode('almacen.stock', 'Stock'),
  ]),
  _MenuGroup('compras', 'Compras', []),
  _MenuGroup('ventas', 'Ventas', []),
  _MenuGroup('cxc', 'Cuentas × Cobrar', []),
  _MenuGroup('cxp', 'Cuentas × Pagar', []),
  _MenuGroup('caja', 'Caja', []),
  _MenuGroup('seguridad', 'Seguridad', [
    _MenuNode('seguridad.usuarios', 'Gestión de usuarios'),
    _MenuNode('seguridad.auditoria', 'Auditoría'),
    _MenuNode('seguridad.perfiles', 'Perfiles'),
  ]),
  _MenuGroup('utilitarios', 'Utilitarios', [
    _MenuNode('utilitarios.cambiar-clave', 'Cambiar contraseña'),
    _MenuNode('utilitarios.tipo-cambio', 'Tipo de Cambio'),
    _MenuNode('utilitarios.parametros', 'Parámetros'),
  ]),
];

// ── Perfiles List Page ────────────────────────────────────────────────────────

class PerfilesPage extends StatefulWidget {
  const PerfilesPage({super.key});

  @override
  State<PerfilesPage> createState() => _PerfilesPageState();
}

class _PerfilesPageState extends State<PerfilesPage> {
  List<Map<String, dynamic>> _perfiles = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = getIt<DioClient>().dio;
      final res = await dio.get('${ApiConstants.baseUrl}/utilitarios/perfiles');
      setState(() => _perfiles = (res.data as List).cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      setState(() => _error = (e.response?.data['message'] ?? 'Error al cargar perfiles').toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> p) async {
    try {
      final dio = getIt<DioClient>().dio;
      await dio.patch('${ApiConstants.baseUrl}/utilitarios/perfiles/${p['id']}/toggle');
      await _fetch();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((e.response?.data['message'] ?? 'Error').toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openForm([Map<String, dynamic>? perfil]) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(
      builder: (_) => _PerfilFormPage(perfil: perfil, onSaved: _fetch),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AriesAppBar(title: const Text('Perfiles de usuario')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Nuevo perfil',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetch,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _perfiles.isEmpty
                  ? const Center(child: Text('Sin perfiles'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _perfiles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final p = _perfiles[i];
                        final activo = p['activo'] as bool? ?? false;
                        final menuCount = (p['menus'] as List?)?.length ?? 0;
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                          leading: CircleAvatar(
                            backgroundColor: activo
                                ? Theme.of(ctx).colorScheme.primaryContainer
                                : Colors.grey.shade300,
                            child: Text(
                              (p['codigo']?.toString() ?? '?').substring(0, 1),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            p['descripcion']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('${p['codigo'] ?? ''} · $menuCount opciones de menú'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openForm(p),
                              ),
                              Switch(
                                value: activo,
                                onChanged: (_) => _toggle(p),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

// ── Perfil Form Page ──────────────────────────────────────────────────────────

class _PerfilFormPage extends StatefulWidget {
  final Map<String, dynamic>? perfil;
  final VoidCallback onSaved;

  const _PerfilFormPage({this.perfil, required this.onSaved});

  @override
  State<_PerfilFormPage> createState() => _PerfilFormPageState();
}

class _PerfilFormPageState extends State<_PerfilFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Set<String> _selectedMenus = {};
  bool _saving = false;

  bool get _isEdit => widget.perfil != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _codigoCtrl.text = widget.perfil!['codigo']?.toString() ?? '';
      _descCtrl.text = widget.perfil!['descripcion']?.toString() ?? '';
      final menus = (widget.perfil!['menus'] as List?)?.cast<String>() ?? [];
      _selectedMenus = menus.toSet();
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _toggleGroup(_MenuGroup group) {
    setState(() {
      if (_isGroupFullySelected(group)) {
        _selectedMenus.remove(group.key);
        for (final c in group.children) {
          _selectedMenus.remove(c.key);
        }
      } else {
        _selectedMenus.add(group.key);
        for (final c in group.children) {
          _selectedMenus.add(c.key);
        }
      }
    });
  }

  void _toggleNode(String parentKey, String nodeKey) {
    setState(() {
      if (_selectedMenus.contains(nodeKey)) {
        _selectedMenus.remove(nodeKey);
      } else {
        _selectedMenus.add(nodeKey);
        _selectedMenus.add(parentKey);
      }
    });
  }

  bool _isGroupFullySelected(_MenuGroup group) {
    if (!_selectedMenus.contains(group.key)) return false;
    if (group.children.isEmpty) return true;
    return group.children.every((c) => _selectedMenus.contains(c.key));
  }

  bool? _groupCheckboxValue(_MenuGroup group) {
    if (_isGroupFullySelected(group)) return true;
    final anySelected = _selectedMenus.contains(group.key) ||
        group.children.any((c) => _selectedMenus.contains(c.key));
    return anySelected ? null : false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final dio = getIt<DioClient>().dio;
      final menusJson = _selectedMenus.toList();
      if (_isEdit) {
        await dio.put(
          '${ApiConstants.baseUrl}/utilitarios/perfiles/${widget.perfil!['id']}',
          data: {
            'descripcion': _descCtrl.text.trim(),
            'menus': menusJson,
          },
        );
      } else {
        await dio.post(
          '${ApiConstants.baseUrl}/utilitarios/perfiles',
          data: {
            'codigo': _codigoCtrl.text.trim().toUpperCase(),
            'descripcion': _descCtrl.text.trim(),
            'menus': menusJson,
          },
        );
      }
      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      final msg = (e.response?.data['message'] ?? 'Error al guardar').toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AriesAppBar(
        title: Text(_isEdit ? 'Editar perfil' : 'Nuevo perfil'),
        actions: [
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codigoCtrl,
              enabled: !_isEdit,
              decoration: const InputDecoration(labelText: 'Código'),
              textCapitalization: TextCapitalization.characters,
              maxLength: 10,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLength: 80,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            Text('Opciones de menú', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            ..._menuTree.map(_buildGroupTile),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTile(_MenuGroup group) {
    if (group.children.isEmpty) {
      return CheckboxListTile(
        value: _selectedMenus.contains(group.key),
        title: Text(group.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        onChanged: (_) => setState(() {
          if (_selectedMenus.contains(group.key)) {
            _selectedMenus.remove(group.key);
          } else {
            _selectedMenus.add(group.key);
          }
        }),
        controlAffinity: ListTileControlAffinity.leading,
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Row(
          children: [
            Checkbox(
              tristate: true,
              value: _groupCheckboxValue(group),
              onChanged: (_) => _toggleGroup(group),
            ),
            Text(group.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        children: group.children
            .map((node) => CheckboxListTile(
                  title: Text(node.label),
                  value: _selectedMenus.contains(node.key),
                  onChanged: (_) => _toggleNode(group.key, node.key),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.only(left: 32, right: 16),
                ))
            .toList(),
      ),
    );
  }
}
