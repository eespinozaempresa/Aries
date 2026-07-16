
sealed class CompraEvent {}

class CompraListLoad extends CompraEvent {
  final String? proveedor;
  final String? almacen;
  final String? desde;
  final String? hasta;
  final int page;
  CompraListLoad({this.proveedor, this.almacen, this.desde, this.hasta, this.page = 1});
}

class CompraListLoadMore extends CompraEvent {}

class CompraRegistrar extends CompraEvent {
  final Map<String, dynamic> data;
  CompraRegistrar(this.data);
}

class CompraAnular extends CompraEvent {
  final String id;
  CompraAnular(this.id);
}

class CompraLoadDetail extends CompraEvent {
  final String id;
  CompraLoadDetail(this.id);
}
