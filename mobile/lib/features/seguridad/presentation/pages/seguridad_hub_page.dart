import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/menu_permission_service.dart';
import '../../../../core/widgets/aries_app_bar.dart';

class SeguridadHubPage extends StatelessWidget {
  const SeguridadHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = MenuPermissionService.instance;
    final tiles = [
      if (svc.canAccess('seguridad.usuarios'))
        const _Tile('Gestión de usuarios', 'Crear y administrar usuarios',
            Icons.manage_accounts_outlined, '/seguridad/usuarios'),
      if (svc.canAccess('seguridad.auditoria'))
        const _Tile('Auditoría', 'Historial de sesiones del sistema',
            Icons.history_outlined, '/seguridad/auditoria'),
      if (svc.canAccess('seguridad.perfiles'))
        const _Tile('Perfiles', 'Control de acceso por perfil de usuario',
            Icons.admin_panel_settings_outlined, '/seguridad/perfiles'),
    ];

    return Scaffold(
      appBar: AriesAppBar(title: const Text('Seguridad')),
      body: tiles.isEmpty
          ? const Center(child: Text('Sin acceso a opciones de seguridad'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final t = tiles[i];
                return ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  tileColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  leading: Icon(t.icon, color: Theme.of(ctx).colorScheme.primary),
                  title: Text(t.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(t.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ctx.push(t.route),
                );
              },
            ),
    );
  }
}

class _Tile {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  const _Tile(this.title, this.subtitle, this.icon, this.route);
}
