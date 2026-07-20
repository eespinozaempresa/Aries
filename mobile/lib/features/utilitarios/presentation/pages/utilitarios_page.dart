import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/menu_permission_service.dart';

class UtilitariosPage extends StatelessWidget {
  const UtilitariosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = MenuPermissionService.instance;
    final tiles = [
      if (svc.canAccess('utilitarios.tipo-cambio'))
        const _Tile('Tipo de Cambio', 'Historial de tipos de cambio USD',
            Icons.currency_exchange_outlined, '/utilitarios/tipo-cambio', false),
      if (svc.canAccess('utilitarios.parametros'))
        const _Tile('Parámetros', 'IGV, plazos y configuración',
            Icons.tune_outlined, '/utilitarios/parametros', false),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Utilitarios')),
      body: tiles.isEmpty
          ? const Center(child: Text('Sin acceso a utilitarios'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final t = tiles[i];
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: t.proximamente
                      ? Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                      : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  leading: Icon(
                    t.icon,
                    color: t.proximamente
                        ? Theme.of(ctx).colorScheme.outline
                        : Theme.of(ctx).colorScheme.primary,
                  ),
                  title: Row(
                    children: [
                      Text(t.title, style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: t.proximamente ? Theme.of(ctx).colorScheme.outline : null,
                      )),
                      if (t.proximamente) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Próximamente',
                              style: TextStyle(fontSize: 10, color: Theme.of(ctx).colorScheme.outline)),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(t.subtitle,
                      style: t.proximamente
                          ? TextStyle(color: Theme.of(ctx).colorScheme.outline)
                          : null),
                  trailing: t.proximamente ? null : const Icon(Icons.chevron_right),
                  onTap: t.proximamente ? null : () => ctx.push(t.route),
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
  final bool proximamente;
  const _Tile(this.title, this.subtitle, this.icon, this.route, this.proximamente);
}
