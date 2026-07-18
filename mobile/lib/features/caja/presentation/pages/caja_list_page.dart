import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../data/datasources/caja_remote_datasource.dart';
import '../../domain/entities/sesion_caja.dart';
import '../bloc/caja_bloc.dart';

class CajaListPage extends StatefulWidget {
  const CajaListPage({super.key});
  @override
  State<CajaListPage> createState() => _State();
}

class _State extends State<CajaListPage> {
  final _scroll = ScrollController();

  @override
  void initState() { super.initState(); _scroll.addListener(_onScroll); }
  @override
  void dispose() { _scroll.dispose(); super.dispose(); }
  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<CajaBloc>().add(CajaLoad());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CajaBloc(getIt<CajaRemoteDataSource>())..add(CajaLoad(reset: true)),
      child: Builder(builder: (ctx) => Scaffold(
        appBar: AppBar(title: const Text('Caja')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAbrirDialog(ctx),
          icon: const Icon(Icons.add),
          label: const Text('Abrir caja'),
        ),
        body: BlocConsumer<CajaBloc, CajaState>(
          listener: (c, s) {
            if (s is CajaError) {
              ScaffoldMessenger.of(c).showSnackBar(
              SnackBar(content: Text(s.message), backgroundColor: Colors.red));
            }
            if (s is CajaAbierta) {
              ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Caja abierta')));
              ctx.read<CajaBloc>().add(CajaLoad(reset: true));
            }
          },
          builder: (c, s) {
            if (s is CajaLoading) return const Center(child: CircularProgressIndicator());
            final items = switch (s) {
              CajaListLoaded(:final items) => items,
              _ => <SesionCaja>[],
            };
            if (items.isEmpty) return const Center(child: Text('Sin sesiones de caja'));
            return ListView.builder(
              controller: _scroll,
              itemCount: items.length + 1,
              itemBuilder: (_, i) {
                if (i == items.length) {
                  final loaded = s is CajaListLoaded;
                  return loaded && s.currentPage < s.lastPage
                    ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                    : const SizedBox();
                }
                final sesion = items[i];
                return ListTile(
                  onTap: () => ctx.go('/caja/${sesion.id}'),
                  leading: CircleAvatar(
                    backgroundColor: sesion.estado == EstadoCaja.ABIERTA ? Colors.green[100] : Colors.grey[200],
                    child: Icon(
                      sesion.estado == EstadoCaja.ABIERTA ? Icons.lock_open : Icons.lock,
                      color: sesion.estado == EstadoCaja.ABIERTA ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Text('Caja ${sesion.codigoCaja}'),
                  subtitle: Text('${sesion.fechaApertura.substring(0, 16)} — ${sesion.codigoUsuario}'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Chip(
                      label: Text(sesion.estado.name, style: const TextStyle(fontSize: 11)),
                      backgroundColor: sesion.estado == EstadoCaja.ABIERTA ? Colors.green[100] : Colors.grey[200],
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text('Apertura: S/ ${sesion.montoApertura.toStringAsFixed(2)}',
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

  void _showAbrirDialog(BuildContext ctx) {
    final cajaCtrl  = TextEditingController();
    final montoCtrl = TextEditingController(text: '0');

    showDialog(context: ctx, builder: (dctx) => AlertDialog(
      title: const Text('Abrir Caja'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: cajaCtrl, decoration: const InputDecoration(labelText: 'Código caja (ej: CAJA01)')),
        const SizedBox(height: 8),
        TextField(controller: montoCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto apertura (S/)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            final m = double.tryParse(montoCtrl.text) ?? 0;
            if (cajaCtrl.text.isEmpty) return;
            Navigator.pop(dctx);
            ctx.read<CajaBloc>().add(CajaAbrir(codigoCaja: cajaCtrl.text.trim().toUpperCase(), montoApertura: m));
          },
          child: const Text('Abrir'),
        ),
      ],
    ));
  }
}
