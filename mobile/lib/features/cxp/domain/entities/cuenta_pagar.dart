enum TipoCxP { COMPRA, RENOVACION }

class CuentaPagar {
  final String id;
  final String codigoEmpresa;
  final int numeroProvision;
  final int? numeroProvisionOrigen;
  final TipoCxP tipo;
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
  final String codigoProveedor;
  final String? razonSocialProveedor;
  final String? abreviaturaDocumento;
  final String? descripcion;
  final bool pendiente;
  final String? referencia;

  const CuentaPagar({
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
    required this.codigoProveedor,
    this.razonSocialProveedor,
    this.abreviaturaDocumento,
    this.descripcion,
    required this.pendiente,
    this.referencia,
  });

  factory CuentaPagar.fromJson(Map<String, dynamic> j) => CuentaPagar(
    id: j['id'] as String,
    codigoEmpresa: j['codigoEmpresa'] as String,
    numeroProvision: (j['numeroProvision'] as num).toInt(),
    numeroProvisionOrigen: j['numeroProvisionOrigen'] != null ? (j['numeroProvisionOrigen'] as num).toInt() : null,
    tipo: TipoCxP.values.byName(j['tipo'] as String),
    codigoDocumento: j['codigoDocumento'] as String,
    numeroDocumento: j['numeroDocumento'] as String,
    numeroCuota: (j['numeroCuota'] as num).toInt(),
    totalCuotas: (j['totalCuotas'] as num).toInt(),
    montoTotal: (j['montoTotal'] as num).toDouble(),
    montoPagado: (j['montoPagado'] as num).toDouble(),
    saldo: (j['saldo'] as num).toDouble(),
    interes: (j['interes'] as num).toDouble(),
    fechaEmision: j['fechaEmision'] as String,
    fechaVencimiento: j['fechaVencimiento'] as String?,
    codigoProveedor: j['codigoProveedor'] as String,
    razonSocialProveedor: j['razonSocialProveedor'] as String?,
    abreviaturaDocumento: j['abreviaturaDocumento'] as String?,
    descripcion: j['descripcion'] as String?,
    pendiente: j['pendiente'] as bool,
    referencia: j['referencia'] as String?,
  );
}

class Pago {
  final String id;
  final String cuentaPagarId;
  final String numeroVoucher;
  final String fecha;
  final String tipoPago;
  final String? numeroOperacion;
  final String? codigoBanco;
  final double monto;
  final String estado;

  const Pago({
    required this.id,
    required this.cuentaPagarId,
    required this.numeroVoucher,
    required this.fecha,
    required this.tipoPago,
    this.numeroOperacion,
    this.codigoBanco,
    required this.monto,
    required this.estado,
  });

  factory Pago.fromJson(Map<String, dynamic> j) => Pago(
    id: j['id'] as String,
    cuentaPagarId: j['cuentaPagarId'] as String,
    numeroVoucher: j['numeroVoucher'] as String,
    fecha: j['fecha'] as String,
    tipoPago: j['tipoPago'] as String,
    numeroOperacion: j['numeroOperacion'] as String?,
    codigoBanco: j['codigoBanco'] as String?,
    monto: (j['monto'] as num).toDouble(),
    estado: j['estado'] as String,
  );
}
