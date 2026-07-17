import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';

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
      _error   = null;
    });
    try {
      final dio      = getIt<DioClient>().dio;
      final response = await dio.get(
        '${ApiConstants.baseUrl}/utilitarios/usuarios',
      );
      final list = response.data as List<dynamic>;
      setState(() {
        _usuarios = list.cast<Map<String, dynamic>>();
      });
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Error al cargar usuarios';
      setState(() => _error = msg.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActivo(Map<String, dynamic> usuario) async {
    final id = usuario['id']?.toString() ?? '';
    try {
      final dio = getIt<DioClient>().dio;
      await dio.patch(
        '${ApiConstants.baseUrl}/utilitarios/usuarios/$id/toggle',
      );
      await _fetch();
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Error';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openNewUserSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NuevoUsuarioSheet(onCreated: _fetch),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de usuarios')),
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
                        final u      = _usuarios[i];
                        final activo = u['activo'] as bool? ?? false;
                        final nivel  = u['nivel']?.toString() ?? '';
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor:
                              Theme.of(ctx).colorScheme.surfaceContainerHighest,
                          leading: CircleAvatar(
                            backgroundColor: activo
                                ? Theme.of(ctx).colorScheme.primaryContainer
                                : Colors.grey.shade300,
                            child: Text(
                              (u['codigo']?.toString() ?? '?')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            u['nombre']?.toString() ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${u['codigo'] ?? ''} · $nivel',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _NivelChip(nivel: nivel),
                              const SizedBox(width: 8),
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

// ── Bottom sheet para crear usuario ─────────────────────────────────────────

class _NuevoUsuarioSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _NuevoUsuarioSheet({required this.onCreated});

  @override
  State<_NuevoUsuarioSheet> createState() => _NuevoUsuarioSheetState();
}

class _NuevoUsuarioSheetState extends State<_NuevoUsuarioSheet> {
  final _formKey      = GlobalKey<FormState>();
  final _codigoCtrl   = TextEditingController();
  final _nombreCtrl   = TextEditingController();
  final _claveCtrl    = TextEditingController();
  final _emailCtrl    = TextEditingController();

  String _nivel       = 'operador';
  bool _obscure       = true;
  bool _saving        = false;

  static const _niveles = ['ADMIN', 'supervisor', 'operador'];

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _claveCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final dio  = getIt<DioClient>().dio;
      final body = <String, dynamic>{
        'codigo': _codigoCtrl.text.trim(),
        'nombre': _nombreCtrl.text.trim(),
        'nivel':  _nivel,
        'clave':  _claveCtrl.text,
      };
      final email = _emailCtrl.text.trim();
      if (email.isNotEmpty) body['email'] = email;

      await dio.post(
        '${ApiConstants.baseUrl}/utilitarios/usuarios',
        data: body,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario creado'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onCreated();
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Error';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.toString()), backgroundColor: Colors.red),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nuevo usuario',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codigoCtrl,
              decoration: const InputDecoration(labelText: 'Código'),
              textCapitalization: TextCapitalization.characters,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _nivel,
              decoration: const InputDecoration(labelText: 'Nivel'),
              items: _niveles
                  .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                  .toList(),
              onChanged: (v) => setState(() => _nivel = v ?? 'operador'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _claveCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Crear usuario'),
            ),
          ],
        ),
      ),
    );
  }
}
