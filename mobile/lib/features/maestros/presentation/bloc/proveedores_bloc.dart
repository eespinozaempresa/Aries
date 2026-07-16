import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/proveedor.dart';
import '../../domain/repositories/proveedor_repository.dart';
import 'maestro_list_event.dart';
import 'maestro_list_state.dart';

class ProveedoresBloc extends Bloc<MaestroListEvent, MaestroListState<Proveedor>> {
  final ProveedorRepository _repo;
  String? _lastQ;

  ProveedoresBloc(this._repo) : super(MaestroListInitial()) {
    on<MaestroListLoad>(_onLoad);
    on<MaestroListRefresh>(_onRefresh);
  }

  Future<void> _onLoad(MaestroListLoad e, Emitter<MaestroListState<Proveedor>> emit) async {
    _lastQ = e.q;
    final prev = state is MaestroListLoaded<Proveedor>
        ? (state as MaestroListLoaded<Proveedor>).items
        : <Proveedor>[];
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

  Future<void> _onRefresh(MaestroListRefresh e, Emitter<MaestroListState<Proveedor>> emit) async {
    add(MaestroListLoad(q: e.q ?? _lastQ));
  }
}
