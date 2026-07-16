import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';
import '../models/tipo_cambio_model.dart';

abstract class TipoCambioRemoteDataSource {
  Future<TipoCambioModel?> getHoy();
  Future<TipoCambioModel> registrar(double tipoCambio);
}

class TipoCambioRemoteDataSourceImpl implements TipoCambioRemoteDataSource {
  final Dio _dio;
  const TipoCambioRemoteDataSourceImpl(this._dio);

  @override
  Future<TipoCambioModel?> getHoy() async {
    try {
      final res = await _dio.get('/tipo-cambio/hoy');
      final data = res.data['data'];
      if (data == null) return null;
      return TipoCambioModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<TipoCambioModel> registrar(double tipoCambio) async {
    try {
      final res = await _dio.post('/tipo-cambio', data: {'tipoCambio': tipoCambio});
      return TipoCambioModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
