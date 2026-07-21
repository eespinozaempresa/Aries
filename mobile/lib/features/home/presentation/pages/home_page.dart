import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/menu_permission_service.dart';
import '../../../../core/widgets/aries_app_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = MenuPermissionService.instance;
    final items = [
      if (svc.canAccess('tablas'))    _MenuItem('Tablas',           Icons.table_chart_outlined,     '/tablas'),
      if (svc.canAccess('maestros'))  _MenuItem('Maestros',         Icons.inventory_2_outlined,     '/maestros'),
      if (svc.canAccess('almacen'))   _MenuItem('Almacén',          Icons.warehouse_outlined,       '/almacen'),
      if (svc.canAccess('compras'))   _MenuItem('Compras',          Icons.shopping_cart_outlined,   '/compras'),
      if (svc.canAccess('ventas'))    _MenuItem('Ventas',           Icons.point_of_sale_outlined,   '/ventas'),
      if (svc.canAccess('cxc'))       _MenuItem('Cuentas × Cobrar', Icons.account_balance_outlined, '/cxc'),
      if (svc.canAccess('cxp'))       _MenuItem('Cuentas × Pagar', Icons.payments_outlined,        '/cxp'),
      if (svc.canAccess('caja'))      _MenuItem('Caja',             Icons.savings_outlined,         '/caja'),
      if (svc.canAccess('seguridad')) _MenuItem('Seguridad',        Icons.shield_outlined,          '/seguridad'),
      if (svc.canAccess('utilitarios')) _MenuItem('Utilitarios',   Icons.settings_outlined,        '/utilitarios'),
    ];

    return Scaffold(
      appBar: const AriesAppBar(title: Text('ARIES')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => _MenuCard(items[i]),
        ),
      ),
    );
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
