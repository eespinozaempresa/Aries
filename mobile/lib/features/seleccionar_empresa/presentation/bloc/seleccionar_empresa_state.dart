import '../../../auth/domain/entities/empresa_opcion.dart';
import '../../../auth/domain/entities/usuario.dart';

sealed class SeleccionarEmpresaState {}

class SeleccionarEmpresaCargando extends SeleccionarEmpresaState {}

class SeleccionarEmpresaErrorInicial extends SeleccionarEmpresaState {
  final String message;
  SeleccionarEmpresaErrorInicial(this.message);
}

class SeleccionarEmpresaListo extends SeleccionarEmpresaState {
  final List<EmpresaOpcion> empresas;
  final EmpresaOpcion empresaSeleccionada;
  final double? tipoCambioHoy;
  final bool tipoCambioRequerido;
  final bool cargandoPreview;
  final bool confirmando;
  final String? errorMessage;

  SeleccionarEmpresaListo({
    required this.empresas,
    required this.empresaSeleccionada,
    this.tipoCambioHoy,
    this.tipoCambioRequerido = false,
    this.cargandoPreview = false,
    this.confirmando = false,
    this.errorMessage,
  });

  SeleccionarEmpresaListo copyWith({
    List<EmpresaOpcion>? empresas,
    EmpresaOpcion? empresaSeleccionada,
    double? tipoCambioHoy,
    bool? tipoCambioRequerido,
    bool? cargandoPreview,
    bool? confirmando,
    String? errorMessage,
  }) {
    return SeleccionarEmpresaListo(
      empresas: empresas ?? this.empresas,
      empresaSeleccionada: empresaSeleccionada ?? this.empresaSeleccionada,
      tipoCambioHoy: tipoCambioHoy ?? this.tipoCambioHoy,
      tipoCambioRequerido: tipoCambioRequerido ?? this.tipoCambioRequerido,
      cargandoPreview: cargandoPreview ?? this.cargandoPreview,
      confirmando: confirmando ?? this.confirmando,
      errorMessage: errorMessage,
    );
  }
}

class SeleccionarEmpresaExitoso extends SeleccionarEmpresaState {
  final Usuario usuario;
  SeleccionarEmpresaExitoso(this.usuario);
}
