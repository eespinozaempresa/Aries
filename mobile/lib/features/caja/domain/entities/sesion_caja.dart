enum EstadoCaja { ABIERTA, CERRADA }
enum TipoMovCaja { INGRESO, EGRESO }

class SesionCaja {
  final String id;
  final String codigoEmpresa;
  final String codigoCaja;
  final String codigoUsuario;
  final String fechaApertura;
  final double montoApertura;
  final String? fechaCierre;
  final double? montosCierre;
  final double? diferencia;
  final EstadoCaja estado;

  const SesionCaja({
    required this.id,
    required this.codigoEmpresa,
    required this.codigoCaja,
    required this.codigoUsuario,
    required this.fechaApertura,
    required this.montoApertura,
    this.fechaCierre,
    this.montosCierre,
    this.diferencia,
    required this.estado,
  });

  factory SesionCaja.fromJson(Map<String, dynamic> j) => SesionCaja(
    id: j['id'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    codigoCaja: j['codigoCaja'] as String,
    codigoUsuario: j['codigoUsuario'] as String,
    fechaApertura: j['fechaApertura'] as String,
    montoApertura: (j['montoApertura'] as num).toDouble(),
    fechaCierre: j['fechaCierre'] as String?,
    montosCierre: j['montosCierre'] != null ? (j['montosCierre'] as num).toDouble() : null,
    diferencia: j['diferencia'] != null ? (j['diferencia'] as num).toDouble() : null,
    estado: EstadoCaja.values.byName(j['estado'] as String),
  );
}

class MovimientoCaja {
  final String id;
  final String sesionCajaId;
  final TipoMovCaja tipo;
  final String concepto;
  final String? referencia;
  final String? tipoPago;
  final double monto;
  final String fecha;

  const MovimientoCaja({
    required this.id,
    required this.sesionCajaId,
    required this.tipo,
    required this.concepto,
    this.referencia,
    this.tipoPago,
    required this.monto,
    required this.fecha,
  });

  factory MovimientoCaja.fromJson(Map<String, dynamic> j) => MovimientoCaja(
    id: j['id'] as String,
    sesionCajaId: j['sesionCajaId'] as String,
    tipo: TipoMovCaja.values.byName(j['tipo'] as String),
    concepto: j['concepto'] as String,
    referencia: j['referencia'] as String?,
    tipoPago: j['tipoPago'] as String?,
    monto: (j['monto'] as num).toDouble(),
    fecha: j['fecha'] as String,
  );
}

class ReporteCaja {
  final SesionCaja sesion;
  final List<MovimientoCaja> movimientos;
  final double totalIngresos;
  final double totalEgresos;
  final double saldoFinal;

  const ReporteCaja({
    required this.sesion,
    required this.movimientos,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldoFinal,
  });

  factory ReporteCaja.fromJson(Map<String, dynamic> j) => ReporteCaja(
    sesion: SesionCaja.fromJson(j['sesion'] as Map<String, dynamic>),
    movimientos: (j['movimientos'] as List)
      .map((m) => MovimientoCaja.fromJson(m as Map<String, dynamic>)).toList(),
    totalIngresos: (j['totalIngresos'] as num).toDouble(),
    totalEgresos:  (j['totalEgresos']  as num).toDouble(),
    saldoFinal:    (j['saldoFinal']    as num).toDouble(),
  );
}
