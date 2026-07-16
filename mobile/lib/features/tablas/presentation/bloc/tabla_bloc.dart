import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/datasources/tablas_remote_datasource.dart';
import '../../domain/entities/tabla_base.dart';
import 'tabla_event.dart';
import 'tabla_state.dart';

class TablaBloc<T extends TablaBase> extends Bloc<TablaEvent, TablaState> {
  final TablasRemoteDataSource _ds;
  final String _path;
  final T Function(Map<String, dynamic>) _fromJson;
  final Map<String, dynamic> Function(T) _toJson;

  TablaBloc({
    required TablasRemoteDataSource ds,
    required String path,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
  })  : _ds = ds,
        _path = path,
        _fromJson = fromJson,
        _toJson = toJson,
        super(TablaInitial()) {
    on<TablaLoad>(_onLoad);
    on<TablaSave>(_onSave);
    on<TablaToggle>(_onToggle);
  }

  Future<void> _onLoad(TablaLoad event, Emitter<TablaState> emit) async {
    emit(TablaLoading());
    try {
      final list = await _ds.list(_path, q: event.q, activo: event.activo);
      emit(TablaLoaded<T>(list.map(_fromJson).toList()));
    } on ApiException catch (e) { emit(TablaError(e.message)); }
  }

  Future<void> _onSave(TablaSave event, Emitter<TablaState> emit) async {
    emit(TablaSaving());
    try {
      final raw = await _ds.save(_path, event.data, id: event.id);
      emit(TablaSaved<T>(_fromJson(raw)));
    } on ApiException catch (e) { emit(TablaError(e.message)); }
  }

  Future<void> _onToggle(TablaToggle event, Emitter<TablaState> emit) async {
    emit(TablaSaving());
    try {
      final raw = await _ds.toggle(_path, event.id);
      emit(TablaSaved<T>(_fromJson(raw)));
    } on ApiException catch (e) { emit(TablaError(e.message)); }
  }
}
