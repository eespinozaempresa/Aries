import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../constants/api_constants.dart';
import '../di/injection.dart';
import '../services/menu_permission_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// AppBar estándar de la app: agrega siempre, al final de [actions],
/// el botón Inicio (oculto en /home), Cambiar contraseña y Cerrar sesión.
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
        IconButton(
          icon: const Icon(Icons.lock_reset_outlined),
          tooltip: 'Cambiar contraseña',
          onPressed: () => context.push('/utilitarios/cambiar-clave'),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: () => _logout(context),
        ),
      ],
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
