import '../../domain/entities/tabla_base.dart';

class TablaModel {
  static Map<String, dynamic> toJson(TablaBase t) => {
    'codigo': t.codigo,
    'descripcion': t.descripcion,
    'activo': t.activo,
  };

  static TipoLista tipoListaFromJson(Map<String, dynamic> j) => TipoLista(
    id: j['id'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    codigo: j['codigo'] as String,
    descripcion: j['descripcion'] as String,
    activo: j['activo'] as bool? ?? true,
    dsctoPct: (j['dsctoPct'] as num?)?.toDouble() ?? 0,
    dctoMto: (j['dctoMto'] as num?)?.toDouble() ?? 0,
  );

  static Map<String, dynamic> tipoListaToJson(TipoLista t) => {
    'codigo': t.codigo,
    'descripcion': t.descripcion,
    'dsctoPct': t.dsctoPct,
    'dctoMto': t.dctoMto,
    'activo': t.activo,
  };

  static TipoPago tipoPagoFromJson(Map<String, dynamic> j) => TipoPago(
    id: j['id'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    codigo: j['codigo'] as String,
    descripcion: j['descripcion'] as String,
    activo: j['activo'] as bool? ?? true,
    requiereOperacion: j['requiereOperacion'] as bool? ?? false,
  );

  static Map<String, dynamic> tipoPagoToJson(TipoPago t) => {
    'codigo': t.codigo,
    'descripcion': t.descripcion,
    'activo': t.activo,
    'requiereOperacion': t.requiereOperacion,
  };

  static Linea lineaFromJson(Map<String, dynamic> j) => Linea(
    id: j['id'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    codigo: j['codigo'] as String,
    descripcion: j['descripcion'] as String,
    activo: j['activo'] as bool,
  );

  static Medida medidaFromJson(Map<String, dynamic> j) => Medida(
    id: j['id'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    codigo: j['codigo'] as String,
    descripcion: j['descripcion'] as String,
    activo: j['activo'] as bool,
  );

  static Banco bancoFromJson(Map<String, dynamic> j) => Banco(
    id: j['id'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    codigo: j['codigo'] as String,
    descripcion: j['descripcion'] as String,
    activo: j['activo'] as bool,
  );

  static Marca marcaFromJson(Map<String, dynamic> j) => Marca(
    id: j['id'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    codigo: j['codigo'] as String,
    descripcion: j['descripcion'] as String,
    activo: j['activo'] as bool,
  );

  static Documento documentoFromJson(Map<String, dynamic> j) => Documento(
    id: j['id'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    codigo: j['codigo'] as String,
    descripcion: j['descripcion'] as String,
    activo: j['activo'] as bool,
    abreviatura: j['abreviatura'] as String?,
    serie: j['serie'] as String? ?? '0001',
    numeroSiguiente: (j['numeroSiguiente'] as num?)?.toInt() ?? 1,
    aplicaIgv: j['aplicaIgv'] as bool? ?? false,
    tipo: j['tipo'] as String?,
  );

  static Map<String, dynamic> documentoToJson(Documento d) => {
    'codigo': d.codigo,
    'descripcion': d.descripcion,
    'activo': d.activo,
    if (d.abreviatura != null) 'abreviatura': d.abreviatura,
    'serie': d.serie,
    'numeroSiguiente': d.numeroSiguiente,
    'aplicaIgv': d.aplicaIgv,
    if (d.tipo != null) 'tipo': d.tipo,
  };
}
