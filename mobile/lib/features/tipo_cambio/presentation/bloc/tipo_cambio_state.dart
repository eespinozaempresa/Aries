import '../../domain/entities/tipo_cambio.dart';

sealed class TipoCambioState {}

class TipoCambioInitial extends TipoCambioState {}

class TipoCambioLoading extends TipoCambioState {}

class TipoCambioRegistradoExitoso extends TipoCambioState {
  final TipoCambio data;
  TipoCambioRegistradoExitoso(this.data);
}

class TipoCambioListLoading extends TipoCambioState {
  final List<TipoCambio> previous;
  TipoCambioListLoading({this.previous = const []});
}

class TipoCambioListLoaded extends TipoCambioState {
  final List<TipoCambio> items;
  final int total;
  final int page;
  final int lastPage;
  TipoCambioListLoaded({required this.items, required this.total, required this.page, required this.lastPage});
}

class TipoCambioGuardado extends TipoCambioState {
  final TipoCambio data;
  TipoCambioGuardado(this.data);
}

class TipoCambioEliminado extends TipoCambioState {
  final String id;
  TipoCambioEliminado(this.id);
}

class TipoCambioError extends TipoCambioState {
  final String message;
  TipoCambioError(this.message);
}
