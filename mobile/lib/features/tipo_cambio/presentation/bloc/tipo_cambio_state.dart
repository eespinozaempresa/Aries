import '../../domain/entities/tipo_cambio.dart';

sealed class TipoCambioState {}

class TipoCambioInitial extends TipoCambioState {}

class TipoCambioLoading extends TipoCambioState {}

class TipoCambioYaRegistrado extends TipoCambioState {
  final TipoCambio data;
  TipoCambioYaRegistrado(this.data);
}

class TipoCambioPendiente extends TipoCambioState {}

class TipoCambioRegistradoExitoso extends TipoCambioState {
  final TipoCambio data;
  TipoCambioRegistradoExitoso(this.data);
}

class TipoCambioError extends TipoCambioState {
  final String message;
  TipoCambioError(this.message);
}
