import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';

class AuditoriaPage extends StatefulWidget {
  const AuditoriaPage({super.key});

  @override
  State<AuditoriaPage> createState() => _AuditoriaPageState();
}

class _AuditoriaPageState extends State<AuditoriaPage> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = false;
  String? _error;

  static final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error   = null;
    });
    try {
      final dio      = getIt<DioClient>().dio;
      final response = await dio.get(
        '${ApiConstants.baseUrl}/utilitarios/auditoria',
        queryParameters: {'limit': 50},
      );
      final list = response.data as List<dynamic>;
      setState(() {
        _entries = list.cast<Map<String, dynamic>>();
      });
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Error al cargar auditoría';
      setState(() => _error = msg.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatFecha(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return _fmt.format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _fetch,
          ),
        ],
      ),
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
              : _entries.isEmpty
                  ? const Center(child: Text('Sin registros'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: _entries.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 64),
                      itemBuilder: (ctx, i) {
                        final e     = _entries[i];
                        final tipo  = (e['tipo'] as String? ?? '').toUpperCase();
                        final isLogin = tipo == 'LOGIN';
                        final fecha = _formatFecha(e['fecha_hora']?.toString());
                        final ip    = e['ip']?.toString();

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isLogin
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Icon(
                              isLogin
                                  ? Icons.login_outlined
                                  : Icons.logout_outlined,
                              color:
                                  isLogin ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                          title: Text(
                            tipo,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isLogin
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                          subtitle: Text(fecha),
                          trailing: ip != null && ip.isNotEmpty
                              ? Text(
                                  ip,
                                  style: Theme.of(ctx).textTheme.bodySmall,
                                )
                              : null,
                        );
                      },
                    ),
    );
  }
}
