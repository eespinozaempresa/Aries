import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/formula.dart';
import '../../domain/repositories/formula_repository.dart';
import 'maestro_list_event.dart';
import 'maestro_list_state.dart';

class FormulasBloc extends Bloc<MaestroListEvent, MaestroListState<Formula>> {
  final FormulaRepository _repo;

  FormulasBloc(this._repo) : super(MaestroListInitial()) {
    on<MaestroListLoad>(_onLoad);
    on<MaestroListRefresh>(_onRefresh);
  }

  Future<void> _onLoad(MaestroListLoad e, Emitter<MaestroListState<Formula>> emit) async {
    emit(const MaestroListLoading());
    final result = await _repo.findAll(q: e.q, activo: e.activo);
    result.fold(
      (err) => emit(MaestroListError(err.message)),
      (list) => emit(MaestroListLoaded(items: list, total: list.length, page: 1, lastPage: 1)),
    );
  }

  Future<void> _onRefresh(MaestroListRefresh e, Emitter<MaestroListState<Formula>> emit) async {
    add(MaestroListLoad(q: e.q));
  }
}
