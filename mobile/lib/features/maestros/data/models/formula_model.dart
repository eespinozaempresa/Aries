import '../../domain/entities/formula.dart';
import 'detalle_formula_model.dart';

class FormulaModel extends Formula {
  const FormulaModel({
    required super.id,
    required super.codigoEmpresa,
    required super.codigoArticulo,
    super.descripcionArticulo,
    super.observacion,
    required super.activo,
    super.detalle,
  });

  factory FormulaModel.fromJson(Map<String, dynamic> j) => FormulaModel(
        id: j['id'] as String,
        codigoEmpresa: j['codigoEmpresa'] as String,
        codigoArticulo: j['codigoArticulo'] as String,
        descripcionArticulo: j['descripcionArticulo'] as String?,
        observacion: j['observacion'] as String?,
        activo: j['activo'] as bool? ?? true,
        detalle: (j['detalle'] as List<dynamic>? ?? [])
            .map((e) => DetalleFormulaModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
