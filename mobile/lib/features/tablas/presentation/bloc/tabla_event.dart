sealed class TablaEvent {}

class TablaLoad extends TablaEvent {
  final String? q;
  final bool? activo;
  TablaLoad({this.q, this.activo});
}

class TablaSave extends TablaEvent {
  final Map<String, dynamic> data;
  final String? id;
  TablaSave(this.data, {this.id});
}

class TablaToggle extends TablaEvent {
  final String id;
  TablaToggle(this.id);
}
