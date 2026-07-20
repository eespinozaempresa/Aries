class MenuPermissionService {
  static final MenuPermissionService _instance = MenuPermissionService._();
  static MenuPermissionService get instance => _instance;
  MenuPermissionService._();

  Set<String> _menus = {};
  bool _isAdmin = false;
  bool _initialized = false;

  bool get initialized => _initialized;
  bool get isAdmin => _isAdmin;

  void load(List<String> menus, String nivel) {
    _isAdmin = nivel.toUpperCase() == 'ADMIN';
    _menus = menus.toSet();
    _initialized = true;
  }

  bool canAccess(String key) {
    if (!_initialized) return true;
    if (_isAdmin) return true;
    return _menus.contains(key);
  }

  void clear() {
    _menus = {};
    _isAdmin = false;
    _initialized = false;
  }
}
