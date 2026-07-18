import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/tipo_cambio.dart';
import '../../data/models/tipo_cambio_model.dart';
import '../../domain/repositories/tipo_cambio_repository.dart';
import 'tipo_cambio_event.dart';
import 'tipo_cambio_state.dart';

class TipoCambioBloc extends Bloc<TipoCambioEvent, TipoCambioState> {
  final TipoCambioRepository _repo;

  int _currentPage = 1;
  int _lastPage = 1;
  List<TipoCambio> _items = [];

  TipoCambioBloc(this._repo) : super(TipoCambioInitial()) {
    on<TipoCambioCheckHoy>(_onCheckHoy);
    on<TipoCambioRegistrar>(_onRegistrar);
    on<TipoCambioListLoad>(_onListLoad);
    on<TipoCambioListLoadMore>(_onListLoadMore);
    on<TipoCambioActualizar>(_onActualizar);
    on<TipoCambioEliminar>(_onEliminar);
  }

  Future<void> _onCheckHoy(TipoCambioCheckHoy event, Emitter<TipoCambioState> emit) async {
    emit(TipoCambioLoading());
    final result = await _repo.getHoy();
    result.fold(
      (e) => emit(TipoCambioError(e.message)),
      (data) => data != null ? emit(TipoCambioYaRegistrado(data)) : emit(TipoCambioPendiente()),
    );
  }

  Future<void> _onRegistrar(TipoCambioRegistrar event, Emitter<TipoCambioState> emit) async {
    emit(TipoCambioLoading());
    final result = await _repo.registrar(event.tipoCambio);
    result.fold(
      (e) => emit(TipoCambioError(e.message)),
      (data) => emit(TipoCambioRegistradoExitoso(data)),
    );
  }

  Future<void> _onListLoad(TipoCambioListLoad event, Emitter<TipoCambioState> emit) async {
    _currentPage = 1;
    _items = [];
    emit(TipoCambioListLoading());
    final result = await _repo.list(page: 1);
    result.fold(
      (e) => emit(TipoCambioError(e.message)),
      (data) {
        _items = List<TipoCambio>.from(
          (data['data'] as List).map((e) => TipoCambioModel.fromJson(e as Map<String, dynamic>)),
        );
        _lastPage = data['lastPage'] as int;
        emit(TipoCambioListLoaded(items: _items, total: data['total'] as int, page: 1, lastPage: _lastPage));
      },
    );
  }

  Future<void> _onListLoadMore(TipoCambioListLoadMore event, Emitter<TipoCambioState> emit) async {
    if (_currentPage >= _lastPage) return;
    final next = _currentPage + 1;
    emit(TipoCambioListLoading(previous: _items));
    final result = await _repo.list(page: next);
    result.fold(
      (e) => emit(TipoCambioError(e.message)),
      (data) {
        _currentPage = next;
        _items = [
          ..._items,
          ...List<TipoCambio>.from(
            (data['data'] as List).map((e) => TipoCambioModel.fromJson(e as Map<String, dynamic>)),
          ),
        ];
        emit(TipoCambioListLoaded(items: _items, total: data['total'] as int, page: next, lastPage: _lastPage));
      },
    );
  }

  Future<void> _onActualizar(TipoCambioActualizar event, Emitter<TipoCambioState> emit) async {
    emit(TipoCambioListLoading(previous: _items));
    final result = await _repo.update(event.id, event.tipoCambio);
    result.fold(
      (e) => emit(TipoCambioError(e.message)),
      (updated) {
        _items = _items.map((i) => i.id == updated.id ? updated : i).toList();
        emit(TipoCambioGuardado(updated));
      },
    );
  }

  Future<void> _onEliminar(TipoCambioEliminar event, Emitter<TipoCambioState> emit) async {
    emit(TipoCambioListLoading(previous: _items));
    final result = await _repo.delete(event.id);
    result.fold(
      (e) => emit(TipoCambioError(e.message)),
      (_) {
        _items = _items.where((i) => i.id != event.id).toList();
        emit(TipoCambioEliminado(event.id));
      },
    );
  }
}
