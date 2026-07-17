import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TablasHubPage extends StatelessWidget {
  const TablasHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      const _Tile('Tipos de Lista', Icons.price_change_outlined, '/tablas/tipos-lista'),
      const _Tile('Líneas',         Icons.category_outlined,     '/tablas/lineas'),
      const _Tile('Medidas',        Icons.straighten,             '/tablas/medidas'),
      const _Tile('Bancos',         Icons.account_balance,        '/tablas/bancos'),
      const _Tile('Marcas',         Icons.label_outlined,         '/tablas/marcas'),
      const _Tile('Documentos',     Icons.description_outlined,   '/tablas/documentos'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tablas Base')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final t = tiles[i];
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
            leading: Icon(t.icon, color: Theme.of(ctx).colorScheme.primary),
            title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
  final IconData icon;
  final String route;
  const _Tile(this.title, this.icon, this.route);
}
