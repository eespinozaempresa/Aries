import '../auth/domain/entities/empresa_opcion.dart';

enum SeleccionarEmpresaModo { postLogin, cambiarEmpresa }

/// Argumentos pasados por go_router (`extra`) al entrar a /seleccionar-empresa.
/// - postLogin: viene de un login fase 1 recién validado (preAuthToken + lista ya conocida).
/// - cambiarEmpresa: sesión ya activa, la lista se recarga en vivo vía /auth/mis-empresas.
class SeleccionarEmpresaArgs {
  final SeleccionarEmpresaModo modo;
  final String? preAuthToken;
  final List<EmpresaOpcion>? empresas;

  const SeleccionarEmpresaArgs.postLogin({
    required this.preAuthToken,
    required this.empresas,
  }) : modo = SeleccionarEmpresaModo.postLogin;

  const SeleccionarEmpresaArgs.cambiarEmpresa()
      : modo = SeleccionarEmpresaModo.cambiarEmpresa,
        preAuthToken = null,
        empresas = null;
}
