import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/datasources/ventas_remote_datasource.dart';
import '../../data/models/venta_model.dart';
import '../../domain/entities/venta.dart';
import 'venta_event.dart';
import 'venta_state.dart';

class VentaBloc extends Bloc<VentaEvent, VentaState> {
  final VentasRemoteDataSource _ds;
  String? _lastCliente, _lastAlm, _lastDesde, _lastHasta;
  int _page = 1, _lastPage = 1;
  List<Venta> _items = [];

  VentaBloc(this._ds) : super(VentaInitial()) {
    on<VentaListLoad>(_onLoad);
    on<VentaListLoadMore>(_onMore);
    on<VentaRegistrar>(_onRegistrar);
    on<VentaAnular>(_onAnular);
    on<VentaLoadDetail>(_onDetail);
  }

  Map<String, dynamic> _params(int page) => {
    if (_lastCliente != null) 'cliente': _lastCliente,
    if (_lastAlm != null) 'almacen': _lastAlm,
    if (_lastDesde != null) 'desde': _lastDesde,
    if (_lastHasta != null) 'hasta': _lastHasta,
    'page': page.toString(),
  };

  Future<void> _onLoad(VentaListLoad e, Emitter<VentaState> emit) async {
    _lastCliente = e.cliente; _lastAlm = e.almacen;
    _lastDesde = e.desde; _lastHasta = e.hasta;
    _page = 1; _items = [];
    emit(VentaListLoading());
    try {
      final data = await _ds.list(_params(1));
      _items = List<Venta>.from((data['data'] as List).map((e) => VentaModel.fromJson(e)));
      _lastPage = data['lastPage'] as int;
      emit(VentaListLoaded(items: _items, total: data['total'] as int, page: 1, lastPage: _lastPage));
    } on ApiException catch (e) { emit(VentaError(e.message)); }
  }

  Future<void> _onMore(VentaListLoadMore _, Emitter<VentaState> emit) async {
    if (_page >= _lastPage) return;
    final next = _page + 1;
    emit(VentaListLoading(previous: _items));
    try {
      final data = await _ds.list(_params(next));
      _page = next;
      _items = [..._items, ...List<Venta>.from((data['data'] as List).map((e) => VentaModel.fromJson(e)))];
      emit(VentaListLoaded(items: _items, total: data['total'] as int, page: next, lastPage: _lastPage));
    } on ApiException catch (e) { emit(VentaError(e.message)); }
  }

  Future<void> _onRegistrar(VentaRegistrar e, Emitter<VentaState> emit) async {
    emit(VentaSaving());
    try { emit(VentaSaved(await _ds.registrar(e.data))); }
    on ApiException catch (e) { emit(VentaError(e.message)); }
  }

  Future<void> _onAnular(VentaAnular e, Emitter<VentaState> emit) async {
    emit(VentaSaving());
    try { emit(VentaAnulada(await _ds.anular(e.id))); }
    on ApiException catch (e) { emit(VentaError(e.message)); }
  }

  Future<void> _onDetail(VentaLoadDetail e, Emitter<VentaState> emit) async {
    emit(VentaDetailLoading());
    try { emit(VentaDetailLoaded(await _ds.findById(e.id))); }
    on ApiException catch (e) { emit(VentaError(e.message)); }
  }
}
