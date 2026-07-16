import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';
import 'maestro_list_event.dart';
import 'maestro_list_state.dart';

class ClientesBloc extends Bloc<MaestroListEvent, MaestroListState<Cliente>> {
  final ClienteRepository _repo;
  String? _lastQ;

  ClientesBloc(this._repo) : super(MaestroListInitial()) {
    on<MaestroListLoad>(_onLoad);
    on<MaestroListRefresh>(_onRefresh);
  }

  Future<void> _onLoad(MaestroListLoad e, Emitter<MaestroListState<Cliente>> emit) async {
    _lastQ = e.q;
    final prev = state is MaestroListLoaded<Cliente>
        ? (state as MaestroListLoaded<Cliente>).items
        : <Cliente>[];
    emit(MaestroListLoading(previousItems: e.page == 1 ? [] : prev));
    final result = await _repo.search(q: e.q, activo: e.activo, page: e.page);
    result.fold(
      (err) => emit(MaestroListError(err.message)),
      (page) {
        final items = e.page == 1 ? page.data : [...prev, ...page.data];
        emit(MaestroListLoaded(
          items: items, total: page.total, page: page.page, lastPage: page.lastPage,
        ));
      },
    );
  }

  Future<void> _onRefresh(MaestroListRefresh e, Emitter<MaestroListState<Cliente>> emit) async {
    add(MaestroListLoad(q: e.q ?? _lastQ));
  }
}
