import 'package:dartz/dartz.dart';
import '../../../../core/network/api_exception.dart';
import '../entities/movimiento.dart';
import '../entities/kardex_item.dart';
import '../entities/stock_item.dart';

abstract class MovimientoRepository {
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
  });

  Future<Either<ApiException, Movimiento>> findById(String id);

  Future<Either<ApiException, Map<String, dynamic>>> list({
    TipoMovimiento? tipo,
    String? codigoAlmacen,
    String? desde,
    String? hasta,
    bool? soloAnulados,
    int page = 1,
    int limit = 20,
  });

  Future<Either<ApiException, Movimiento>> anular(String id);

  Future<Either<ApiException, List<KardexItem>>> getKardex({
    required String codigoAlmacen,
    required String codigoArticulo,
    String? desde,
    String? hasta,
  });

  Future<Either<ApiException, Map<String, dynamic>>> recalcularKardex();

  Future<Either<ApiException, List<StockItem>>> getStock({
    String? codigoAlmacen,
    String? codigoArticulo,
    String? q,
    bool soloConStock = false,
  });
}
