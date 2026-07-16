import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../domain/repositories/tipo_cambio_repository.dart';
import '../bloc/tipo_cambio_bloc.dart';
import '../bloc/tipo_cambio_event.dart';
import '../bloc/tipo_cambio_state.dart';

class TipoCambioPage extends StatelessWidget {
  const TipoCambioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TipoCambioBloc(getIt<TipoCambioRepository>())
        ..add(TipoCambioCheckHoy()),
      child: const _TipoCambioView(),
    );
  }
}

class _TipoCambioView extends StatefulWidget {
  const _TipoCambioView();

  @override
  State<_TipoCambioView> createState() => _TipoCambioViewState();
}

class _TipoCambioViewState extends State<_TipoCambioView> {
  final _formKey = GlobalKey<FormState>();
  final _tcController = TextEditingController();

  @override
  void dispose() {
    _tcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hoy = DateTime.now();
    final fechaStr =
        '${hoy.day.toString().padLeft(2, '0')}/${hoy.month.toString().padLeft(2, '0')}/${hoy.year}';

    return BlocListener<TipoCambioBloc, TipoCambioState>(
      listener: (context, state) {
        if (state is TipoCambioYaRegistrado || state is TipoCambioRegistradoExitoso) {
          context.go('/home');
        }
        if (state is TipoCambioError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: cs.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tipo de Cambio'),
          automaticallyImplyLeading: false,
        ),
        body: BlocBuilder<TipoCambioBloc, TipoCambioState>(
          builder: (context, state) {
            if (state is TipoCambioLoading || state is TipoCambioInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              Icons.currency_exchange,
                              size: 48,
                              color: cs.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Registrar Tipo de Cambio',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fechaStr,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _tcController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              autofocus: true,
                              decoration: InputDecoration(
                                labelText: 'Tipo de Cambio (S/. por USD)',
                                prefixText: 'S/. ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Ingrese el tipo de cambio';
                                }
                                final n = double.tryParse(v.replaceAll(',', '.'));
                                if (n == null || n <= 0) {
                                  return 'Ingrese un valor válido mayor a 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () => _submit(context),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text('Registrar'),
                              ),
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

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final value = double.parse(_tcController.text.replaceAll(',', '.'));
    context.read<TipoCambioBloc>().add(TipoCambioRegistrar(value));
  }
}
