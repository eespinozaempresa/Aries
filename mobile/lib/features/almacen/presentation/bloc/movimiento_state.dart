import '../../domain/entities/movimiento.dart';

sealed class MovimientoState {}

class MovimientoInitial extends MovimientoState {}

class MovimientoListLoading extends MovimientoState {
  final List<Movimiento> previous;
  MovimientoListLoading({this.previous = const []});
}

class MovimientoListLoaded extends MovimientoState {
  final List<Movimiento> items;
  final int total;
  final int page;
  final int lastPage;
  MovimientoListLoaded({required this.items, required this.total, required this.page, required this.lastPage});
}

class MovimientoDetailLoading extends MovimientoState {}

class MovimientoDetailLoaded extends MovimientoState {
  final Movimiento movimiento;
  MovimientoDetailLoaded(this.movimiento);
}

class MovimientoSaving extends MovimientoState {}

class MovimientoSaved extends MovimientoState {
  final Movimiento movimiento;
  MovimientoSaved(this.movimiento);
}

class MovimientoAnulado extends MovimientoState {
  final Movimiento movimiento;
  MovimientoAnulado(this.movimiento);
}

class MovimientoEliminado extends MovimientoState {
  final String id;
  MovimientoEliminado(this.id);
}

class MovimientoError extends MovimientoState {
  final String message;
  MovimientoError(this.message);
}
