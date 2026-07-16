import '../../domain/entities/tabla_base.dart';

sealed class TablaState {}

class TablaInitial  extends TablaState {}
class TablaLoading  extends TablaState {}
class TablaLoaded<T extends TablaBase> extends TablaState {
  final List<T> items;
  TablaLoaded(this.items);
}
class TablaSaving   extends TablaState {}
class TablaSaved<T extends TablaBase> extends TablaState {
  final T item;
  TablaSaved(this.item);
}
class TablaError    extends TablaState {
  final String message;
  TablaError(this.message);
}
