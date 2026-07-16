sealed class TipoCambioEvent {}

class TipoCambioCheckHoy extends TipoCambioEvent {}

class TipoCambioRegistrar extends TipoCambioEvent {
  final double tipoCambio;
  TipoCambioRegistrar(this.tipoCambio);
}
