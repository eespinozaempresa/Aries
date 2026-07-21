import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/export_service.dart';
import '../../data/datasources/compras_remote_datasource.dart';
import '../../domain/entities/compra.dart';
import '../bloc/compra_bloc.dart';
import '../bloc/compra_event.dart';
import '../bloc/compra_state.dart';
import '../../../../core/widgets/aries_app_bar.dart';

class ComprasListPage extends StatelessWidget {
  const ComprasListPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CompraBloc(getIt<ComprasRemoteDataSource>())..add(CompraListLoad()),
    child: const _View(),
  );
}

class _View extends StatefulWidget {
  const _View();
  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<CompraBloc>().add(CompraListLoadMore());
      }
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AriesAppBar(
        title: const Text('Compras'),
        actions: [
          BlocBuilder<CompraBloc, CompraState>(
            builder: (ctx, state) {
              final items = switch (state) {
                CompraListLoaded(:final items) => items,
                CompraListLoading(:final previous) => previous,
                _ => <Compra>[],
              };
              if (items.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Exportar',
                onPressed: () => ExportService.showExportDialog(
                  context: context,
                  title: 'Compras',
                  columns: const ['Doc', 'Serie', 'Número', 'Fecha', 'Proveedor', 'Total', 'Moneda', 'Estado'],
                  rows: items.map((c) => [
                    c.abreviaturaDocumento ?? c.codigoDocumento,
                    c.serie,
                    c.numeroDocumento,
                    ExportService.fmtDate(c.fecha),
                    c.codigoProveedor,
                    c.total.toStringAsFixed(2),
                    c.moneda,
                    c.anulado ? 'Anulada' : 'Vigente',
                  ]).toList(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await context.push<bool>('/compras/nueva');
          if (saved == true && context.mounted) {
            context.read<CompraBloc>().add(CompraListLoad());
          }
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<CompraBloc, CompraState>(
        builder: (ctx, state) {
          if (state is CompraListLoading && state.previous.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = switch (state) {
            CompraListLoaded(:final items) => items,
            CompraListLoading(:final previous) => previous,
            _ => <Compra>[],
          };
          if (items.isEmpty) return const Center(child: Text('Sin compras'));
          return RefreshIndicator(
            onRefresh: () async => ctx.read<CompraBloc>().add(CompraListLoad()),
            child: ListView.builder(
              controller: _scroll,
              itemCount: items.length + 1,
              itemBuilder: (ctx, i) {
                if (i == items.length) {
                  return state is CompraListLoading && (state).previous.isNotEmpty
                      ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                      : const SizedBox.shrink();
                }
                final c = items[i];
                final cur   = c.moneda == 'USD' ? '\$' : 'S/';
                final monto = c.moneda == 'USD' ? c.totalUsd : c.total;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: c.anulado ? Colors.grey.shade200 : Colors.blue.shade50,
                    child: Text(c.abreviaturaDocumento ?? c.codigoDocumento, style: const TextStyle(fontSize: 10)),
                  ),
                  title: Text('${c.abreviaturaDocumento ?? c.codigoDocumento}-${c.serie}-${c.numeroDocumento}'),
                  subtitle: Text('${c.fecha} · ${c.razonSocialProveedor ?? c.codigoProveedor}'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('$cur ${monto.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (c.anulado) const Text('ANULADA', style: TextStyle(color: Colors.red, fontSize: 10)),
                  ]),
                  onTap: () async {
                    final deleted = await ctx.push<bool>('/compras/${c.id}');
                    if (deleted == true && ctx.mounted) {
                      ctx.read<CompraBloc>().add(CompraListLoad());
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
