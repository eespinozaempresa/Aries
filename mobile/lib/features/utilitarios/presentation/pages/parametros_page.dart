import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/aries_app_bar.dart';
import '../../../../core/widgets/number_form_field.dart';

class ParametrosPage extends StatefulWidget {
  const ParametrosPage({super.key});

  @override
  State<ParametrosPage> createState() => _ParametrosPageState();
}

class _ParametrosPageState extends State<ParametrosPage> {
  final _formKey              = GlobalKey<FormState>();
  final _igvCtrl              = TextEditingController();
  final _tiempoCtrl           = TextEditingController();

  bool _loading               = false;
  bool _saving                = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _igvCtrl.dispose();
    _tiempoCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error   = null;
    });
    try {
      final dio = getIt<DioClient>().dio;
      final response = await dio.get(
        '${ApiConstants.baseUrl}/utilitarios/parametros',
      );
      final data = response.data as Map<String, dynamic>;
      _igvCtrl.text    = (data['igv'] ?? 0).toString();
      _tiempoCtrl.text = (data['tiempoFinanciamiento'] ?? 0).toString();
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Error al cargar parámetros';
      setState(() => _error = msg.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final dio = getIt<DioClient>().dio;
      await dio.put(
        '${ApiConstants.baseUrl}/utilitarios/parametros',
        data: {
          'igv':                 double.tryParse(_igvCtrl.text.trim()) ?? 0.0,
          'tiempoFinanciamiento': int.tryParse(_tiempoCtrl.text.trim()) ?? 0,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parámetros actualizados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Error';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AriesAppBar(title: const Text('Parámetros')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetch,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NumberFormField(
                          controller: _igvCtrl,
                          decoration: const InputDecoration(
                            labelText: 'IGV (%)',
                            prefixIcon: Icon(Icons.percent),
                            helperText: 'Valor entre 0 y 100',
                          ),
                          validator: (v) {
                            final d = double.tryParse(v ?? '');
                            if (d == null) return 'Ingrese un número válido';
                            if (d < 0 || d > 100) return 'Debe estar entre 0 y 100';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        NumberFormField(
                          controller: _tiempoCtrl,
                          allowDecimal: false,
                          decoration: const InputDecoration(
                            labelText: 'Tiempo de financiamiento (días)',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null) return 'Ingrese un número entero';
                            if (n < 0) return 'Debe ser mayor o igual a 0';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving ? null : () => context.pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _submit,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save, size: 18),
                              label: const Text('Guardar'),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
    );
  }
}
