import '../../domain/entities/articulo.dart';

class ArticuloModel extends Articulo {
  const ArticuloModel({
    required super.id,
    required super.codigoEmpresa,
    required super.codigo,
    required super.descripcion,
    super.codigoLinea,
    super.codigoMedida,
    super.codigoMarca,
    required super.precioCompraBase,
    required super.precioCompra,
    required super.utilidadPct,
    required super.precioVentaBase,
    required super.precioVenta,
    required super.stockMinimo,
    required super.stockMaximo,
    super.codigoBarras,
    required super.activo,
    super.conFormula,
  });

  factory ArticuloModel.fromJson(Map<String, dynamic> j) => ArticuloModel(
        id: j['id'] as String,
        codigoEmpresa: j['codigoEmpresa'] as String,
        codigo: j['codigo'] as String,
        descripcion: j['descripcion'] as String,
        codigoLinea: j['codigoLinea'] as String?,
        codigoMedida: j['codigoMedida'] as String?,
        codigoMarca: j['codigoMarca'] as String?,
        precioCompraBase: (j['precioCompraBase'] as num?)?.toDouble() ?? 0,
        precioCompra: (j['precioCompra'] as num?)?.toDouble() ?? 0,
        utilidadPct: (j['utilidadPct'] as num?)?.toDouble() ?? 0,
        precioVentaBase: (j['precioVentaBase'] as num?)?.toDouble() ?? 0,
        precioVenta: (j['precioVenta'] as num?)?.toDouble() ?? 0,
        stockMinimo: (j['stockMinimo'] as num?)?.toDouble() ?? 0,
        stockMaximo: (j['stockMaximo'] as num?)?.toDouble() ?? 0,
        codigoBarras: j['codigoBarras'] as String?,
        activo: j['activo'] as bool? ?? true,
        conFormula: j['conFormula'] as bool? ?? false,
      );
}
