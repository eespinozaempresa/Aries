import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UtilitariosPage extends StatelessWidget {
  const UtilitariosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      const _Tile('Cambiar contraseña',   'Actualiza tu clave de acceso',      Icons.lock_reset_outlined,       '/utilitarios/cambiar-clave',    false),
      const _Tile('Tipo de Cambio',       'Historial de tipos de cambio USD',  Icons.currency_exchange_outlined, '/utilitarios/tipo-cambio',     false),
      const _Tile('Parámetros',           'IGV, plazos y configuración',       Icons.tune_outlined,              '/utilitarios/parametros',      true),
      const _Tile('Gestión de usuarios',  'Crear y administrar usuarios',      Icons.manage_accounts_outlined,   '/utilitarios/usuarios',        true),
      const _Tile('Auditoría',            'Historial de sesiones del sistema', Icons.history_outlined,           '/utilitarios/auditoria',       true),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Utilitarios')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final t = tiles[i];
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: t.proximamente
                ? Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : Theme.of(ctx).colorScheme.surfaceContainerHighest,
            leading: Icon(
              t.icon,
              color: t.proximamente
                  ? Theme.of(ctx).colorScheme.outline
                  : Theme.of(ctx).colorScheme.primary,
            ),
            title: Row(
              children: [
                Text(t.title, style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: t.proximamente ? Theme.of(ctx).colorScheme.outline : null,
                )),
                if (t.proximamente) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Próximamente',
                        style: TextStyle(fontSize: 10, color: Theme.of(ctx).colorScheme.outline)),
                  ),
                ],
              ],
            ),
            subtitle: Text(t.subtitle,
                style: t.proximamente
                    ? TextStyle(color: Theme.of(ctx).colorScheme.outline)
                    : null),
            trailing: t.proximamente ? null : const Icon(Icons.chevron_right),
            onTap: t.proximamente ? null : () => ctx.push(t.route),
          );
        },
      ),
    );
  }
}

class _ChangePasswordPage extends StatefulWidget {
  const _ChangePasswordPage();

  @override
  State<_ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<_ChangePasswordPage> {
  final _formKey   = GlobalKey<FormState>();
  final _claveCtrl = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _loading    = false;
  bool _obscure1   = true;
  bool _obscure2   = true;

  @override
  void dispose() {
    _claveCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funcionalidad disponible próximamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _claveCtrl,
                obscureText: _obscure1,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confCtrl,
                obscureText: _obscure2,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                ),
                validator: (v) => v != _claveCtrl.text ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool proximamente;
  const _Tile(this.title, this.subtitle, this.icon, this.route, this.proximamente);
}
