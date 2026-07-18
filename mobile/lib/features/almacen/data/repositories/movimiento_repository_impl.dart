import 'package:dartz/dartz.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/movimiento.dart';
import '../../domain/entities/kardex_item.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/repositories/movimiento_repository.dart';
import '../datasources/almacen_remote_datasource.dart';
import '../models/movimiento_model.dart';

class MovimientoRepositoryImpl implements MovimientoRepository {
  final AlmacenRemoteDataSource _ds;
  const MovimientoRepositoryImpl(this._ds);

  @override
  Future<Either<ApiException, String>> registrar({
    required String codigoDocumento,
    String serie = '0001',
    required String fecha,
    required TipoMovimiento tipo,
    required String codigoAlmacenOrigen,
    String? codigoAlmacenDest,
    String? observacion,
    String? concepto,
    required List<Map<String, dynamic>> lineas,
  }) async {
    try {
      final id = await _ds.registrar({
        'codigoDocumento': codigoDocumento,
        'serie': serie,
        'fecha': fecha,
        'tipo': tipo.name,
        'codigoAlmacenOrigen': codigoAlmacenOrigen,
        if (codigoAlmacenDest != null) 'codigoAlmacenDest': codigoAlmacenDest,
        if (observacion != null) 'observacion': observacion,
        if (concepto != null) 'concepto': concepto,
        'lineas': lineas,
      });
      return Right(id);
    } on ApiException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<ApiException, Movimiento>> findById(String id) async {
    try {
      return Right(await _ds.findById(id));
    } on ApiException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<ApiException, Map<String, dynamic>>> list({
    TipoMovimiento? tipo,
    String? codigoAlmacen,
    String? desde,
    String? hasta,
    bool? soloAnulados,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return Right(await _ds.list({
        if (tipo != null) 'tipo': tipo.name,
        if (codigoAlmacen != null) 'almacen': codigoAlmacen,
        if (desde != null) 'desde': desde,
        if (hasta != null) 'hasta': hasta,
        if (soloAnulados != null) 'anulados': soloAnulados.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      }));
    } on ApiException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<ApiException, Movimiento>> anular(String id) async {
    try {
      return Right(await _ds.anular(id));
    } on ApiException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<ApiException, List<KardexItem>>> getKardex({
    String? codigoAlmacen,
    String? codigoArticulo,
    String? desde,
    String? hasta,
  }) async {
    try {
      final list = await _ds.getKardex({
        if (codigoAlmacen != null) 'almacen': codigoAlmacen,
        if (codigoArticulo != null) 'articulo': codigoArticulo,
        if (desde != null) 'desde': desde,
        if (hasta != null) 'hasta': hasta,
      });
      return Right(list.map((e) => KardexModel.fromJson(e as Map<String, dynamic>)).toList());
    } on ApiException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<ApiException, Map<String, dynamic>>> recalcularKardex() async {
    try {
      return Right(await _ds.recalcularKardex());
    } on ApiException catch (e) {
      return Left(e);
    }
  }

  @override
  Future<Either<ApiException, List<StockItem>>> getStock({
    String? codigoAlmacen,
    String? codigoArticulo,
    String? q,
    bool soloConStock = false,
  }) async {
    try {
      final list = await _ds.getStock({
        if (codigoAlmacen != null) 'almacen': codigoAlmacen,
        if (codigoArticulo != null) 'articulo': codigoArticulo,
        if (q != null) 'q': q,
        if (soloConStock) 'soloConStock': 'true',
      });
      return Right(list.map((e) => StockModel.fromJson(e as Map<String, dynamic>)).toList());
    } on ApiException catch (e) {
      return Left(e);
    }
  }
}
