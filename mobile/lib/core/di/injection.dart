import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/use_cases/login_use_case.dart';
import '../../features/auth/domain/use_cases/logout_use_case.dart';
import '../../features/tipo_cambio/data/datasources/tipo_cambio_remote_datasource.dart';
import '../../features/tipo_cambio/data/repositories/tipo_cambio_repository_impl.dart';
import '../../features/tipo_cambio/domain/repositories/tipo_cambio_repository.dart';
import '../../features/maestros/data/datasources/maestros_remote_datasource.dart';
import '../../features/maestros/data/repositories/articulo_repository_impl.dart';
import '../../features/maestros/data/repositories/cliente_repository_impl.dart';
import '../../features/maestros/data/repositories/proveedor_repository_impl.dart';
import '../../features/maestros/data/repositories/almacen_repository_impl.dart';
import '../../features/maestros/domain/repositories/articulo_repository.dart';
import '../../features/maestros/domain/repositories/cliente_repository.dart';
import '../../features/maestros/domain/repositories/proveedor_repository.dart';
import '../../features/maestros/domain/repositories/almacen_repository.dart';
import '../../features/almacen/data/datasources/almacen_remote_datasource.dart';
import '../../features/almacen/data/repositories/movimiento_repository_impl.dart';
import '../../features/almacen/domain/repositories/movimiento_repository.dart';
import '../../features/tablas/data/datasources/tablas_remote_datasource.dart';
import '../../features/tablas/data/models/tabla_model.dart';
import '../../features/tablas/domain/entities/tabla_base.dart';
import '../../features/tablas/presentation/bloc/tabla_bloc.dart';
import '../../features/compras/data/datasources/compras_remote_datasource.dart';
import '../../features/ventas/data/datasources/ventas_remote_datasource.dart';
import '../../features/cxc/data/datasources/cxc_remote_datasource.dart';
import '../../features/cxp/data/datasources/cxp_remote_datasource.dart';
import '../../features/caja/data/datasources/caja_remote_datasource.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  getIt.registerLazySingleton<DioClient>(
    () => DioClient(getIt()),
  );

  // Auth
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<AuthRemoteDataSource>(),
      getIt<FlutterSecureStorage>(),
    ),
  );
  getIt.registerFactory(() => LoginUseCase(getIt()));
  getIt.registerFactory(() => LogoutUseCase(getIt()));

  // Tipo Cambio
  getIt.registerLazySingleton<TipoCambioRemoteDataSource>(
    () => TipoCambioRemoteDataSourceImpl(getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<TipoCambioRepository>(
    () => TipoCambioRepositoryImpl(getIt<TipoCambioRemoteDataSource>()),
  );

  // Maestros (shared datasource)
  getIt.registerLazySingleton<MaestrosRemoteDataSource>(
    () => MaestrosRemoteDataSourceImpl(getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<ArticuloRepository>(
    () => ArticuloRepositoryImpl(getIt<MaestrosRemoteDataSource>()),
  );
  getIt.registerLazySingleton<ClienteRepository>(
    () => ClienteRepositoryImpl(getIt<MaestrosRemoteDataSource>()),
  );
  getIt.registerLazySingleton<ProveedorRepository>(
    () => ProveedorRepositoryImpl(getIt<MaestrosRemoteDataSource>()),
  );
  getIt.registerLazySingleton<AlmacenRepository>(
    () => AlmacenRepositoryImpl(getIt<MaestrosRemoteDataSource>()),
  );

  // Tablas base
  getIt.registerLazySingleton<TablasRemoteDataSource>(
    () => TablasRemoteDataSource(getIt<DioClient>().dio),
  );
  getIt.registerFactory<TablaBloc<TipoLista>>(() => TablaBloc<TipoLista>(
    ds: getIt(), path: 'tipos-lista',
    fromJson: TablaModel.tipoListaFromJson, toJson: TablaModel.tipoListaToJson,
  ));
  getIt.registerFactory<TablaBloc<Linea>>(() => TablaBloc<Linea>(
    ds: getIt(), path: 'lineas',
    fromJson: TablaModel.lineaFromJson, toJson: TablaModel.toJson,
  ));
  getIt.registerFactory<TablaBloc<Medida>>(() => TablaBloc<Medida>(
    ds: getIt(), path: 'medidas',
    fromJson: TablaModel.medidaFromJson, toJson: TablaModel.toJson,
  ));
  getIt.registerFactory<TablaBloc<Banco>>(() => TablaBloc<Banco>(
    ds: getIt(), path: 'bancos',
    fromJson: TablaModel.bancoFromJson, toJson: TablaModel.toJson,
  ));
  getIt.registerFactory<TablaBloc<Marca>>(() => TablaBloc<Marca>(
    ds: getIt(), path: 'marcas',
    fromJson: TablaModel.marcaFromJson, toJson: TablaModel.toJson,
  ));
  getIt.registerFactory<TablaBloc<Documento>>(() => TablaBloc<Documento>(
    ds: getIt(), path: 'documentos',
    fromJson: TablaModel.documentoFromJson, toJson: TablaModel.documentoToJson,
  ));
  getIt.registerFactory<TablaBloc<TipoPago>>(() => TablaBloc<TipoPago>(
    ds: getIt(), path: 'tipos-pago',
    fromJson: TablaModel.tipoPagoFromJson, toJson: TablaModel.tipoPagoToJson,
  ));

  // Compras
  getIt.registerLazySingleton<ComprasRemoteDataSource>(
    () => ComprasRemoteDataSource(getIt<DioClient>().dio),
  );

  // Ventas
  getIt.registerLazySingleton<VentasRemoteDataSource>(
    () => VentasRemoteDataSource(getIt<DioClient>().dio),
  );

  // CxC
  getIt.registerLazySingleton<CxCRemoteDataSource>(
    () => CxCRemoteDataSource(getIt<DioClient>().dio),
  );

  // CxP
  getIt.registerLazySingleton<CxPRemoteDataSource>(
    () => CxPRemoteDataSource(getIt<DioClient>().dio),
  );

  // Caja
  getIt.registerLazySingleton<CajaRemoteDataSource>(
    () => CajaRemoteDataSource(getIt<DioClient>().dio),
  );

  // Almacén
  getIt.registerLazySingleton<AlmacenRemoteDataSource>(
    () => AlmacenRemoteDataSource(getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<MovimientoRepository>(
    () => MovimientoRepositoryImpl(getIt<AlmacenRemoteDataSource>()),
  );
}
