import '../../domain/entities/movimiento.dart';

sealed class MovimientoEvent {}

class MovimientoListLoad extends MovimientoEvent {
  final TipoMovimiento? tipo;
  final String? codigoAlmacen;
  final String? desde;
  final String? hasta;
  final bool? soloAnulados;
  final int page;
  MovimientoListLoad({this.tipo, this.codigoAlmacen, this.desde, this.hasta, this.soloAnulados, this.page = 1});
}

class MovimientoListLoadMore extends MovimientoEvent {}

class MovimientoRegistrar extends MovimientoEvent {
  final String codigoDocumento;
  final String serie;
  final String fecha;
  final TipoMovimiento tipo;
  final String codigoAlmacenOrigen;
  final String? codigoAlmacenDest;
  final String? observacion;
  final String? concepto;
  final List<Map<String, dynamic>> lineas;

  MovimientoRegistrar({
    required this.codigoDocumento,
    this.serie = '0001',
    required this.fecha,
    required this.tipo,
    required this.codigoAlmacenOrigen,
    this.codigoAlmacenDest,
    this.observacion,
    this.concepto,
    required this.lineas,
  });
}

class MovimientoAnular extends MovimientoEvent {
  final String id;
  MovimientoAnular(this.id);
}

class MovimientoLoadDetail extends MovimientoEvent {
  final String id;
  MovimientoLoadDetail(this.id);
}

class MovimientoEliminar extends MovimientoEvent {
  final String id;
  MovimientoEliminar(this.id);
}
