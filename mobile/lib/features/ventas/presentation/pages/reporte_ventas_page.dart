import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/export_service.dart';

enum _TipoReporte { ventas, general }
enum _SubtipoVentas { general, detallado }

class ReporteVentasPage extends StatefulWidget {
  const ReporteVentasPage({super.key});
  @override
  State<ReporteVentasPage> createState() => _ReporteVentasPageState();
}

class _ReporteVentasPageState extends State<ReporteVentasPage> {
  _TipoReporte _tipo     = _TipoReporte.ventas;
  _SubtipoVentas _subtipo = _SubtipoVentas.general;

  DateTime _desde = DateTime.now().subtract(const Duration(days: 30));
  DateTime _hasta = DateTime.now();

  String? _almacenV;
  String? _tipoVentaV;
  String? _almacenG;
  String? _clienteG;
  String? _articuloG;
  String? _usuarioG;

  List<_Combo> _almacenes = [];
  List<_Combo> _clientes  = [];
  List<_Combo> _articulos = [];
  List<_Combo> _usuarios  = [];
  bool _loadingCombos = true;

  List<dynamic> _results  = [];
  bool _generating = false;
  bool _hasResults = false;
  String? _error;

  static final _dateFmt    = DateFormat('dd/MM/yyyy');
  static final _rowDateFmt = DateFormat('dd/MM/yyyy');
  static final _numFmt     = NumberFormat('#,##0.00');

  String _fmtFecha(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try { return _rowDateFmt.format(DateTime.parse(iso)); } catch (_) { return iso; }
  }

  @override
  void initState() {
    super.initState();
    _loadCombos();
  }

  Future<void> _loadCombos() async {
    try {
      final dio = getIt<DioClient>().dio;
      final futures = await Future.wait([
        dio.get('${ApiConstants.baseUrl}/maestros/almacenes', queryParameters: {'limit': 200}),
        dio.get('${ApiConstants.baseUrl}/maestros/clientes',  queryParameters: {'limit': 500, 'page': 1}),
        dio.get('${ApiConstants.baseUrl}/maestros/articulos', queryParameters: {'limit': 500, 'page': 1}),
        dio.get('${ApiConstants.baseUrl}/utilitarios/usuarios'),
      ]);
      if (!mounted) return;
      setState(() {
        _almacenes = _toCombo(futures[0].data, 'codigo', ['descripcion']);
        _clientes  = _toCombo(futures[1].data, 'codigo', ['razonSocial', 'nombre', 'descripcion']);
        _articulos = _toCombo(futures[2].data, 'codigo', ['descripcion']);
        _usuarios  = _toCombo(futures[3].data, 'codigo', ['nombre']);
        _loadingCombos = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCombos = false);
    }
  }

  List<_Combo> _toCombo(dynamic data, String codeField, List<String> labelFields) {
    final List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else {
      return [];
    }
    return list.whereType<Map>().map((m) {
      final code = m[codeField]?.toString() ?? '';
      final label = labelFields
          .map((f) => m[f]?.toString())
          .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => code) ?? code;
      return _Combo(code, label);
    }).where((c) => c.code.isNotEmpty).toList();
  }

