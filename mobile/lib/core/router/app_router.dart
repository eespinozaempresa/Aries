import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/tipo_cambio/presentation/pages/tipo_cambio_page.dart';
import '../../features/maestros/presentation/pages/maestros_hub_page.dart';
import '../../features/maestros/presentation/pages/articulos_list_page.dart';
import '../../features/maestros/presentation/pages/articulo_form_page.dart';
import '../../features/maestros/presentation/pages/personas_list_page.dart';
import '../../features/maestros/presentation/pages/persona_form_page.dart';
import '../../features/maestros/presentation/pages/almacenes_list_page.dart';
import '../../features/maestros/presentation/pages/almacen_form_page.dart';
import '../../features/compras/presentation/pages/compras_list_page.dart';
import '../../features/compras/presentation/pages/compra_form_page.dart';
import '../../features/compras/presentation/pages/compra_detail_page.dart';
import '../../features/tablas/presentation/pages/tablas_hub_page.dart';
import '../../features/tablas/presentation/pages/tabla_list_page.dart';
import '../../features/tablas/domain/entities/tabla_base.dart';
import '../../features/tablas/presentation/bloc/tabla_bloc.dart';
import '../../features/almacen/presentation/pages/almacen_hub_page.dart';
import '../../features/almacen/presentation/pages/movimientos_list_page.dart';
import '../../features/almacen/presentation/pages/movimiento_form_page.dart';
import '../../features/almacen/presentation/pages/movimiento_detail_page.dart';
import '../../features/almacen/presentation/pages/kardex_page.dart';
import '../../features/almacen/presentation/pages/stock_page.dart';
import '../../features/ventas/presentation/pages/ventas_list_page.dart';
import '../../features/ventas/presentation/pages/venta_form_page.dart';
import '../../features/ventas/presentation/pages/venta_detail_page.dart';
import '../../features/ventas/presentation/pages/reporte_utilidad_page.dart';
import '../../features/cxc/presentation/pages/cxc_list_page.dart';
import '../../features/cxc/presentation/pages/cxc_detail_page.dart';
import '../../features/cxp/presentation/pages/cxp_list_page.dart';
import '../../features/cxp/presentation/pages/cxp_detail_page.dart';
import '../../features/caja/presentation/pages/caja_list_page.dart';
import '../../features/caja/presentation/pages/caja_reporte_page.dart';
import '../../features/utilitarios/presentation/pages/utilitarios_page.dart';
import '../../features/utilitarios/presentation/pages/cambiar_clave_page.dart';
import '../../features/utilitarios/presentation/pages/parametros_page.dart';
import '../../features/utilitarios/presentation/pages/usuarios_page.dart';
import '../../features/utilitarios/presentation/pages/auditoria_page.dart';
import '../di/injection.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

class AppRouter {
  static final _publicRoutes = {'/login'};

