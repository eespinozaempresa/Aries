sealed class VentaEvent {}
class VentaListLoad     extends VentaEvent { final String? cliente; final String? almacen; final String? desde; final String? hasta; VentaListLoad({this.cliente, this.almacen, this.desde, this.hasta}); }
class VentaListLoadMore extends VentaEvent {}
class VentaRegistrar    extends VentaEvent { final Map<String, dynamic> data; VentaRegistrar(this.data); }
class VentaAnular       extends VentaEvent { final String id; VentaAnular(this.id); }
class VentaLoadDetail   extends VentaEvent { final String id; VentaLoadDetail(this.id); }
class VentaEliminar     extends VentaEvent { final String id; VentaEliminar(this.id); }
