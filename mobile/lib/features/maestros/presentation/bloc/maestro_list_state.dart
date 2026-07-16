sealed class MaestroListState<T> {
  const MaestroListState();
}

class MaestroListInitial<T> extends MaestroListState<T> {}

class MaestroListLoading<T> extends MaestroListState<T> {
  final List<T> previousItems;
  const MaestroListLoading({this.previousItems = const []});
}

class MaestroListLoaded<T> extends MaestroListState<T> {
  final List<T> items;
  final int total;
  final int page;
  final int lastPage;
  const MaestroListLoaded({
    required this.items,
    required this.total,
    required this.page,
    required this.lastPage,
  });
  bool get hasMore => page < lastPage;
}

class MaestroListError<T> extends MaestroListState<T> {
  final String message;
  const MaestroListError(this.message);
}
