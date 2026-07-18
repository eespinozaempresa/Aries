enum TipoCxC { VENTA, RENOVACION }

class CuentaCobrar {
  final String id;
  final String codigoEmpresa;
  final int numeroProvision;
  final int? numeroProvisionOrigen;
  final TipoCxC tipo;
  final String codigoDocumento;
  final String numeroDocumento;
  final int numeroCuota;
  final int totalCuotas;
  final double montoTotal;
  final double montoPagado;
  final double saldo;
  final double interes;
  final String fechaEmision;
  final String? fechaVencimiento;
  final String codigoCliente;
  final String? descripcion;
  final bool pendiente;
  final String? referencia;

  const CuentaCobrar({
    required this.id,
    required this.codigoEmpresa,
    required this.numeroProvision,
    this.numeroProvisionOrigen,
    required this.tipo,
    required this.codigoDocumento,
    required this.numeroDocumento,
    required this.numeroCuota,
    required this.totalCuotas,
    required this.montoTotal,
    required this.montoPagado,
    required this.saldo,
    required this.interes,
    required this.fechaEmision,
    this.fechaVencimiento,
    required this.codigoCliente,
    this.descripcion,
    required this.pendiente,
    this.referencia,
  });

  factory CuentaCobrar.fromJson(Map<String, dynamic> j) => CuentaCobrar(
    id: j['id'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    numeroProvision: (j['numeroProvision'] as num).toInt(),
    numeroProvisionOrigen: j['numeroProvisionOrigen'] != null ? (j['numeroProvisionOrigen'] as num).toInt() : null,
    tipo: TipoCxC.values.byName(j['tipo'] as String),
    codigoDocumento: j['codigoDocumento'] as String,
    numeroDocumento: j['numeroDocumento'] as String,
    numeroCuota: (j['numeroCuota'] as num?)?.toInt() ?? 1,
    totalCuotas: (j['totalCuotas'] as num?)?.toInt() ?? 1,
    montoTotal: (j['montoTotal'] as num).toDouble(),
    montoPagado: (j['montoPagado'] as num).toDouble(),
    saldo: (j['saldo'] as num).toDouble(),
    interes: (j['interes'] as num).toDouble(),
    fechaEmision: j['fechaEmision'] as String,
    fechaVencimiento: j['fechaVencimiento'] as String?,
    codigoCliente: j['codigoCliente'] as String,
    descripcion: j['descripcion'] as String?,
    pendiente: j['pendiente'] as bool,
    referencia: j['referencia'] as String?,
  );
}

class Cobro {
  final String id;
  final String cuentaCobrarId;
  final String numeroRecibo;
  final String fecha;
  final String tipoPago;
  final String? numeroOperacion;
  final String? codigoBanco;
  final double monto;
  final String estado;

  const Cobro({
    required this.id,
    required this.cuentaCobrarId,
    required this.numeroRecibo,
    required this.fecha,
    required this.tipoPago,
    this.numeroOperacion,
    this.codigoBanco,
    required this.monto,
    required this.estado,
  });

  factory Cobro.fromJson(Map<String, dynamic> j) => Cobro(
    id: j['id'] as String,
    cuentaCobrarId: j['cuentaCobrarId'] as String,
    numeroRecibo: j['numeroRecibo'] as String,
    fecha: j['fecha'] as String,
    tipoPago: j['tipoPago'] as String,
    numeroOperacion: j['numeroOperacion'] as String?,
    codigoBanco: j['codigoBanco'] as String?,
    monto: (j['monto'] as num).toDouble(),
    estado: j['estado'] as String,
  );
}
