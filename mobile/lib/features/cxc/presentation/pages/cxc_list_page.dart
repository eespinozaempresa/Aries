import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/export_service.dart';
import '../../data/datasources/cxc_remote_datasource.dart';
import '../../domain/entities/cuenta_cobrar.dart';
import '../bloc/cxc_bloc.dart';

class CxCListPage extends StatefulWidget {
  const CxCListPage({super.key});
  @override
  State<CxCListPage> createState() => _State();
}

class _State extends State<CxCListPage> {
  bool? _filtroPendiente = true;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<CxCBloc>().add(CxCLoad(pendiente: _filtroPendiente));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CxCBloc(getIt<CxCRemoteDataSource>())
        ..add(CxCLoad(reset: true, pendiente: _filtroPendiente)),
      child: Builder(builder: (ctx) => Scaffold(
        appBar: AppBar(
          title: const Text('CxC — Cuentas por Cobrar'),
          actions: [
            BlocBuilder<CxCBloc, CxCState>(
              builder: (bctx, state) {
                final items = switch (state) {
                  CxCLoaded(:final items) => items,
                  _ => <CuentaCobrar>[],
                };
                if (items.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: 'Exportar',
                  onPressed: () => ExportService.showExportDialog(
                    context: context,
                    title: 'Cuentas por Cobrar',
                    columns: const ['Provisión', 'Cliente', 'Doc', 'Número', 'Emisión', 'Vencimiento', 'Total', 'Saldo', 'Estado'],
                    rows: items.map((c) => <String>[
                      '${c.numeroProvision}',
                      c.codigoCliente,
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
                ctx.read<CxCBloc>().add(CxCLoad(reset: true, pendiente: v));
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocConsumer<CxCBloc, CxCState>(
          listener: (c, s) {
            if (s is CxCError) {
              ScaffoldMessenger.of(c).showSnackBar(
              SnackBar(content: Text(s.message), backgroundColor: Colors.red));
            }
          },
          builder: (c, s) {
            if (s is CxCLoading && (s is! CxCLoaded)) return const Center(child: CircularProgressIndicator());
            final items = switch (s) {
              CxCLoaded(:final items) => items,
              _ => <CuentaCobrar>[],
            };
            if (items.isEmpty && s is! CxCLoading) return const Center(child: Text('Sin registros'));
            return ListView.builder(
              controller: _scroll,
              itemCount: items.length + 1,
              itemBuilder: (_, i) {
                if (i == items.length) {
                  final loaded = s is CxCLoaded;
                  return loaded && s.currentPage < s.lastPage
                    ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                    : const SizedBox();
                }
                final cxc = items[i];
                final vencida = cxc.fechaVencimiento != null &&
                  DateTime.tryParse(cxc.fechaVencimiento!)?.isBefore(DateTime.now()) == true &&
                  cxc.pendiente;
                return ListTile(
                  onTap: () => ctx.push('/cxc/${cxc.id}'),
                  leading: CircleAvatar(
                    backgroundColor: vencida ? Colors.red[100] : cxc.pendiente ? Colors.orange[100] : Colors.green[100],
                    child: Icon(
                      vencida ? Icons.warning : cxc.pendiente ? Icons.hourglass_empty : Icons.check_circle,
                      color: vencida ? Colors.red : cxc.pendiente ? Colors.orange : Colors.green,
                      size: 20,
                    ),
                  ),
                  title: Text('Prov. ${cxc.numeroProvision} — ${cxc.codigoCliente}'),
                  subtitle: Text('${cxc.codigoDocumento} ${cxc.numeroDocumento} | ${cxc.fechaEmision}'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('S/ ${cxc.saldo.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: cxc.pendiente ? Colors.deepOrange : Colors.grey)),
                    Text('Total: S/ ${cxc.montoTotal.toStringAsFixed(2)}',
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
