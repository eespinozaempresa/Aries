class TablaBase {
  final String id;
  final String codigoEmpresa;
  final String codigo;
  final String descripcion;
  final bool activo;

  const TablaBase({
    required this.id,
    required this.codigoEmpresa,
    required this.codigo,
    required this.descripcion,
    required this.activo,
  });

  String get subtitle => codigo;
}

class Linea  extends TablaBase { const Linea({required super.id, required super.codigoEmpresa, required super.codigo, required super.descripcion, required super.activo}); }
class Medida extends TablaBase { const Medida({required super.id, required super.codigoEmpresa, required super.codigo, required super.descripcion, required super.activo}); }
class Banco  extends TablaBase { const Banco({required super.id, required super.codigoEmpresa, required super.codigo, required super.descripcion, required super.activo}); }
class Marca  extends TablaBase { const Marca({required super.id, required super.codigoEmpresa, required super.codigo, required super.descripcion, required super.activo}); }

class TipoLista extends TablaBase {
  final double dsctoPct;
  final double dctoMto;

  const TipoLista({
    required super.id,
    required super.codigoEmpresa,
    required super.codigo,
    required super.descripcion,
    required super.activo,
    required this.dsctoPct,
    required this.dctoMto,
  });

  @override
  String get subtitle => 'Dscto: ${dsctoPct.toStringAsFixed(1)}% / S/ ${dctoMto.toStringAsFixed(2)}';
}

class TipoPago extends TablaBase {
  final bool requiereOperacion;

  const TipoPago({
    required super.id,
    required super.codigoEmpresa,
    required super.codigo,
    required super.descripcion,
    required super.activo,
    required this.requiereOperacion,
  });

  @override
  String get subtitle => requiereOperacion ? 'Requiere N° operación' : '';
}

class Documento extends TablaBase {
  final String? abreviatura;
  final String serie;
  final int numeroSiguiente;
  final bool aplicaIgv;
  final String? tipo;

  const Documento({
    required super.id,
    required super.codigoEmpresa,
    required super.codigo,
    required super.descripcion,
    required super.activo,
    this.abreviatura,
    this.serie = '0001',
    required this.numeroSiguiente,
    required this.aplicaIgv,
    this.tipo,
  });

  @override
  String get subtitle =>
      '${(abreviatura != null && abreviatura!.isNotEmpty) ? abreviatura! : codigo}-$serie';
}
