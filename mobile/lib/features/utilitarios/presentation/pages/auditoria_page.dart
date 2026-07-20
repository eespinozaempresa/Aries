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
        queryParameters: {'limit': 100},
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
      return _fmt.format(DateTime.parse(raw).toLocal());
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
                      itemBuilder: (ctx, i) => _AuditoriaItem(
                        entry: _entries[i],
                        formatFecha: _formatFecha,
                      ),
                    ),
    );
  }
}

class _AuditoriaItem extends StatelessWidget {
  final Map<String, dynamic> entry;
  final String Function(String?) formatFecha;

  const _AuditoriaItem({required this.entry, required this.formatFecha});

  @override
  Widget build(BuildContext context) {
    final tipo         = (entry['tipo'] as String? ?? '').toUpperCase();
    final usuarioCodigo = entry['usuario_codigo']?.toString() ?? '';
    final fecha        = formatFecha(entry['fecha_hora']?.toString());
    final ip           = entry['ip']?.toString() ?? '';

    final Color bgColor;
    final Color iconColor;
    final IconData icon;
    final String tipoLabel;

    switch (tipo) {
      case 'LOGIN':
        bgColor   = Colors.green.shade100;
        iconColor = Colors.green.shade700;
        icon      = Icons.login_outlined;
        tipoLabel = 'Inicio de sesión';
        break;
      case 'LOGIN_FAIL':
        bgColor   = Colors.orange.shade100;
        iconColor = Colors.orange.shade800;
        icon      = Icons.warning_amber_rounded;
        tipoLabel = 'Intento fallido';
        break;
      default: // LOGOUT
        bgColor   = Colors.red.shade100;
        iconColor = Colors.red.shade700;
        icon      = Icons.logout_outlined;
        tipoLabel = 'Cierre de sesión';
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: bgColor,
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Row(
        children: [
          Text(
            tipoLabel,
            style: TextStyle(fontWeight: FontWeight.w600, color: iconColor),
          ),
          if (usuarioCodigo.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                usuarioCodigo,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(fecha),
      trailing: ip.isNotEmpty
          ? Text(ip, style: Theme.of(context).textTheme.bodySmall)
          : null,
    );
  }
}
