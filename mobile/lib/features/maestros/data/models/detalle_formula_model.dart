import '../../domain/entities/detalle_formula.dart';

class DetalleFormulaModel extends DetalleFormula {
  const DetalleFormulaModel({
    super.id,
    super.formulaId,
    required super.codigoArticulo,
    super.descripcionArticulo,
    required super.cantidad,
    super.orden,
  });

  factory DetalleFormulaModel.fromJson(Map<String, dynamic> j) => DetalleFormulaModel(
        id: j['id'] as String?,
        formulaId: j['formulaId'] as String?,
        codigoArticulo: j['codigoArticulo'] as String,
        descripcionArticulo: j['descripcionArticulo'] as String?,
        cantidad: (j['cantidad'] as num).toDouble(),
        orden: (j['orden'] as num?)?.toInt() ?? 0,
      );
}
