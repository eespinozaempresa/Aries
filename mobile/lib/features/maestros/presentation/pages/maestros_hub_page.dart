import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/menu_permission_service.dart';
import '../../../../core/widgets/aries_app_bar.dart';

class MaestrosHubPage extends StatelessWidget {
  const MaestrosHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svc = MenuPermissionService.instance;
    final items = [
      if (svc.canAccess('maestros.articulos'))
        const _Item('Artículos', Icons.inventory_2_outlined, '/maestros/articulos'),
      if (svc.canAccess('maestros.clientes'))
        const _Item('Clientes', Icons.people_outline, '/maestros/clientes'),
      if (svc.canAccess('maestros.proveedores'))
        const _Item('Proveedores', Icons.local_shipping_outlined, '/maestros/proveedores'),
      if (svc.canAccess('maestros.almacenes'))
        const _Item('Almacenes', Icons.warehouse_outlined, '/maestros/almacenes'),
    ];

    return Scaffold(
      appBar: AriesAppBar(title: const Text('Maestros')),
      body: items.isEmpty
          ? const Center(child: Text('Sin acceso a maestros'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final item = items[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Icon(item.icon, color: cs.primary),
                    ),
                    title: Text(item.label,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(item.route),
                  ),
                );
              },
            ),
    );
  }
}

class _Item {
  final String label;
  final IconData icon;
  final String route;
  const _Item(this.label, this.icon, this.route);
}
