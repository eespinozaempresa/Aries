import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MaestrosHubPage extends StatelessWidget {
  const MaestrosHubPage({super.key});

  static const _items = [
    _Item('Artículos',   Icons.inventory_2_outlined,  '/maestros/articulos'),
    _Item('Clientes',    Icons.people_outline,         '/maestros/clientes'),
    _Item('Proveedores', Icons.local_shipping_outlined,'/maestros/proveedores'),
    _Item('Almacenes',   Icons.warehouse_outlined,     '/maestros/almacenes'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Maestros')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final item = _items[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(item.icon, color: cs.primary),
              ),
              title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
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
