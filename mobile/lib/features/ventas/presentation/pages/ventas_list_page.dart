import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/export_service.dart';
import '../../data/datasources/ventas_remote_datasource.dart';
import '../../domain/entities/venta.dart';
import '../bloc/venta_bloc.dart';
import '../bloc/venta_event.dart';
import '../bloc/venta_state.dart';

class VentasListPage extends StatelessWidget {
  const VentasListPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => VentaBloc(getIt<VentasRemoteDataSource>())..add(VentaListLoad()),
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
        context.read<VentaBloc>().add(VentaListLoadMore());
      }
    });
  }
  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Reporte Utilidad',
            onPressed: () => context.push('/ventas/reporte-utilidad'),
          ),
          BlocBuilder<VentaBloc, VentaState>(
            builder: (ctx, state) {
              final items = switch (state) {
                VentaListLoaded(:final items) => items,
                VentaListLoading(:final previous) => previous,
                _ => <Venta>[],
              };
              if (items.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Exportar',
                onPressed: () => ExportService.showExportDialog(
                  context: context,
                  title: 'Ventas',
                  columns: const ['Doc', 'Serie', 'Número', 'Fecha', 'Cliente', 'Total', 'Tipo', 'Estado'],
                  rows: items.map((v) => [
                    v.codigoDocumento,
                    v.serie,
                    v.numeroDocumento,
                    v.fecha,
                    v.codigoCliente,
                    v.total.toStringAsFixed(2),
                    v.tipoVenta.name,
                    v.anulado ? 'Anulada' : 'Vigente',
                  ]).toList(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await context.push<bool>('/ventas/nueva');
          if (saved == true && context.mounted) {
            context.read<VentaBloc>().add(VentaListLoad());
          }
        },
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<VentaBloc, VentaState>(
        builder: (ctx, state) {
          if (state is VentaListLoading && state.previous.isEmpty) return const Center(child: CircularProgressIndicator());
          final items = switch (state) {
            VentaListLoaded(:final items) => items,
            VentaListLoading(:final previous) => previous,
            _ => <Venta>[],
          };
          if (items.isEmpty) return const Center(child: Text('Sin ventas'));
          return RefreshIndicator(
            onRefresh: () async => ctx.read<VentaBloc>().add(VentaListLoad()),
            child: ListView.builder(
              controller: _scroll,
              itemCount: items.length + 1,
              itemBuilder: (ctx, i) {
                if (i == items.length) {
                  return state is VentaListLoading && (state).previous.isNotEmpty
                      ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                      : const SizedBox.shrink();
                }
                final v = items[i];
                final cur    = v.moneda == 'USD' ? '\$' : 'S/';
                final monto  = v.moneda == 'USD' ? v.totalUsd : v.total;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: v.anulado ? Colors.grey.shade200 : Colors.green.shade50,
                    child: Icon(Icons.receipt, color: v.anulado ? Colors.grey : Colors.green, size: 20),
                  ),
                  title: Text('${v.codigoDocumento}-${v.serie}-${v.numeroDocumento}'),
                  subtitle: Text('${v.fecha} · ${v.razonSocialCliente ?? v.codigoCliente}'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('$cur ${monto.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (v.anulado) const Text('ANULADA', style: TextStyle(color: Colors.red, fontSize: 10)),
                    if (v.tipoVenta == TipoVenta.CREDITO && !v.anulado) const Text('CRÉDITO', style: TextStyle(color: Colors.orange, fontSize: 10)),
                  ]),
                  onTap: () async {
                    final deleted = await ctx.push<bool>('/ventas/${v.id}');
                    if (deleted == true && ctx.mounted) {
                      ctx.read<VentaBloc>().add(VentaListLoad());
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
