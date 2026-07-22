import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/api_constants.dart';
import '../di/injection.dart';
import '../services/menu_permission_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// AppBar estándar de la app: agrega siempre, al final de [actions],
/// el botón Inicio (oculto en /home); en /home se muestra en su lugar
/// un botón de usuario que abre un popup con los datos de la sesión,
/// Cambiar contraseña y Cerrar sesión.
class AriesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget> actions;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const AriesAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final isHome = GoRouterState.of(context).matchedLocation == '/home';
    return AppBar(
      title: title,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      actions: [
        ...actions,
        if (!isHome)
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Inicio',
            onPressed: () => context.go('/home'),
          ),
        if (isHome)
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Usuario',
            onPressed: () => _showUserMenu(context),
          ),
      ],
    );
  }

  Future<void> _showUserMenu(BuildContext context) async {
    final usuario = await getIt<AuthRepository>().getCachedUsuario();
    final now = DateTime.now();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Mi cuenta'),
          IconButton(
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(dialogCtx),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Usuario', usuario?.codigo ?? '-'),
            _InfoRow('Nombre', usuario?.nombre ?? '-'),
            _InfoRow('Fecha', DateFormat('dd/MM/yyyy').format(now)),
            _InfoRow('Hora', DateFormat('HH:mm:ss').format(now)),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_reset_outlined),
              title: const Text('Cambiar Contraseña'),
              onTap: () {
                Navigator.pop(dialogCtx);
                context.push('/utilitarios/cambiar-clave');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(dialogCtx);
                _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final storage = getIt<FlutterSecureStorage>();
    final refreshToken = await storage.read(key: ApiConstants.kRefreshToken);
    if (refreshToken != null) {
      await getIt<AuthRepository>().logout(refreshToken);
    } else {
      await storage.deleteAll();
      MenuPermissionService.instance.clear();
    }
    if (context.mounted) context.go('/login');
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label: $value'),
    );
  }
}
