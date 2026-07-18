import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/datasources/compras_remote_datasource.dart';
import '../../data/models/compra_model.dart';
import '../../domain/entities/compra.dart';
import 'compra_event.dart';
import 'compra_state.dart';

class CompraBloc extends Bloc<CompraEvent, CompraState> {
  final ComprasRemoteDataSource _ds;

  String? _lastProv;
  String? _lastAlm;
  String? _lastDesde;
  String? _lastHasta;
  int _page = 1;
  int _lastPage = 1;
  List<Compra> _items = [];

  CompraBloc(this._ds) : super(CompraInitial()) {
    on<CompraListLoad>(_onLoad);
    on<CompraListLoadMore>(_onMore);
    on<CompraRegistrar>(_onRegistrar);
    on<CompraAnular>(_onAnular);
    on<CompraLoadDetail>(_onDetail);
    on<CompraEliminar>(_onEliminar);
  }

  Future<void> _onLoad(CompraListLoad e, Emitter<CompraState> emit) async {
    _lastProv = e.proveedor; _lastAlm = e.almacen;
    _lastDesde = e.desde;   _lastHasta = e.hasta;
    _page = 1; _items = [];
    emit(CompraListLoading());
    try {
      final data = await _ds.list(_params(1));
      _items = List<Compra>.from((data['data'] as List).map((e) => CompraModel.fromJson(e)));
      _lastPage = data['lastPage'] as int;
      emit(CompraListLoaded(items: _items, total: data['total'] as int, page: 1, lastPage: _lastPage));
    } on ApiException catch (e) { emit(CompraError(e.message)); }
  }

  Future<void> _onMore(CompraListLoadMore _, Emitter<CompraState> emit) async {
    if (_page >= _lastPage) return;
    final next = _page + 1;
    emit(CompraListLoading(previous: _items));
    try {
      final data = await _ds.list(_params(next));
      _page = next;
      _items = [..._items, ...List<Compra>.from((data['data'] as List).map((e) => CompraModel.fromJson(e)))];
      emit(CompraListLoaded(items: _items, total: data['total'] as int, page: next, lastPage: _lastPage));
    } on ApiException catch (e) { emit(CompraError(e.message)); }
  }

  Future<void> _onRegistrar(CompraRegistrar e, Emitter<CompraState> emit) async {
    emit(CompraSaving());
    try {
      final c = await _ds.registrar(e.data);
      emit(CompraSaved(c));
    } on ApiException catch (e) { emit(CompraError(e.message)); }
  }

  Future<void> _onAnular(CompraAnular e, Emitter<CompraState> emit) async {
    emit(CompraSaving());
    try {
      final c = await _ds.anular(e.id);
      emit(CompraAnulado(c));
    } on ApiException catch (e) { emit(CompraError(e.message)); }
  }

  Future<void> _onDetail(CompraLoadDetail e, Emitter<CompraState> emit) async {
    emit(CompraDetailLoading());
    try {
      final c = await _ds.findById(e.id);
      emit(CompraDetailLoaded(c));
    } on ApiException catch (e) { emit(CompraError(e.message)); }
  }

  Future<void> _onEliminar(CompraEliminar e, Emitter<CompraState> emit) async {
    emit(CompraSaving());
    try {
      await _ds.eliminar(e.id);
      emit(CompraEliminada(e.id));
    } on ApiException catch (e) { emit(CompraError(e.message)); }
  }

  Map<String, dynamic> _params(int page) => {
    if (_lastProv != null) 'proveedor': _lastProv,
    if (_lastAlm  != null) 'almacen':   _lastAlm,
    if (_lastDesde != null) 'desde':    _lastDesde,
    if (_lastHasta != null) 'hasta':    _lastHasta,
    'page': page.toString(),
  };
}
