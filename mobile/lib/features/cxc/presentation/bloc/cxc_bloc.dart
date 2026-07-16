import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/datasources/cxc_remote_datasource.dart';
import '../../domain/entities/cuenta_cobrar.dart';

// ── Events ──────────────────────────────────────────────────────────────────
sealed class CxCEvent {}
class CxCLoad extends CxCEvent {
  final bool reset;
  final bool? pendiente;
  final String? codigoCliente;
  CxCLoad({this.reset = false, this.pendiente, this.codigoCliente});
}
class CxCLoadDetail extends CxCEvent { final String id; CxCLoadDetail(this.id); }
class CxCRegistrarCobro extends CxCEvent {
  final String cuentaCobrarId, numeroRecibo, fecha, tipoPago;
  final double monto;
  final String? numeroOperacion, codigoBanco;
  CxCRegistrarCobro({
    required this.cuentaCobrarId, required this.numeroRecibo,
    required this.fecha, required this.tipoPago, required this.monto,
    this.numeroOperacion, this.codigoBanco,
  });
}
class CxCRenovar extends CxCEvent {
  final String id, nuevaFechaVencimiento, codigoDocumento, numeroDocumento;
  final double? interes;
  CxCRenovar({
    required this.id, required this.nuevaFechaVencimiento,
    required this.codigoDocumento, required this.numeroDocumento, this.interes,
  });
}

// ── States ───────────────────────────────────────────────────────────────────
sealed class CxCState {}
class CxCInitial extends CxCState {}
class CxCLoading extends CxCState {}
class CxCLoaded extends CxCState {
  final List<CuentaCobrar> items;
  final int currentPage, lastPage;
  CxCLoaded(this.items, this.currentPage, this.lastPage);
}
class CxCDetailLoaded extends CxCState {
  final CuentaCobrar cxc;
  final List<Cobro> cobros;
  CxCDetailLoaded(this.cxc, this.cobros);
}
class CxCSaving extends CxCState {}
class CxCCobroRegistrado extends CxCState { final Cobro cobro; CxCCobroRegistrado(this.cobro); }
class CxCRenovada extends CxCState { final CuentaCobrar nueva; CxCRenovada(this.nueva); }
class CxCError extends CxCState { final String message; CxCError(this.message); }

// ── BLoC ─────────────────────────────────────────────────────────────────────
class CxCBloc extends Bloc<CxCEvent, CxCState> {
  final CxCRemoteDataSource _ds;
  List<CuentaCobrar> _items = [];
  int _currentPage = 1, _lastPage = 1;

  CxCBloc(this._ds) : super(CxCInitial()) {
    on<CxCLoad>(_onLoad);
    on<CxCLoadDetail>(_onLoadDetail);
    on<CxCRegistrarCobro>(_onRegistrarCobro);
    on<CxCRenovar>(_onRenovar);
  }

  Future<void> _onLoad(CxCLoad e, Emitter<CxCState> emit) async {
    if (e.reset) { _items = []; _currentPage = 1; _lastPage = 1; }
    if (_currentPage > _lastPage && _items.isNotEmpty) return;
    emit(CxCLoading());
    try {
      final res = await _ds.list(
        codigoCliente: e.codigoCliente,
        pendiente: e.pendiente,
        page: _currentPage,
      );
      final newItems = (res['data'] as List).map((j) => CuentaCobrar.fromJson(j as Map<String, dynamic>)).toList();
      _items = e.reset ? newItems : [..._items, ...newItems];
      _lastPage = (res['lastPage'] as num).toInt();
      emit(CxCLoaded(List.unmodifiable(_items), _currentPage, _lastPage));
      _currentPage++;
    } on ApiException catch (ex) {
      emit(CxCError(ex.message));
    }
  }

  Future<void> _onLoadDetail(CxCLoadDetail e, Emitter<CxCState> emit) async {
    emit(CxCLoading());
    try {
      final cxcJson = await _ds.findById(e.id);
      final cobrosJson = await _ds.getCobros(e.id);
      emit(CxCDetailLoaded(
        CuentaCobrar.fromJson(cxcJson),
        cobrosJson.map((j) => Cobro.fromJson(j as Map<String, dynamic>)).toList(),
      ));
    } on ApiException catch (ex) {
      emit(CxCError(ex.message));
    }
  }

  Future<void> _onRegistrarCobro(CxCRegistrarCobro e, Emitter<CxCState> emit) async {
    emit(CxCSaving());
    try {
      final cobro = await _ds.registrarCobro(
        cuentaCobrarId: e.cuentaCobrarId,
        numeroRecibo: e.numeroRecibo,
        fecha: e.fecha,
        tipoPago: e.tipoPago,
        monto: e.monto,
        numeroOperacion: e.numeroOperacion,
        codigoBanco: e.codigoBanco,
      );
      emit(CxCCobroRegistrado(Cobro.fromJson(cobro)));
    } on ApiException catch (ex) {
      emit(CxCError(ex.message));
    }
  }

  Future<void> _onRenovar(CxCRenovar e, Emitter<CxCState> emit) async {
    emit(CxCSaving());
    try {
      final nueva = await _ds.renovar(
        id: e.id,
        nuevaFechaVencimiento: e.nuevaFechaVencimiento,
        interes: e.interes,
        codigoDocumento: e.codigoDocumento,
        numeroDocumento: e.numeroDocumento,
      );
      emit(CxCRenovada(CuentaCobrar.fromJson(nueva)));
    } on ApiException catch (ex) {
      emit(CxCError(ex.message));
    }
  }
}
