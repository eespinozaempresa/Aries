import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/export_service.dart';
import '../../data/datasources/cxp_remote_datasource.dart';
import '../../domain/entities/cuenta_pagar.dart';
import '../bloc/cxp_bloc.dart';
import '../../../../core/widgets/aries_app_bar.dart';
import '../../../../core/widgets/number_form_field.dart';
import '../../../tablas/data/datasources/tablas_remote_datasource.dart';
import '../../../tablas/data/models/tabla_model.dart';
import '../../../tablas/domain/entities/tabla_base.dart';

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
        appBar: AriesAppBar(
          title: const Text('CxP — Cuentas por Pagar'),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              tooltip: 'Consolidado',
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => _ConsolidadoDialog(bloc: ctx.read<CxPBloc>()),
              ),
            ),
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
                      c.razonSocialProveedor ?? c.codigoProveedor,
                      c.codigoDocumento,
                      c.numeroDocumento,
                      ExportService.fmtDate(c.fechaEmision),
                      ExportService.fmtDate(c.fechaVencimiento),
                      c.montoTotal.toStringAsFixed(2),
                      c.saldo.toStringAsFixed(2),
                      c.pendiente ? 'Pendiente' : 'Cancelada',
                    ]).toList(),
                  ),
                );
              },
            ),
            PopupMenuButton<bool?>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtrar',
              initialValue: _filtroPendiente,
              onSelected: (v) {
                setState(() => _filtroPendiente = v);
                ctx.read<CxPBloc>().add(CxPLoad(reset: true, pendiente: v));
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(value: null,  checked: _filtroPendiente == null,  child: const Text('Todas')),
                CheckedPopupMenuItem(value: true,  checked: _filtroPendiente == true,  child: const Text('Pendientes')),
                CheckedPopupMenuItem(value: false, checked: _filtroPendiente == false, child: const Text('Canceladas')),
              ],
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
            if (s is CxPPagoRegistrado) {
              ScaffoldMessenger.of(c).showSnackBar(
                const SnackBar(content: Text('Pago registrado'), backgroundColor: Colors.green));
              c.read<CxPBloc>().add(CxPLoad(reset: true, pendiente: _filtroPendiente));
            }
          },
          builder: (c, s) {
            if (s is CxPLoading || s is CxPSaving) return const Center(child: CircularProgressIndicator());
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
                  onTap: () => ctx.push('/cxp/${cxp.id}'),
                  leading: CircleAvatar(
                    backgroundColor: vencida ? Colors.red[100] : cxp.pendiente ? Colors.orange[100] : Colors.green[100],
                    child: Icon(
                      vencida ? Icons.warning : cxp.pendiente ? Icons.hourglass_empty : Icons.check_circle,
                      color: vencida ? Colors.red : cxp.pendiente ? Colors.orange : Colors.green,
                      size: 20,
                    ),
                  ),
                  title: Text('Prov. ${cxp.numeroProvision} — ${cxp.razonSocialProveedor ?? cxp.codigoProveedor}'),
                  subtitle: Text('${cxp.abreviaturaDocumento ?? cxp.codigoDocumento}-${cxp.serieDocumento ?? '0001'}-${cxp.numeroDocumento} | ${cxp.fechaEmision}'),
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

// ── Consolidado dialog ────────────────────────────────────────────────────────

class _ConsolidadoDialog extends StatefulWidget {
  final CxPBloc bloc;
  const _ConsolidadoDialog({required this.bloc});
  @override State<_ConsolidadoDialog> createState() => _ConsolidadoDialogState();
}

class _ConsolidadoDialogState extends State<_ConsolidadoDialog> {
  List<CuentaPagar> _all = [];
  bool _loading = true;
  String _error = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final ds = getIt<CxPRemoteDataSource>();
      final res = await ds.list(pendiente: true, limit: 500);
      final items = (res['data'] as List)
          .map((j) => CuentaPagar.fromJson(j as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _all = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.toLowerCase();
    final filtered = q.isEmpty ? _all : _all.where((c) =>
      (c.razonSocialProveedor ?? c.codigoProveedor).toLowerCase().contains(q) ||
      c.codigoProveedor.toLowerCase().contains(q),
    ).toList();

    final Map<String, List<CuentaPagar>> grouped = {};
    for (final c in filtered) grouped.putIfAbsent(c.codigoProveedor, () => []).add(c);

    final proveedores = grouped.keys.toList()
      ..sort((a, b) {
        final sa = grouped[a]!.fold(0.0, (s, c) => s + c.saldo);
        final sb = grouped[b]!.fold(0.0, (s, c) => s + c.saldo);
        return sb.compareTo(sa);
      });

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Consolidado CxP',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Buscar proveedor...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              if (!_loading && filtered.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${proveedores.length} proveedor(es)',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      'Total: S/ ${filtered.fold(0.0, (s, c) => s + c.saldo).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ]),
                ),
              const SizedBox(height: 4),
              if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
              if (_error.isNotEmpty)
                Expanded(child: Center(child: Text(_error,
                    style: const TextStyle(color: Colors.red)))),
              if (!_loading && proveedores.isEmpty && _error.isEmpty)
                const Expanded(child: Center(child: Text('Sin cuentas pendientes'))),
              if (!_loading && proveedores.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: proveedores.length,
                    itemBuilder: (_, i) {
                      final code = proveedores[i];
                      final docs = grouped[code]!;
                      final totalSaldo = docs.fold(0.0, (s, c) => s + c.saldo);
                      return _ProveedorGroup(
                        code: code,
                        name: docs.first.razonSocialProveedor ?? code,
                        totalSaldo: totalSaldo,
                        docs: docs,
                        onDocTap: _onDocTap,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDocTap(CuentaPagar cxp) async {
    final docLabel =
        '${cxp.abreviaturaDocumento ?? cxp.codigoDocumento}-${cxp.serieDocumento ?? '0001'}-${cxp.numeroDocumento}';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (alertCtx) => AlertDialog(
        title: const Text('Registrar pago'),
        content: Text(
            '¿Desea registrar el pago de $docLabel?\nSaldo: S/ ${cxp.saldo.toStringAsFixed(2)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(alertCtx, false),
              child: const Text('No')),
          ElevatedButton(
              onPressed: () => Navigator.pop(alertCtx, true),
              child: const Text('Sí')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    _showPagoForm(cxp);
  }

  void _showPagoForm(CuentaPagar cxp) {
    final voucherCtrl = TextEditingController();
    final montoCtrl   = TextEditingController(text: cxp.saldo.toStringAsFixed(2));
    final operCtrl    = TextEditingController();
    List<TipoPago> tiposPago = [];
    TipoPago? tipoPagoSeleccionado;
    bool fetched = false;
    DateTime fecha    = DateTime.now();

    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(builder: (dctx, setSt) {
        if (!fetched) {
          fetched = true;
          getIt<TablasRemoteDataSource>().list('tipos-pago', activo: true).then((raw) {
            setSt(() => tiposPago = raw.map(TablaModel.tipoPagoFromJson).toList());
          }).catchError((_) {});
        }
        return AlertDialog(
        title: const Text('Registrar Pago'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Saldo: S/ ${cxp.saldo.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(controller: voucherCtrl,
              decoration: const InputDecoration(labelText: 'N° Voucher')),
          const SizedBox(height: 8),
          NumberFormField(controller: montoCtrl,
              decoration: const InputDecoration(labelText: 'Monto')),
          const SizedBox(height: 8),
          DropdownButtonFormField<TipoPago>(
            value: tipoPagoSeleccionado,
            decoration: const InputDecoration(labelText: 'Tipo Pago'),
            items: tiposPago.map((t) => DropdownMenuItem(value: t, child: Text(t.descripcion))).toList(),
            onChanged: (v) => setSt(() {
              tipoPagoSeleccionado = v;
              operCtrl.clear();
            }),
          ),
          if (tipoPagoSeleccionado?.requiereOperacion == true)
            TextField(controller: operCtrl,
                decoration: const InputDecoration(labelText: 'N° Operación')),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Fecha: ${fecha.toIso8601String().substring(0, 10)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(
                context: dctx,
                initialDate: fecha,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setSt(() => fecha = d);
            },
          ),
        ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final m = double.tryParse(montoCtrl.text);
              if (voucherCtrl.text.isEmpty || m == null || m <= 0 || tipoPagoSeleccionado == null) return;
              widget.bloc.add(CxPRegistrarPago(
                cuentaPagarId: cxp.id,
                numeroVoucher: voucherCtrl.text.trim(),
                fecha: fecha.toIso8601String().substring(0, 10),
                tipoPago: tipoPagoSeleccionado!.descripcion,
                monto: m,
                numeroOperacion:
                    operCtrl.text.isNotEmpty ? operCtrl.text.trim() : null,
              ));
              Navigator.pop(dctx);    // close pago dialog
              Navigator.pop(context); // close consolidado dialog
            },
            child: const Text('Guardar'),
          ),
        ],
      );}),
    );
  }
}

// ── Proveedor group row ──────────────────────────────────────────────────────

class _ProveedorGroup extends StatefulWidget {
  final String code, name;
  final double totalSaldo;
  final List<CuentaPagar> docs;
  final void Function(CuentaPagar) onDocTap;
  const _ProveedorGroup({
    required this.code, required this.name, required this.totalSaldo,
    required this.docs, required this.onDocTap,
  });
  @override State<_ProveedorGroup> createState() => _ProveedorGroupState();
}

class _ProveedorGroupState extends State<_ProveedorGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(children: [
        ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.red.shade100,
            child: Text(
              widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(widget.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text('${widget.docs.length} pendiente(s)',
              style: const TextStyle(fontSize: 11)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('S/ ${widget.totalSaldo.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 13)),
            const SizedBox(width: 4),
            Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18),
          ]),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded) ...[
          const Divider(height: 0, indent: 16, endIndent: 16),
          ...widget.docs.map((doc) {
            final docLabel =
                '${doc.abreviaturaDocumento ?? doc.codigoDocumento}-${doc.serieDocumento ?? '0001'}-${doc.numeroDocumento}';
            final vencida = doc.fechaVencimiento != null &&
                DateTime.tryParse(doc.fechaVencimiento!)
                    ?.isBefore(DateTime.now()) ==
                    true;
            return InkWell(
              onTap: () => widget.onDocTap(doc),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Icon(
                    vencida ? Icons.warning_amber : Icons.receipt_long,
                    color: vencida ? Colors.red : Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(docLabel,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500)),
                          Text(
                            doc.fechaEmision +
                                (doc.fechaVencimiento != null
                                    ? ' · Venc: ${doc.fechaVencimiento}'
                                    : ''),
                            style: TextStyle(
                                fontSize: 10,
                                color: vencida ? Colors.red : Colors.grey),
                          ),
                        ]),
                  ),
                  Text('S/ ${doc.saldo.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: vencida ? Colors.red : Colors.redAccent,
                          fontSize: 12)),
                ]),
              ),
            );
          }),
        ],
      ]),
    );
  }
}