  Future<void> _pickDate(bool isDesde) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDesde ? _desde : _hasta,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() { if (isDesde) _desde = picked; else _hasta = picked; });
    }
  }

  Future<void> _generar() async {
    setState(() { _generating = true; _error = null; _hasResults = false; _results = []; });
    try {
      final dio     = getIt<DioClient>().dio;
      final desdeStr = _desde.toIso8601String().substring(0, 10);
      final hastaStr = _hasta.toIso8601String().substring(0, 10);

      final Response res;
      if (_tipo == _TipoReporte.ventas) {
        res = await dio.get('${ApiConstants.baseUrl}/ventas/reporte/ventas', queryParameters: {
          'tipo'  : _subtipo.name,
          'desde' : desdeStr,
          'hasta' : hastaStr,
          if (_almacenV != null) 'almacen'  : _almacenV,
          if (_tipoVentaV != null) 'tipoVenta': _tipoVentaV,
        });
      } else {
        res = await dio.get('${ApiConstants.baseUrl}/ventas/reporte/general', queryParameters: {
          'desde' : desdeStr,
          'hasta' : hastaStr,
          if (_almacenG != null) 'almacen' : _almacenG,
          if (_clienteG != null) 'cliente' : _clienteG,
          if (_articuloG != null) 'articulo': _articuloG,
          if (_usuarioG != null) 'usuario' : _usuarioG,
        });
      }
      if (mounted) {
        setState(() {
          _results    = res.data is List ? List.from(res.data) : [];
          _hasResults = true;
        });
      }
    } on DioException catch (e) {
      if (mounted) setState(() => _error = (e.response?.data?['message'] ?? 'Error al generar reporte').toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _export() {
    final period = '${_dateFmt.format(_desde)} - ${_dateFmt.format(_hasta)}';
    final List<String> columns;
    final List<List<String>> rows;
    final String title;

    if (_tipo == _TipoReporte.ventas) {
      if (_subtipo == _SubtipoVentas.general) {
        title   = 'Reporte de Ventas General';
        columns = ['Tipo Venta', 'Fecha', 'Doc.', 'Serie', 'Núm.', 'Cliente', 'Anulado', 'SubTotal', 'IGV', 'Total'];
        rows    = _results.whereType<Map<String, dynamic>>().map((r) => [
          r['tipoVenta']?.toString() ?? '',
          _fmtFecha(r['fecha']?.toString()),
          r['documento']?.toString() ?? '',
          r['serie']?.toString() ?? '',
          r['numero']?.toString() ?? '',
          r['cliente']?.toString() ?? '',
          r['anulado'] == true ? 'Sí' : 'No',
          _numFmt.format(r['subtotal'] ?? 0),
          _numFmt.format(r['igv']     ?? 0),
          _numFmt.format(r['total']   ?? 0),
        ]).toList();
      } else {
        title   = 'Reporte de Ventas Detallado';
        columns = ['Tipo Venta', 'Fecha', 'Doc.', 'Serie', 'Núm.', 'Cliente', 'Artículo', 'UM', 'Cantidad', 'Total'];
        rows    = _results.whereType<Map<String, dynamic>>().map((r) => [
          r['tipoVenta']?.toString() ?? '',
          _fmtFecha(r['fecha']?.toString()),
          r['documento']?.toString() ?? '',
          r['serie']?.toString() ?? '',
          r['numero']?.toString() ?? '',
          r['cliente']?.toString() ?? '',
          r['articulo']?.toString() ?? '',
          r['unidadMedida']?.toString() ?? '',
          _numFmt.format(r['cantidad'] ?? 0),
          _numFmt.format(r['total']   ?? 0),
        ]).toList();
      }
    } else {
      title   = 'Reportes Generales de Ventas';
      columns = ['Línea', 'Fecha', 'Cliente', 'Almacén', 'Usuario', 'Artículo', 'UM', 'Cantidad', 'Total'];
      rows    = _results.whereType<Map<String, dynamic>>().map((r) => [
        r['linea']?.toString() ?? '',
        _fmtFecha(r['fecha']?.toString()),
        r['cliente']?.toString() ?? '',
        r['almacen']?.toString() ?? '',
        r['usuario']?.toString() ?? '',
        r['articulo']?.toString() ?? '',
        r['unidadMedida']?.toString() ?? '',
        _numFmt.format(r['cantidad'] ?? 0),
        _numFmt.format(r['total']   ?? 0),
      ]).toList();
    }

    ExportService.showExportDialog(
      context: context,
      title: title,
      columns: columns,
      rows: rows,
      subtitle: period,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Ventas'),
        actions: [
          if (_hasResults && _results.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Descargar reporte',
              onPressed: _export,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTipoSelector(),
          const SizedBox(height: 12),
          _buildFilters(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _generar,
              icon: _generating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow_outlined),
              label: Text(_generating ? 'Generando...' : 'Generar Reporte'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (_hasResults) ...[
            const SizedBox(height: 20),
            _buildResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildTipoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_TipoReporte>(
          segments: const [
            ButtonSegment(value: _TipoReporte.ventas,  label: Text('Reporte de Ventas'),    icon: Icon(Icons.receipt_long_outlined)),
            ButtonSegment(value: _TipoReporte.general, label: Text('Reportes Generales'),   icon: Icon(Icons.bar_chart_outlined)),
          ],
          selected: {_tipo},
          onSelectionChanged: (s) => setState(() { _tipo = s.first; _hasResults = false; }),
        ),
        if (_tipo == _TipoReporte.ventas) ...[
          const SizedBox(height: 8),
          SegmentedButton<_SubtipoVentas>(
            segments: const [
              ButtonSegment(value: _SubtipoVentas.general,   label: Text('General')),
              ButtonSegment(value: _SubtipoVentas.detallado, label: Text('Detallado')),
            ],
            selected: {_subtipo},
            onSelectionChanged: (s) => setState(() { _subtipo = s.first; _hasResults = false; }),
          ),
        ],
      ],
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: _DateField(label: 'Desde', date: _desde, onTap: () => _pickDate(true))),
          const SizedBox(width: 8),
          Expanded(child: _DateField(label: 'Hasta', date: _hasta, onTap: () => _pickDate(false))),
        ]),
        const SizedBox(height: 8),
        if (_tipo == _TipoReporte.ventas) ...[
          _dropdown('Almacén', _almacenes, _almacenV,   (v) => setState(() => _almacenV   = v)),
          const SizedBox(height: 8),
          _dropdown('Tipo de Venta',
            [_Combo('CONTADO', 'Contado'), _Combo('CREDITO', 'Crédito')],
            _tipoVentaV, (v) => setState(() => _tipoVentaV = v)),
        ] else ...[
          _dropdown('Almacén',  _almacenes, _almacenG,  (v) => setState(() => _almacenG  = v)),
          const SizedBox(height: 8),
          _dropdown('Cliente',  _clientes,  _clienteG,  (v) => setState(() => _clienteG  = v)),
          const SizedBox(height: 8),
          _dropdown('Artículo', _articulos, _articuloG, (v) => setState(() => _articuloG = v)),
          const SizedBox(height: 8),
          _dropdown('Usuario',  _usuarios,  _usuarioG,  (v) => setState(() => _usuarioG  = v)),
        ],
      ],
    );
  }

  Widget _dropdown(String label, List<_Combo> items, String? value, ValueChanged<String?> onChange) {
    final valid = items.any((i) => i.code == value) ? value : null;
    return DropdownButtonFormField<String>(
      value: valid,
      decoration: InputDecoration(labelText: label, isDense: true),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Todos')),
        ...items.map((i) => DropdownMenuItem<String>(
          value: i.code,
          child: Text(i.label, overflow: TextOverflow.ellipsis),
        )),
      ],
      onChanged: onChange,
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Sin resultados para los filtros seleccionados', textAlign: TextAlign.center),
      ));
    }
    return _tipo == _TipoReporte.ventas ? _ventasResults() : _generalResults();
  }

  // ── Reporte de Ventas ────────────────────────────────────────────────────────

  Widget _ventasResults() {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final item in _results.whereType<Map<String, dynamic>>()) {
      final key = item['tipoVenta']?.toString() ?? 'OTRO';
      (groups[key] ??= []).add(item);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((e) {
        final label     = e.key == 'CREDITO' ? 'Crédito' : 'Contado';
        final rows      = e.value;
        final totalGrp  = rows.fold<double>(0, (s, r) => s + (r['total']  as num? ?? 0));
        final subtotGrp = rows.fold<double>(0, (s, r) => s + (r['subtotal'] as num? ?? 0));
        final igvGrp    = rows.fold<double>(0, (s, r) => s + (r['igv']    as num? ?? 0));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(label),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _subtipo == _SubtipoVentas.general
                  ? _tableGeneral(rows)
                  : _tableDetallado(rows),
            ),
            if (_subtipo == _SubtipoVentas.general)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                child: Text(
                  'SubTotal: ${_numFmt.format(subtotGrp)}  IGV: ${_numFmt.format(igvGrp)}  Total: ${_numFmt.format(totalGrp)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                child: Text('Total: ${_numFmt.format(totalGrp)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _tableGeneral(List<Map<String, dynamic>> rows) {
    return DataTable(
      columnSpacing: 10,
      dataRowMinHeight: 30,
      dataRowMaxHeight: 44,
      columns: _cols(['Fecha', 'Doc.', 'Serie', 'Núm.', 'Cliente', 'Anulado', 'SubTotal', 'IGV', 'Total']),
      rows: rows.map((r) => DataRow(cells: [
        _cell(_fmtFecha(r['fecha']?.toString())),
        _cell(r['documento']?.toString() ?? ''),
        _cell(r['serie']?.toString() ?? ''),
        _cell(r['numero']?.toString() ?? ''),
        _cellWide(r['cliente']?.toString() ?? '', 130),
        DataCell(Text(r['anulado'] == true ? 'Sí' : 'No',
            style: TextStyle(fontSize: 11, color: r['anulado'] == true ? Colors.red : null))),
        _cellNum(_numFmt.format(r['subtotal'] ?? 0)),
        _cellNum(_numFmt.format(r['igv']      ?? 0)),
        _cellNum(_numFmt.format(r['total']    ?? 0), bold: true),
      ])).toList(),
    );
  }

  Widget _tableDetallado(List<Map<String, dynamic>> rows) {
    return DataTable(
      columnSpacing: 10,
      dataRowMinHeight: 30,
      dataRowMaxHeight: 44,
      columns: _cols(['Fecha', 'Doc.', 'Serie', 'Núm.', 'Cliente', 'Producto', 'UM', 'Cantidad', 'Total']),
      rows: rows.map((r) => DataRow(cells: [
        _cell(_fmtFecha(r['fecha']?.toString())),
        _cell(r['documento']?.toString() ?? ''),
        _cell(r['serie']?.toString() ?? ''),
        _cell(r['numero']?.toString() ?? ''),
        _cellWide(r['cliente']?.toString() ?? '', 100),
        _cellWide(r['articulo']?.toString() ?? '', 120),
        _cell(r['unidadMedida']?.toString() ?? ''),
        _cellNum(_numFmt.format(r['cantidad'] ?? 0)),
        _cellNum(_numFmt.format(r['total']    ?? 0), bold: true),
      ])).toList(),
    );
  }

  // ── Reportes Generales ───────────────────────────────────────────────────────

  Widget _generalResults() {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final item in _results.whereType<Map<String, dynamic>>()) {
      final key = '${item['codigoLinea'] ?? ''}||${item['linea'] ?? 'Sin línea'}';
      (groups[key] ??= []).add(item);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((e) {
        final label      = e.key.split('||').last;
        final rows       = e.value;
        final totalGrp   = rows.fold<double>(0, (s, r) => s + (r['total']    as num? ?? 0));
        final cantidadGrp = rows.fold<double>(0, (s, r) => s + (r['cantidad'] as num? ?? 0));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Línea: $label'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 10,
                dataRowMinHeight: 30,
                dataRowMaxHeight: 44,
                columns: _cols(['Fecha', 'Cliente', 'Almacén', 'Usuario', 'Artículo', 'UM', 'Cantidad', 'Total']),
                rows: rows.map((r) => DataRow(cells: [
                  _cell(_fmtFecha(r['fecha']?.toString())),
                  _cellWide(r['cliente']?.toString() ?? '', 130),
                  _cellWide(r['almacen']?.toString() ?? '', 100),
                  _cell(r['usuario']?.toString() ?? ''),
                  _cellWide(r['articulo']?.toString() ?? '', 150),
                  _cell(r['unidadMedida']?.toString() ?? ''),
                  _cellNum(_numFmt.format(r['cantidad'] ?? 0)),
                  _cellNum(_numFmt.format(r['total']    ?? 0), bold: true),
                ])).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              child: Text(
                'Cant: ${_numFmt.format(cantidadGrp)}  Total: ${_numFmt.format(totalGrp)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: cs.primaryContainer,
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
    );
  }

  List<DataColumn> _cols(List<String> names) =>
      names.map((n) => DataColumn(label: Text(n, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))).toList();

  DataCell _cell(String v) => DataCell(Text(v, style: const TextStyle(fontSize: 11)));

  DataCell _cellWide(String v, double maxW) => DataCell(ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxW),
    child: Text(v, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
  ));

  DataCell _cellNum(String v, {bool bold = false}) => DataCell(Text(v,
      style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)));
}

// ── Data classes ─────────────────────────────────────────────────────────────

class _Combo {
  final String code;
  final String label;
  const _Combo(this.code, this.label);
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  static final _fmt = DateFormat('dd/MM/yyyy');
  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
        ),
        child: Text(_fmt.format(date), style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
