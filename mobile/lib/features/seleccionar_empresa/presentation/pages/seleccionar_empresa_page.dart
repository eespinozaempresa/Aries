import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/aries_app_bar.dart';
import '../../../../core/widgets/number_form_field.dart';
import '../../../auth/domain/entities/empresa_opcion.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../tipo_cambio/domain/repositories/tipo_cambio_repository.dart';
import '../../seleccionar_empresa_args.dart';
import '../bloc/seleccionar_empresa_bloc.dart';
import '../bloc/seleccionar_empresa_event.dart';
import '../bloc/seleccionar_empresa_state.dart';

class SeleccionarEmpresaPage extends StatelessWidget {
  final SeleccionarEmpresaArgs? args;
  const SeleccionarEmpresaPage({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    final resolvedArgs = args ?? const SeleccionarEmpresaArgs.cambiarEmpresa();
    return BlocProvider(
      create: (_) => SeleccionarEmpresaBloc(
        authRepo: getIt<AuthRepository>(),
        tipoCambioRepo: getIt<TipoCambioRepository>(),
        args: resolvedArgs,
      )..add(SeleccionarEmpresaIniciar()),
      child: const _SeleccionarEmpresaView(),
    );
  }
}

class _SeleccionarEmpresaView extends StatefulWidget {
  const _SeleccionarEmpresaView();

  @override
  State<_SeleccionarEmpresaView> createState() => _SeleccionarEmpresaViewState();
}

class _SeleccionarEmpresaViewState extends State<_SeleccionarEmpresaView> {
  final _formKey = GlobalKey<FormState>();
  final _tcController = TextEditingController();

  @override
  void dispose() {
    _tcController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, SeleccionarEmpresaListo state) {
    if (!_formKey.currentState!.validate()) return;
    final valor = state.tipoCambioRequerido
        ? double.parse(_tcController.text.replaceAll(',', '.'))
        : null;
    context.read<SeleccionarEmpresaBloc>().add(SeleccionarEmpresaConfirmar(tipoCambioValor: valor));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fechaStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return BlocListener<SeleccionarEmpresaBloc, SeleccionarEmpresaState>(
      listener: (context, state) {
        if (state is SeleccionarEmpresaExitoso) {
          context.go('/home');
        } else if (state is SeleccionarEmpresaListo && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: cs.error,
          ));
        } else if (state is SeleccionarEmpresaErrorInicial) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: cs.error,
          ));
        }
      },
      child: Scaffold(
        appBar: const AriesAppBar(
          title: Text('Seleccionar Empresa'),
          automaticallyImplyLeading: false,
        ),
        body: BlocBuilder<SeleccionarEmpresaBloc, SeleccionarEmpresaState>(
          builder: (context, state) {
            if (state is SeleccionarEmpresaErrorInicial) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(state.message, textAlign: TextAlign.center),
                ),
              );
            }
            if (state is! SeleccionarEmpresaListo) {
              return const Center(child: CircularProgressIndicator());
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(Icons.domain, size: 48, color: cs.primary),
                            const SizedBox(height: 16),
                            Text(
                              'Seleccione la empresa',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),

                            DropdownButtonFormField<EmpresaOpcion>(
                              initialValue: state.empresaSeleccionada,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Empresa',
                                prefixIcon: Icon(Icons.domain_outlined),
                                border: OutlineInputBorder(),
                              ),
                              items: state.empresas
                                  .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e.nombre, overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: state.empresas.length > 1
                                  ? (e) {
                                      if (e != null) {
                                        context.read<SeleccionarEmpresaBloc>().add(SeleccionarEmpresaElegir(e));
                                      }
                                    }
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 18, color: cs.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Text(fechaStr, style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                            const SizedBox(height: 20),

                            if (state.cargandoPreview)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              )
                            else if (state.tipoCambioRequerido)
                              NumberFormField(
                                controller: _tcController,
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de Cambio (S/. por USD)',
                                  prefixText: 'S/. ',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Ingrese el tipo de cambio';
                                  final n = double.tryParse(v);
                                  if (n == null || n <= 0) return 'Ingrese un valor válido mayor a 0';
                                  return null;
                                },
                              )
                            else
                              Row(
                                children: [
                                  Icon(Icons.currency_exchange, size: 18, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tipo de Cambio: S/. ${state.tipoCambioHoy?.toStringAsFixed(4) ?? '-'}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            const SizedBox(height: 24),

                            FilledButton(
                              onPressed: state.confirmando || state.cargandoPreview
                                  ? null
                                  : () => _submit(context, state),
                              child: state.confirmando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : const Text('Aceptar'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: state.confirmando
                                  ? null
                                  : () {
                                      final modo = context.read<SeleccionarEmpresaBloc>().args.modo;
                                      context.go(modo == SeleccionarEmpresaModo.postLogin ? '/login' : '/home');
                                    },
                              child: const Text('Cancelar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