  static final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final repo = getIt<AuthRepository>();
      final loggedIn = await repo.isLoggedIn();
      final isPublic = _publicRoutes.contains(state.matchedLocation);
      if (!loggedIn && !isPublic) return '/login';
      if (loggedIn && state.matchedLocation == '/login') return '/tipo-cambio';
      return null;
    },
    routes: [
      GoRoute(path: '/login',      builder: (_, __) => const LoginPage()),
      GoRoute(path: '/tipo-cambio',builder: (_, __) => const TipoCambioPage()),
      GoRoute(path: '/home',       builder: (_, __) => const HomePage()),

      // Compras
      GoRoute(
        path: '/compras',
        builder: (_, __) => const ComprasListPage(),
        routes: [
          GoRoute(path: 'nueva', builder: (_, __) => const CompraFormPage()),
          GoRoute(path: ':id',   builder: (_, s)  => CompraDetailPage(compraId: s.pathParameters['id']!)),
        ],
      ),

      // Tablas
      GoRoute(path: '/tablas', builder: (_, __) => const TablasHubPage()),
      GoRoute(path: '/tablas/lineas',     builder: (_, __) => LineasPage(bloc: getIt<TablaBloc<Linea>>())),
      GoRoute(path: '/tablas/medidas',    builder: (_, __) => MedidasPage(bloc: getIt<TablaBloc<Medida>>())),
      GoRoute(path: '/tablas/bancos',     builder: (_, __) => BancosPage(bloc: getIt<TablaBloc<Banco>>())),
      GoRoute(path: '/tablas/marcas',     builder: (_, __) => MarcasPage(bloc: getIt<TablaBloc<Marca>>())),
      GoRoute(path: '/tablas/documentos', builder: (_, __) => DocumentosPage(bloc: getIt<TablaBloc<Documento>>())),

      // Maestros
      GoRoute(path: '/maestros',   builder: (_, __) => const MaestrosHubPage()),

      GoRoute(
        path: '/maestros/articulos',
        builder: (_, __) => const ArticulosListPage(),
        routes: [
          GoRoute(path: 'nuevo',   builder: (_, __) => const ArticuloFormPage()),
          GoRoute(path: ':id',     builder: (_, s)  => ArticuloFormPage(articuloId: s.pathParameters['id'])),
        ],
      ),

      GoRoute(
        path: '/maestros/clientes',
        builder: (_, __) => const ClientesListPage(),
        routes: [
          GoRoute(path: 'nuevo', builder: (_, __) => const PersonaFormPage(tipo: PersonaTipo.cliente)),
          GoRoute(path: ':id',   builder: (_, s)  => PersonaFormPage(tipo: PersonaTipo.cliente, personaId: s.pathParameters['id'])),
        ],
      ),

      GoRoute(
        path: '/maestros/proveedores',
        builder: (_, __) => const ProveedoresListPage(),
        routes: [
          GoRoute(path: 'nuevo', builder: (_, __) => const PersonaFormPage(tipo: PersonaTipo.proveedor)),
          GoRoute(path: ':id',   builder: (_, s)  => PersonaFormPage(tipo: PersonaTipo.proveedor, personaId: s.pathParameters['id'])),
        ],
      ),

      GoRoute(
        path: '/maestros/almacenes',
        builder: (_, __) => const AlmacenesListPage(),
        routes: [
          GoRoute(path: 'nuevo', builder: (_, __) => const AlmacenFormPage()),
          GoRoute(path: ':id',   builder: (_, s)  => AlmacenFormPage(almacenId: s.pathParameters['id'])),
        ],
      ),

      // Ventas
      GoRoute(
        path: '/ventas',
        builder: (_, __) => const VentasListPage(),
        routes: [
          GoRoute(path: 'nueva',            builder: (_, __) => const VentaFormPage()),
          GoRoute(path: 'reporte-utilidad', builder: (_, __) => const ReporteUtilidadPage()),
          GoRoute(path: ':id',              builder: (_, s)  => VentaDetailPage(ventaId: s.pathParameters['id']!)),
        ],
      ),

      // CxP
      GoRoute(
        path: '/cxp',
        builder: (_, __) => const CxPListPage(),
        routes: [
          GoRoute(path: ':id', builder: (_, s) => CxPDetailPage(cxpId: s.pathParameters['id']!)),
        ],
      ),

      // CxC
      GoRoute(
        path: '/cxc',
        builder: (_, __) => const CxCListPage(),
        routes: [
          GoRoute(path: ':id', builder: (_, s) => CxCDetailPage(cxcId: s.pathParameters['id']!)),
        ],
      ),

      // Caja
      GoRoute(
        path: '/caja',
        builder: (_, __) => const CajaListPage(),
        routes: [
          GoRoute(path: ':id', builder: (_, s) => CajaReportePage(sesionId: s.pathParameters['id']!)),
        ],
      ),

      // Almacén
      GoRoute(path: '/almacen', builder: (_, __) => const AlmacenHubPage()),
      GoRoute(
        path: '/almacen/movimientos',
        builder: (_, __) => const MovimientosListPage(),
        routes: [
          GoRoute(path: 'nuevo', builder: (_, __) => const MovimientoFormPage()),
          GoRoute(path: ':id',   builder: (_, s)  => MovimientoDetailPage(movimientoId: s.pathParameters['id']!)),
        ],
      ),
      GoRoute(path: '/almacen/kardex', builder: (_, __) => const KardexPage()),
      GoRoute(path: '/almacen/stock',  builder: (_, __) => const StockPage()),

      // Utilitarios
      GoRoute(
        path: '/utilitarios',
        builder: (_, __) => const UtilitariosPage(),
        routes: [
          GoRoute(path: 'cambiar-clave', builder: (_, __) => const CambiarClavePage()),
          GoRoute(path: 'parametros',    builder: (_, __) => const ParametrosPage()),
          GoRoute(path: 'usuarios',      builder: (_, __) => const UsuariosPage()),
          GoRoute(path: 'auditoria',     builder: (_, __) => const AuditoriaPage()),
        ],
      ),
    ],
  );
}
