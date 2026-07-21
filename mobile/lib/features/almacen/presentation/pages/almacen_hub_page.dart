import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/menu_permission_service.dart';
import '../../../../core/widgets/aries_app_bar.dart';

class AlmacenHubPage extends StatelessWidget {
  const AlmacenHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = MenuPermissionService.instance;
    final tiles = [
      if (svc.canAccess('almacen.movimientos'))
        const _Tile('Movimientos', 'Ingresos, Salidas y Traslados', Icons.swap_horiz, '/almacen/movimientos'),
      if (svc.canAccess('almacen.kardex'))
        const _Tile('Kardex', 'Consulta de movimientos por artículo', Icons.receipt_long, '/almacen/kardex'),
      if (svc.canAccess('almacen.stock'))
        const _Tile('Stock', 'Inventario actual', Icons.inventory, '/almacen/stock'),
    ];

    return Scaffold(
      appBar: AriesAppBar(title: const Text('Almacén')),
      body: tiles.isEmpty
          ? const Center(child: Text('Sin acceso a almacén'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final t = tiles[i];
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  leading: Icon(t.icon, color: Theme.of(ctx).colorScheme.primary),
                  title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(t.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ctx.push(t.route),
                );
              },
            ),
    );
  }
}

class _Tile {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  const _Tile(this.title, this.subtitle, this.icon, this.route);
}
