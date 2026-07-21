import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/menu_permission_service.dart';
import '../../../../core/widgets/aries_app_bar.dart';

Future<void> _showForbiddenDialog(BuildContext context, String message) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
      title: const Text('Acción no permitida'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  List<Map<String, dynamic>> _usuarios = [];
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
      final response = await dio.get('${ApiConstants.baseUrl}/utilitarios/usuarios');
      final list = response.data as List<dynamic>;
      setState(() => _usuarios = list.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Error al cargar usuarios';
      setState(() => _error = msg.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _guardaAdmin(Map<String, dynamic> usuario) {
    final targetNivel = usuario['nivel']?.toString().toUpperCase() ?? '';
    if (targetNivel == 'ADMIN' && !MenuPermissionService.instance.isAdmin) {
      _showForbiddenDialog(
        context,
        'No tiene permisos para modificar un usuario administrador',
      );
      return true;
    }
    return false;
  }

  Future<void> _toggleActivo(Map<String, dynamic> usuario) async {
    if (_guardaAdmin(usuario)) return;
    final id = usuario['id']?.toString() ?? '';
    try {
      final dio = getIt<DioClient>().dio;
      await dio.patch('${ApiConstants.baseUrl}/utilitarios/usuarios/$id/toggle');
      await _fetch();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data['message'] ?? 'Error').toString();
      if (e.response?.statusCode == 403) {
        _showForbiddenDialog(context, msg);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openNewUserSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UsuarioSheet(onSaved: _fetch),
    );
  }

  void _openEditSheet(Map<String, dynamic> usuario) {
    if (_guardaAdmin(usuario)) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UsuarioSheet(usuario: usuario, onSaved: _fetch),
    );
  }

  void _openResetPasswordDialog(Map<String, dynamic> usuario) {
    if (_guardaAdmin(usuario)) return;
    showDialog(
      context: context,
      builder: (ctx) => _ResetPasswordDialog(usuario: usuario),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AriesAppBar(title: const Text('Gestión de usuarios')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewUserSheet,
        tooltip: 'Nuevo usuario',
        child: const Icon(Icons.person_add_outlined),
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
              : _usuarios.isEmpty
                  ? const Center(child: Text('Sin usuarios'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _usuarios.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final u = _usuarios[i];
                        final activo = u['activo'] as bool? ?? false;
                        final nivel = u['nivel']?.toString() ?? '';
                        final perfilDesc = u['perfilDescripcion']?.toString();
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
                              (u['codigo']?.toString() ?? '?')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            u['nombre']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${u['codigo'] ?? ''} · $nivel'
                            '${perfilDesc != null ? ' · $perfilDesc' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _NivelChip(nivel: nivel),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _openEditSheet(u),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.lock_reset_outlined, size: 20),
                                onPressed: () => _openResetPasswordDialog(u),
                                tooltip: 'Resetear contraseña',
                              ),
                              Switch(
                                value: activo,
                                onChanged: (_) => _toggleActivo(u),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

class _NivelChip extends StatelessWidget {
  final String nivel;
  const _NivelChip({required this.nivel});

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (nivel.toUpperCase()) {
      case 'ADMIN':
        bg = Colors.purple.shade100;
        break;
      case 'SUPERVISOR':
        bg = Colors.blue.shade100;
        break;
      default:
        bg = Colors.grey.shade200;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        nivel,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Sheet para crear / editar usuario ─────────────────────────────────────────

class _UsuarioSheet extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final VoidCallback onSaved;
  const _UsuarioSheet({this.usuario, required this.onSaved});

  @override
  State<_UsuarioSheet> createState() => _UsuarioSheetState();
}

class _UsuarioSheetState extends State<_UsuarioSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _claveCtrl  = TextEditingController();
  final _emailCtrl  = TextEditingController();

  String _nivel    = 'OPERADOR';
  String? _perfilId;
  bool _obscure    = true;
  bool _saving     = false;

  List<Map<String, dynamic>> _perfiles = [];
  bool _loadingPerfiles = false;

  bool get _isEdit => widget.usuario != null;

  static const _niveles = ['ADMIN', 'SUPERVISOR', 'OPERADOR'];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final u = widget.usuario!;
      _codigoCtrl.text = u['codigo']?.toString() ?? '';
      _nombreCtrl.text = u['nombre']?.toString() ?? '';
      _emailCtrl.text  = u['email']?.toString() ?? '';
      final rawNivel = u['nivel']?.toString() ?? 'operador';
      _nivel = _niveles.firstWhere(
        (n) => n.toLowerCase() == rawNivel.toLowerCase(),
        orElse: () => 'operador',
      );
      _perfilId = u['perfilId']?.toString();
    }
    _loadPerfiles();
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _claveCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPerfiles() async {
    setState(() => _loadingPerfiles = true);
    try {
      final dio = getIt<DioClient>().dio;
      final res = await dio.get('${ApiConstants.baseUrl}/utilitarios/perfiles');
      if (mounted) {
        setState(() {
          _perfiles = (res.data as List)
              .cast<Map<String, dynamic>>()
              .where((p) => p['activo'] == true)
              .toList();
        });
      }
    } catch (_) {
      // non-critical; perfil dropdown will be empty
    } finally {
      if (mounted) setState(() => _loadingPerfiles = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final dio = getIt<DioClient>().dio;
      final email = _emailCtrl.text.trim();

      if (_isEdit) {
        final body = <String, dynamic>{
          'nombre': _nombreCtrl.text.trim(),
          'nivel': _nivel,
          'perfilId': _perfilId ?? '',
        };
        if (email.isNotEmpty) body['email'] = email;
        await dio.put(
          '${ApiConstants.baseUrl}/utilitarios/usuarios/${widget.usuario!['id']}',
          data: body,
        );
      } else {
        final body = <String, dynamic>{
          'codigo': _codigoCtrl.text.trim(),
          'nombre': _nombreCtrl.text.trim(),
          'nivel': _nivel,
          'clave': _claveCtrl.text,
        };
        if (email.isNotEmpty) body['email'] = email;
        if (_perfilId != null && _perfilId!.isNotEmpty) body['perfilId'] = _perfilId;
        await dio.post('${ApiConstants.baseUrl}/utilitarios/usuarios', data: body);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Usuario actualizado' : 'Usuario creado'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data['message'] ?? 'Error').toString();
      if (e.response?.statusCode == 403) {
        _showForbiddenDialog(context, msg);
      } else {
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
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? 'Editar usuario' : 'Nuevo usuario',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codigoCtrl,
                enabled: !_isEdit,
                decoration: const InputDecoration(labelText: 'Código'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _nivel,
                decoration: const InputDecoration(labelText: 'Nivel'),
                items: _niveles
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (v) => setState(() => _nivel = v ?? 'operador'),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _claveCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
              ],
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (opcional)'),
              ),
              const SizedBox(height: 8),
              _loadingPerfiles
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                  : DropdownButtonFormField<String>(
                      value: _perfiles.any((p) => p['id'] == _perfilId)
                          ? _perfilId
                          : null,
                      decoration: const InputDecoration(labelText: 'Perfil (opcional)'),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('Sin perfil')),
                        ..._perfiles.map((p) => DropdownMenuItem<String>(
                              value: p['id']?.toString(),
                              child: Text(p['descripcion']?.toString() ?? ''),
                            )),
                      ],
                      onChanged: (v) => setState(() => _perfilId = v),
                    ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEdit ? 'Guardar cambios' : 'Crear usuario'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Diálogo reset de contraseña ───────────────────────────────────────────────

class _ResetPasswordDialog extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const _ResetPasswordDialog({required this.usuario});

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey    = GlobalKey<FormState>();
  final _claveCtrl  = TextEditingController();
  final _confCtrl   = TextEditingController();
  bool _obscure1    = true;
  bool _obscure2    = true;
  bool _saving      = false;

  @override
  void dispose() {
    _claveCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final dio = getIt<DioClient>().dio;
      await dio.patch(
        '${ApiConstants.baseUrl}/utilitarios/usuarios/${widget.usuario['id']}/reset-password',
        data: {'nuevaClave': _claveCtrl.text},
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contraseña de ${widget.usuario['nombre']} actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = (e.response?.data['message'] ?? 'Error').toString();
      if (e.response?.statusCode == 403) {
        _showForbiddenDialog(context, msg);
      } else {
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
    return AlertDialog(
      title: const Text('Resetear contraseña'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.usuario['nombre']?.toString() ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _claveCtrl,
              obscureText: _obscure1,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure1
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confCtrl,
              obscureText: _obscure2,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure2
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                ),
              ),
              validator: (v) =>
                  v != _claveCtrl.text ? 'Las contraseñas no coinciden' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Resetear'),
        ),
      ],
    );
  }
}
