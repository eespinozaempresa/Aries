import '../../domain/entities/compra.dart';

sealed class CompraState {}
class CompraInitial       extends CompraState {}
class CompraListLoading   extends CompraState { final List<Compra> previous; CompraListLoading({this.previous = const []}); }
class CompraListLoaded    extends CompraState { final List<Compra> items; final int total; final int page; final int lastPage; CompraListLoaded({required this.items, required this.total, required this.page, required this.lastPage}); }
class CompraDetailLoading extends CompraState {}
class CompraDetailLoaded  extends CompraState { final Compra compra; CompraDetailLoaded(this.compra); }
class CompraSaving        extends CompraState {}
class CompraSaved         extends CompraState { final Compra compra; CompraSaved(this.compra); }
class CompraAnulado       extends CompraState { final Compra compra; CompraAnulado(this.compra); }
class CompraEliminada     extends CompraState { final String id; CompraEliminada(this.id); }
class CompraError         extends CompraState { final String message; CompraError(this.message); }
