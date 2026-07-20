import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/constants/api_constants.dart';
import 'core/di/injection.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/services/menu_permission_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const AriesApp());
}

class AriesApp extends StatefulWidget {
  const AriesApp({super.key});

  @override
  State<AriesApp> createState() => _AriesAppState();
}

class _AriesAppState extends State<AriesApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _logAppExit();
    }
  }

  Future<void> _logAppExit() async {
    final storage = getIt<FlutterSecureStorage>();
    final refreshToken = await storage.read(key: ApiConstants.kRefreshToken);
    if (refreshToken == null) return;
    try {
      await getIt<DioClient>().dio.post(
        '${ApiConstants.baseUrl}/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } catch (_) {}
    await storage.deleteAll();
    MenuPermissionService.instance.clear();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Aries',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
