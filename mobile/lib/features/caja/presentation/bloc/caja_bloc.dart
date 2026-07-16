import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/datasources/caja_remote_datasource.dart';
import '../../domain/entities/sesion_caja.dart';

// ── Events ───────────────────────────────────────────────────────────────────
sealed class CajaEvent {}
class CajaLoad extends CajaEvent { final bool reset; CajaLoad({this.reset = false}); }
class CajaLoadReporte extends CajaEvent { final String id; CajaLoadReporte(this.id); }
class CajaAbrir extends CajaEvent {
  final String codigoCaja;
  final double montoApertura;
  CajaAbrir({required this.codigoCaja, required this.montoApertura});
}
class CajaCerrar extends CajaEvent {
  final String id;
  final double montosCierre;
  CajaCerrar({required this.id, required this.montosCierre});
}
class CajaRegistrarMovimiento extends CajaEvent {
  final String sesionCajaId, tipo, concepto, fecha;
  final double monto;
  final String? referencia;
  CajaRegistrarMovimiento({
    required this.sesionCajaId, required this.tipo, required this.concepto,
    required this.monto, required this.fecha, this.referencia,
  });
}

// ── States ───────────────────────────────────────────────────────────────────
sealed class CajaState {}
class CajaInitial extends CajaState {}
class CajaLoading extends CajaState {}
class CajaListLoaded extends CajaState {
  final List<SesionCaja> items;
  final int currentPage, lastPage;
  CajaListLoaded(this.items, this.currentPage, this.lastPage);
}
class CajaReporteLoaded extends CajaState { final ReporteCaja reporte; CajaReporteLoaded(this.reporte); }
class CajaSaving extends CajaState {}
class CajaAbierta extends CajaState { final SesionCaja sesion; CajaAbierta(this.sesion); }
class CajaCerrada extends CajaState { final SesionCaja sesion; CajaCerrada(this.sesion); }
class CajaMovimientoRegistrado extends CajaState { final MovimientoCaja movimiento; CajaMovimientoRegistrado(this.movimiento); }
class CajaError extends CajaState { final String message; CajaError(this.message); }

// ── BLoC ─────────────────────────────────────────────────────────────────────
class CajaBloc extends Bloc<CajaEvent, CajaState> {
  final CajaRemoteDataSource _ds;
  List<SesionCaja> _items = [];
  int _currentPage = 1, _lastPage = 1;

  CajaBloc(this._ds) : super(CajaInitial()) {
    on<CajaLoad>(_onLoad);
    on<CajaLoadReporte>(_onLoadReporte);
    on<CajaAbrir>(_onAbrir);
    on<CajaCerrar>(_onCerrar);
    on<CajaRegistrarMovimiento>(_onRegistrarMovimiento);
  }

  Future<void> _onLoad(CajaLoad e, Emitter<CajaState> emit) async {
    if (e.reset) { _items = []; _currentPage = 1; _lastPage = 1; }
    if (_currentPage > _lastPage && _items.isNotEmpty) return;
    emit(CajaLoading());
    try {
      final res = await _ds.list(page: _currentPage);
      final newItems = (res['data'] as List).map((j) => SesionCaja.fromJson(j as Map<String, dynamic>)).toList();
      _items = e.reset ? newItems : [..._items, ...newItems];
      _lastPage = (res['lastPage'] as num).toInt();
      emit(CajaListLoaded(List.unmodifiable(_items), _currentPage, _lastPage));
      _currentPage++;
    } on ApiException catch (ex) {
      emit(CajaError(ex.message));
    }
  }

  Future<void> _onLoadReporte(CajaLoadReporte e, Emitter<CajaState> emit) async {
    emit(CajaLoading());
    try {
      final json = await _ds.reporte(e.id);
      emit(CajaReporteLoaded(ReporteCaja.fromJson(json)));
    } on ApiException catch (ex) {
      emit(CajaError(ex.message));
    }
  }

  Future<void> _onAbrir(CajaAbrir e, Emitter<CajaState> emit) async {
    emit(CajaSaving());
    try {
      final json = await _ds.abrir(codigoCaja: e.codigoCaja, montoApertura: e.montoApertura);
      emit(CajaAbierta(SesionCaja.fromJson(json)));
    } on ApiException catch (ex) {
      emit(CajaError(ex.message));
    }
  }

  Future<void> _onCerrar(CajaCerrar e, Emitter<CajaState> emit) async {
    emit(CajaSaving());
    try {
      final json = await _ds.cerrar(id: e.id, montosCierre: e.montosCierre);
      emit(CajaCerrada(SesionCaja.fromJson(json)));
    } on ApiException catch (ex) {
      emit(CajaError(ex.message));
    }
  }

  Future<void> _onRegistrarMovimiento(CajaRegistrarMovimiento e, Emitter<CajaState> emit) async {
    emit(CajaSaving());
    try {
      final json = await _ds.registrarMovimiento(
        sesionCajaId: e.sesionCajaId,
        tipo: e.tipo,
        concepto: e.concepto,
        monto: e.monto,
        fecha: e.fecha,
        referencia: e.referencia,
      );
      emit(CajaMovimientoRegistrado(MovimientoCaja.fromJson(json)));
    } on ApiException catch (ex) {
      emit(CajaError(ex.message));
    }
  }
}
