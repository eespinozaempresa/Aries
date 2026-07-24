sealed class TipoCambioEvent {}

class TipoCambioRegistrar extends TipoCambioEvent {
  final double tipoCambio;
  TipoCambioRegistrar(this.tipoCambio);
}

class TipoCambioListLoad extends TipoCambioEvent {}

class TipoCambioListLoadMore extends TipoCambioEvent {}

class TipoCambioActualizar extends TipoCambioEvent {
  final String id;
  final double tipoCambio;
  TipoCambioActualizar(this.id, this.tipoCambio);
}

class TipoCambioEliminar extends TipoCambioEvent {
  final String id;
  TipoCambioEliminar(this.id);
}
