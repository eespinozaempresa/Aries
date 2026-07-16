import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/tipo_cambio_repository.dart';
import 'tipo_cambio_event.dart';
import 'tipo_cambio_state.dart';

class TipoCambioBloc extends Bloc<TipoCambioEvent, TipoCambioState> {
  final TipoCambioRepository _repo;

  TipoCambioBloc(this._repo) : super(TipoCambioInitial()) {
    on<TipoCambioCheckHoy>(_onCheckHoy);
    on<TipoCambioRegistrar>(_onRegistrar);
  }

  Future<void> _onCheckHoy(
    TipoCambioCheckHoy event,
    Emitter<TipoCambioState> emit,
  ) async {
    emit(TipoCambioLoading());
    final result = await _repo.getHoy();
    result.fold(
      (error) => emit(TipoCambioError(error.message)),
      (data) => data != null
          ? emit(TipoCambioYaRegistrado(data))
          : emit(TipoCambioPendiente()),
    );
  }

  Future<void> _onRegistrar(
    TipoCambioRegistrar event,
    Emitter<TipoCambioState> emit,
  ) async {
    emit(TipoCambioLoading());
    final result = await _repo.registrar(event.tipoCambio);
    result.fold(
      (error) => emit(TipoCambioError(error.message)),
      (data) => emit(TipoCambioRegistradoExitoso(data)),
    );
  }
}
