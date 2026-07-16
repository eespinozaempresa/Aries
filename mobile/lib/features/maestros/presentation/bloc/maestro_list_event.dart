sealed class MaestroListEvent {
  const MaestroListEvent();
}

class MaestroListLoad extends MaestroListEvent {
  final String? q;
  final bool? activo;
  final int page;
  MaestroListLoad({this.q, this.activo, this.page = 1});
}

class MaestroListLoadMore extends MaestroListEvent {}

class MaestroListRefresh extends MaestroListEvent {
  final String? q;
  const MaestroListRefresh({this.q});
}
