import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _menuItems = [
    _MenuItem('Tablas',          Icons.table_chart_outlined,     '/tablas'),
    _MenuItem('Maestros',        Icons.inventory_2_outlined,     '/maestros'),
    _MenuItem('Almacén',         Icons.warehouse_outlined,       '/almacen'),
    _MenuItem('Compras',         Icons.shopping_cart_outlined,   '/compras'),
    _MenuItem('Ventas',          Icons.point_of_sale_outlined,   '/ventas'),
    _MenuItem('Cuentas × Cobrar',Icons.account_balance_outlined, '/cxc'),
    _MenuItem('Cuentas × Pagar', Icons.payments_outlined,        '/cxp'),
    _MenuItem('Caja',            Icons.savings_outlined,         '/caja'),
    _MenuItem('Utilitarios',     Icons.settings_outlined,        '/utilitarios'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARIES ERP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: _menuItems.length,
          itemBuilder: (context, i) => _MenuCard(_menuItems[i]),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final storage = getIt<FlutterSecureStorage>();
    await storage.deleteAll();
    if (context.mounted) context.go('/login');
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final String route;
  const _MenuItem(this.label, this.icon, this.route);
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard(this.item);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () => context.push(item.route),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 36, color: cs.primary),
              const SizedBox(height: 10),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
