import '../../domain/entities/venta.dart';
sealed class VentaState {}
class VentaInitial       extends VentaState {}
class VentaListLoading   extends VentaState { final List<Venta> previous; VentaListLoading({this.previous = const []}); }
class VentaListLoaded    extends VentaState { final List<Venta> items; final int total; final int page; final int lastPage; VentaListLoaded({required this.items, required this.total, required this.page, required this.lastPage}); }
class VentaDetailLoading extends VentaState {}
class VentaDetailLoaded  extends VentaState { final Venta venta; VentaDetailLoaded(this.venta); }
class VentaSaving        extends VentaState {}
class VentaSaved         extends VentaState { final Venta venta; VentaSaved(this.venta); }
class VentaAnulada       extends VentaState { final Venta venta; VentaAnulada(this.venta); }
class VentaError         extends VentaState { final String message; VentaError(this.message); }
