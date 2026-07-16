import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/articulo.dart';
import '../../domain/repositories/articulo_repository.dart';
import 'maestro_list_event.dart';
import 'maestro_list_state.dart';

class ArticulosBloc extends Bloc<MaestroListEvent, MaestroListState<Articulo>> {
  final ArticuloRepository _repo;
  String? _lastQ;
  bool? _lastActivo;

  ArticulosBloc(this._repo) : super(MaestroListInitial()) {
    on<MaestroListLoad>(_onLoad);
    on<MaestroListRefresh>(_onRefresh);
  }

  Future<void> _onLoad(MaestroListLoad e, Emitter<MaestroListState<Articulo>> emit) async {
    _lastQ = e.q;
    _lastActivo = e.activo;
    final prev = state is MaestroListLoaded<Articulo>
        ? (state as MaestroListLoaded<Articulo>).items
        : <Articulo>[];
    emit(MaestroListLoading(previousItems: e.page == 1 ? [] : prev));
    final result = await _repo.search(q: e.q, activo: e.activo, page: e.page);
    result.fold(
      (err) => emit(MaestroListError(err.message)),
      (page) {
        final items = e.page == 1 ? page.data : [...prev, ...page.data];
        emit(MaestroListLoaded(
          items: items,
          total: page.total,
          page: page.page,
          lastPage: page.lastPage,
        ));
      },
    );
  }

  Future<void> _onRefresh(MaestroListRefresh e, Emitter<MaestroListState<Articulo>> emit) async {
    add(MaestroListLoad(q: e.q ?? _lastQ, activo: _lastActivo));
  }
}
