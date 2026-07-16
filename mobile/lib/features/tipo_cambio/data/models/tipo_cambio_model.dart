import '../../domain/entities/tipo_cambio.dart';

class TipoCambioModel extends TipoCambio {
  const TipoCambioModel({
    required super.id,
    required super.codigoEmpresa,
    required super.fecha,
    required super.tipoCambio,
  });

  factory TipoCambioModel.fromJson(Map<String, dynamic> json) {
    return TipoCambioModel(
      id: json['id'] as String,
      codigoEmpresa: json['codigoEmpresa'] as String,
      fecha: json['fecha'] as String,
      tipoCambio: (json['tipoCambio'] as num).toDouble(),
    );
  }
}
