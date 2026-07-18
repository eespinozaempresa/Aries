import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/export_service.dart';
import '../../data/datasources/cxp_remote_datasource.dart';
import '../../domain/entities/cuenta_pagar.dart';
import '../bloc/cxp_bloc.dart';

class CxPListPage extends StatefulWidget {
  const CxPListPage({super.key});
  @override
  State<CxPListPage> createState() => _State();
}

class _State extends State<CxPListPage> {
  bool? _filtroPendiente = true;
  final _scroll = ScrollController();

  @override
  void initState() { super.initState(); _scroll.addListener(_onScroll); }
  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<CxPBloc>().add(CxPLoad(pendiente: _filtroPendiente));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CxPBloc(getIt<CxPRemoteDataSource>())
        ..add(CxPLoad(reset: true, pendiente: _filtroPendiente)),
      child: Builder(builder: (ctx) => Scaffold(
        appBar: AppBar(
          title: const Text('CxP — Cuentas por Pagar'),
          actions: [
            BlocBuilder<CxPBloc, CxPState>(
              builder: (bctx, state) {
                final items = switch (state) {
                  CxPLoaded(:final items) => items,
                  _ => <CuentaPagar>[],
                };
                if (items.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Exportar',
                  onPressed: () => ExportService.showExportDialog(
                    context: context,
                    title: 'Cuentas por Pagar',
                    columns: const ['Provisión', 'Proveedor', 'Doc', 'Número', 'Emisión', 'Vencimiento', 'Total', 'Saldo', 'Estado'],
                    rows: items.map((c) => [
                      '${c.numeroProvision}',
                      c.codigoProveedor,
                      c.codigoDocumento,
                      c.numeroDocumento,
                      c.fechaEmision,
                      c.fechaVencimiento ?? '-',
                      c.montoTotal.toStringAsFixed(2),
                      c.saldo.toStringAsFixed(2),
                      c.pendiente ? 'Pendiente' : 'Cancelada',
                    ]).toList(),
                  ),
                );
              },
            ),
            DropdownButton<bool?>(
              value: _filtroPendiente,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: null,  child: Text('Todas')),
                DropdownMenuItem(value: true,  child: Text('Pendientes')),
                DropdownMenuItem(value: false, child: Text('Canceladas')),
              ],
              onChanged: (v) {
                setState(() => _filtroPendiente = v);
                ctx.read<CxPBloc>().add(CxPLoad(reset: true, pendiente: v));
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocConsumer<CxPBloc, CxPState>(
          listener: (c, s) {
            if (s is CxPError) {
              ScaffoldMessenger.of(c).showSnackBar(
              SnackBar(content: Text(s.message), backgroundColor: Colors.red));
            }
          },
          builder: (c, s) {
            if (s is CxPLoading) return const Center(child: CircularProgressIndicator());
            final items = switch (s) {
              CxPLoaded(:final items) => items,
              _ => <CuentaPagar>[],
            };
            if (items.isEmpty && s is! CxPLoading) return const Center(child: Text('Sin registros'));
            return ListView.builder(
              controller: _scroll,
              itemCount: items.length + 1,
              itemBuilder: (_, i) {
                if (i == items.length) {
                  final loaded = s is CxPLoaded;
                  return loaded && s.currentPage < s.lastPage
                    ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                    : const SizedBox();
                }
                final cxp = items[i];
                final vencida = cxp.fechaVencimiento != null &&
                  DateTime.tryParse(cxp.fechaVencimiento!)?.isBefore(DateTime.now()) == true &&
                  cxp.pendiente;
                return ListTile(
                  onTap: () => ctx.go('/cxp/${cxp.id}'),
                  leading: CircleAvatar(
                    backgroundColor: vencida ? Colors.red[100] : cxp.pendiente ? Colors.orange[100] : Colors.green[100],
                    child: Icon(
                      vencida ? Icons.warning : cxp.pendiente ? Icons.hourglass_empty : Icons.check_circle,
                      color: vencida ? Colors.red : cxp.pendiente ? Colors.orange : Colors.green,
                      size: 20,
                    ),
                  ),
                  title: Text('Prov. ${cxp.numeroProvision} — ${cxp.codigoProveedor}'),
                  subtitle: Text('${cxp.codigoDocumento} ${cxp.numeroDocumento} | ${cxp.fechaEmision}'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('S/ ${cxp.saldo.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: cxp.pendiente ? Colors.deepOrange : Colors.grey)),
                    Text('Total: S/ ${cxp.montoTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
                );
              },
            );
          },
        ),
      )),
    );
  }
}
