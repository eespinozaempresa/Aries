import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/datasources/cxp_remote_datasource.dart';
import '../../domain/entities/cuenta_pagar.dart';

// ── Events ──────────────────────────────────────────────────────────────────
sealed class CxPEvent {}
class CxPLoad extends CxPEvent {
  final bool reset;
  final bool? pendiente;
  final String? codigoProveedor;
  CxPLoad({this.reset = false, this.pendiente, this.codigoProveedor});
}
class CxPLoadDetail extends CxPEvent { final String id; CxPLoadDetail(this.id); }
class CxPRegistrarPago extends CxPEvent {
  final String cuentaPagarId, numeroVoucher, fecha, tipoPago;
  final double monto;
  final String? numeroOperacion, codigoBanco;
  CxPRegistrarPago({
    required this.cuentaPagarId, required this.numeroVoucher,
    required this.fecha, required this.tipoPago, required this.monto,
    this.numeroOperacion, this.codigoBanco,
  });
}
class CxPRenovar extends CxPEvent {
  final String id;
  final List<Map<String, dynamic>> cuotas;
  CxPRenovar({required this.id, required this.cuotas});
}

// ── States ───────────────────────────────────────────────────────────────────
sealed class CxPState {}
class CxPInitial extends CxPState {}
class CxPLoading extends CxPState {}
class CxPLoaded extends CxPState {
  final List<CuentaPagar> items;
  final int currentPage, lastPage;
  CxPLoaded(this.items, this.currentPage, this.lastPage);
}
class CxPDetailLoaded extends CxPState {
  final CuentaPagar cxp;
  final List<Pago> pagos;
  CxPDetailLoaded(this.cxp, this.pagos);
}
class CxPSaving extends CxPState {}
class CxPPagoRegistrado extends CxPState { final Pago pago; CxPPagoRegistrado(this.pago); }
class CxPRenovada extends CxPState { final List<CuentaPagar> nuevas; CxPRenovada(this.nuevas); }
class CxPError extends CxPState { final String message; CxPError(this.message); }

// ── BLoC ─────────────────────────────────────────────────────────────────────
class CxPBloc extends Bloc<CxPEvent, CxPState> {
  final CxPRemoteDataSource _ds;
  List<CuentaPagar> _items = [];
  int _currentPage = 1, _lastPage = 1;

  CxPBloc(this._ds) : super(CxPInitial()) {
    on<CxPLoad>(_onLoad);
    on<CxPLoadDetail>(_onLoadDetail);
    on<CxPRegistrarPago>(_onRegistrarPago);
    on<CxPRenovar>(_onRenovar);
  }

  Future<void> _onLoad(CxPLoad e, Emitter<CxPState> emit) async {
    if (e.reset) { _items = []; _currentPage = 1; _lastPage = 1; }
    if (_currentPage > _lastPage && _items.isNotEmpty) return;
    emit(CxPLoading());
    try {
      final res = await _ds.list(
        codigoProveedor: e.codigoProveedor,
        pendiente: e.pendiente,
        page: _currentPage,
      );
      final newItems = (res['data'] as List).map((j) => CuentaPagar.fromJson(j as Map<String, dynamic>)).toList();
      _items = e.reset ? newItems : [..._items, ...newItems];
      _lastPage = (res['lastPage'] as num).toInt();
      emit(CxPLoaded(List.unmodifiable(_items), _currentPage, _lastPage));
      _currentPage++;
    } on ApiException catch (ex) {
      emit(CxPError(ex.message));
    }
  }

  Future<void> _onLoadDetail(CxPLoadDetail e, Emitter<CxPState> emit) async {
    emit(CxPLoading());
    try {
      final cxpJson = await _ds.findById(e.id);
      final pagosJson = await _ds.getPagos(e.id);
      emit(CxPDetailLoaded(
        CuentaPagar.fromJson(cxpJson),
        pagosJson.map((j) => Pago.fromJson(j as Map<String, dynamic>)).toList(),
      ));
    } on ApiException catch (ex) {
      emit(CxPError(ex.message));
    }
  }

  Future<void> _onRegistrarPago(CxPRegistrarPago e, Emitter<CxPState> emit) async {
    emit(CxPSaving());
    try {
      final pago = await _ds.registrarPago(
        cuentaPagarId: e.cuentaPagarId,
        numeroVoucher: e.numeroVoucher,
        fecha: e.fecha,
        tipoPago: e.tipoPago,
        monto: e.monto,
        numeroOperacion: e.numeroOperacion,
        codigoBanco: e.codigoBanco,
      );
      emit(CxPPagoRegistrado(Pago.fromJson(pago)));
    } on ApiException catch (ex) {
      emit(CxPError(ex.message));
    }
  }

  Future<void> _onRenovar(CxPRenovar e, Emitter<CxPState> emit) async {
    emit(CxPSaving());
    try {
      final nuevasList = await _ds.renovar(id: e.id, cuotas: e.cuotas);
      emit(CxPRenovada(
        nuevasList.map((j) => CuentaPagar.fromJson(j as Map<String, dynamic>)).toList(),
      ));
    } on ApiException catch (ex) {
      emit(CxPError(ex.message));
    }
  }
}
