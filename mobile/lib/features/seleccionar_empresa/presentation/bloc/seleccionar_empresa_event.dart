import '../../../auth/domain/entities/empresa_opcion.dart';

sealed class SeleccionarEmpresaEvent {}

class SeleccionarEmpresaIniciar extends SeleccionarEmpresaEvent {}

class SeleccionarEmpresaElegir extends SeleccionarEmpresaEvent {
  final EmpresaOpcion empresa;
  SeleccionarEmpresaElegir(this.empresa);
}

class SeleccionarEmpresaConfirmar extends SeleccionarEmpresaEvent {
  final double? tipoCambioValor;
  SeleccionarEmpresaConfirmar({this.tipoCambioValor});
}
