import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../tipo_cambio/domain/repositories/tipo_cambio_repository.dart';
import '../../../auth/domain/entities/empresa_opcion.dart';
import '../../seleccionar_empresa_args.dart';
import 'seleccionar_empresa_event.dart';
import 'seleccionar_empresa_state.dart';

class SeleccionarEmpresaBloc extends Bloc<SeleccionarEmpresaEvent, SeleccionarEmpresaState> {
  final AuthRepository _authRepo;
  final TipoCambioRepository _tipoCambioRepo;
  final SeleccionarEmpresaArgs args;

  List<EmpresaOpcion> _empresas = [];
  EmpresaOpcion? _seleccionada;

  SeleccionarEmpresaBloc({
    required AuthRepository authRepo,
    required TipoCambioRepository tipoCambioRepo,
    required this.args,
  })  : _authRepo = authRepo,
        _tipoCambioRepo = tipoCambioRepo,
        super(SeleccionarEmpresaCargando()) {
    on<SeleccionarEmpresaIniciar>(_onIniciar);
    on<SeleccionarEmpresaElegir>(_onElegir);
    on<SeleccionarEmpresaConfirmar>(_onConfirmar);
  }

  bool get _esPostLogin => args.modo == SeleccionarEmpresaModo.postLogin;

  Future<void> _onIniciar(
    SeleccionarEmpresaIniciar event,
    Emitter<SeleccionarEmpresaState> emit,
  ) async {
    emit(SeleccionarEmpresaCargando());

    if (_esPostLogin) {
      _empresas = args.empresas!;
    } else {
      final result = await _authRepo.misEmpresas();
      if (result.isLeft()) {
        emit(SeleccionarEmpresaErrorInicial(result.fold((f) => f.message, (_) => '')));
        return;
      }
      _empresas = result.fold((_) => const [], (list) => list);
    }

    if (_empresas.isEmpty) {
      emit(SeleccionarEmpresaErrorInicial('No tiene empresas disponibles.'));
      return;
    }

    _seleccionada = _empresas.first;
    await _cargarPreview(emit);
  }

  Future<void> _onElegir(
    SeleccionarEmpresaElegir event,
    Emitter<SeleccionarEmpresaState> emit,
  ) async {
    _seleccionada = event.empresa;
    await _cargarPreview(emit);
  }

  Future<void> _cargarPreview(Emitter<SeleccionarEmpresaState> emit) async {
    emit(SeleccionarEmpresaListo(
      empresas: _empresas,
      empresaSeleccionada: _seleccionada!,
      cargandoPreview: true,
    ));

    final preAuthToken = _esPostLogin ? args.preAuthToken : null;
    final result = await _tipoCambioRepo.preview(_seleccionada!.codigo, bearerOverride: preAuthToken);

    if (result.isLeft()) {
      emit(SeleccionarEmpresaListo(
        empresas: _empresas,
        empresaSeleccionada: _seleccionada!,
        errorMessage: result.fold((f) => f.message, (_) => ''),
      ));
      return;
    }

    final tc = result.fold((_) => null, (tc) => tc);
    emit(SeleccionarEmpresaListo(
      empresas: _empresas,
      empresaSeleccionada: _seleccionada!,
      tipoCambioHoy: tc?.tipoCambio,
      tipoCambioRequerido: tc == null || tc.tipoCambio == 0,
    ));
  }

  Future<void> _onConfirmar(
    SeleccionarEmpresaConfirmar event,
    Emitter<SeleccionarEmpresaState> emit,
  ) async {
    final actual = state;
    if (actual is! SeleccionarEmpresaListo) return;
    emit(actual.copyWith(confirmando: true, errorMessage: null));

    final seleccionResult = _esPostLogin
        ? await _authRepo.seleccionarEmpresa(
            preAuthToken: args.preAuthToken!,
            codigoEmpresa: _seleccionada!.codigo,
          )
        : await _authRepo.cambiarEmpresa(codigoEmpresa: _seleccionada!.codigo);

    if (seleccionResult.isLeft()) {
      emit(actual.copyWith(
        confirmando: false,
        errorMessage: seleccionResult.fold((f) => f.message, (_) => ''),
      ));
      return;
    }
    final usuario = seleccionResult.fold((_) => null, (u) => u)!;

    if (event.tipoCambioValor != null) {
      final tcResult = await _tipoCambioRepo.registrar(event.tipoCambioValor!);
      if (tcResult.isLeft()) {
        emit(actual.copyWith(
          confirmando: false,
          errorMessage: tcResult.fold((f) => f.message, (_) => ''),
        ));
        return;
      }
    }

    emit(SeleccionarEmpresaExitoso(usuario));
  }
}
