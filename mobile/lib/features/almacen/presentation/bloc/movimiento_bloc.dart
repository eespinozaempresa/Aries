import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/movimiento_repository.dart';
import '../../data/models/movimiento_model.dart';
import 'movimiento_event.dart';
import 'movimiento_state.dart';
import '../../domain/entities/movimiento.dart';

class MovimientoBloc extends Bloc<MovimientoEvent, MovimientoState> {
  final MovimientoRepository _repo;

  TipoMovimiento? _lastTipo;
  String? _lastAlmacen;
  String? _lastDesde;
  String? _lastHasta;
  bool? _lastAnulados;
  int _currentPage = 1;
  int _lastPage = 1;
  List<Movimiento> _items = [];

  MovimientoBloc(this._repo) : super(MovimientoInitial()) {
    on<MovimientoListLoad>(_onLoad);
    on<MovimientoListLoadMore>(_onLoadMore);
    on<MovimientoRegistrar>(_onRegistrar);
    on<MovimientoAnular>(_onAnular);
    on<MovimientoLoadDetail>(_onLoadDetail);
  }

  Future<void> _onLoad(MovimientoListLoad event, Emitter<MovimientoState> emit) async {
    _lastTipo    = event.tipo;
    _lastAlmacen = event.codigoAlmacen;
    _lastDesde   = event.desde;
    _lastHasta   = event.hasta;
    _lastAnulados = event.soloAnulados;
    _currentPage  = 1;
    _items        = [];

    emit(MovimientoListLoading());
    final result = await _repo.list(
      tipo: _lastTipo, codigoAlmacen: _lastAlmacen,
      desde: _lastDesde, hasta: _lastHasta,
      soloAnulados: _lastAnulados, page: 1,
    );
    result.fold(
      (e) => emit(MovimientoError(e.message)),
      (data) {
        _items    = List<Movimiento>.from((data['data'] as List).map((e) => MovimientoModel.fromJson(e as Map<String, dynamic>)));
        _lastPage = data['lastPage'] as int;
        emit(MovimientoListLoaded(items: _items, total: data['total'] as int, page: 1, lastPage: _lastPage));
      },
    );
  }

  Future<void> _onLoadMore(MovimientoListLoadMore event, Emitter<MovimientoState> emit) async {
    if (_currentPage >= _lastPage) return;
    final next = _currentPage + 1;
    emit(MovimientoListLoading(previous: _items));
    final result = await _repo.list(
      tipo: _lastTipo, codigoAlmacen: _lastAlmacen,
      desde: _lastDesde, hasta: _lastHasta,
      soloAnulados: _lastAnulados, page: next,
    );
    result.fold(
      (e) => emit(MovimientoError(e.message)),
      (data) {
        _currentPage = next;
        _items = [..._items, ...List<Movimiento>.from((data['data'] as List).map((e) => MovimientoModel.fromJson(e as Map<String, dynamic>)))];
        emit(MovimientoListLoaded(items: _items, total: data['total'] as int, page: next, lastPage: _lastPage));
      },
    );
  }

  Future<void> _onRegistrar(MovimientoRegistrar event, Emitter<MovimientoState> emit) async {
    emit(MovimientoSaving());
    final idResult = await _repo.registrar(
      codigoDocumento: event.codigoDocumento,
      serie: event.serie,
      fecha: event.fecha,
      tipo: event.tipo,
      codigoAlmacenOrigen: event.codigoAlmacenOrigen,
      codigoAlmacenDest: event.codigoAlmacenDest,
      observacion: event.observacion,
      concepto: event.concepto,
      lineas: event.lineas,
    );
    await idResult.fold(
      (e) async => emit(MovimientoError(e.message)),
      (id) async {
        final detailResult = await _repo.findById(id);
        detailResult.fold(
          (e) => emit(MovimientoError(e.message)),
          (mov) => emit(MovimientoSaved(mov)),
        );
      },
    );
  }

  Future<void> _onAnular(MovimientoAnular event, Emitter<MovimientoState> emit) async {
    emit(MovimientoSaving());
    final result = await _repo.anular(event.id);
    result.fold(
      (e) => emit(MovimientoError(e.message)),
      (mov) => emit(MovimientoAnulado(mov)),
    );
  }

  Future<void> _onLoadDetail(MovimientoLoadDetail event, Emitter<MovimientoState> emit) async {
    emit(MovimientoDetailLoading());
    final result = await _repo.findById(event.id);
    result.fold(
      (e) => emit(MovimientoError(e.message)),
      (mov) => emit(MovimientoDetailLoaded(mov)),
    );
  }
}
