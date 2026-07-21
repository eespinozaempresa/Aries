import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _fileTimestampFmt = DateFormat('yyyyMMddHHmmss');

  /// Formatea una fecha ISO (yyyy-MM-dd o datetime) a dd/MM/yyyy.
  /// Si no puede parsear, retorna [fallback].
  static String fmtDate(String? iso, {String fallback = '-'}) {
    if (iso == null || iso.isEmpty) return fallback;
    try {
      return _dateFmt.format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  /// Nombre de archivo a partir del título, con fecha y hora agregadas
  /// (ej. "Ventas_20260721145502"), para que cada descarga tenga nombre único.
  static String _fileBaseName(String title) {
    final safe = title.replaceAll(RegExp(r'[^\w]'), '_');
    return '${safe}_${_fileTimestampFmt.format(DateTime.now())}';
  }

  /// Exporta a PDF y abre el visor de impresión/compartir
  static Future<void> exportPdf({
    required BuildContext context,
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
    String? subtitle,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          if (subtitle != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 10)),
          ],
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: columns,
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
            cellAlignments: {for (var i = 0; i < columns.length; i++) i: pw.Alignment.centerLeft},
            columnWidths: null,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save(), name: _fileBaseName(title));
  }

  /// Exporta a Excel y comparte el archivo
  static Future<void> exportExcel({
    required BuildContext context,
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
  }) async {
    try {
      final excelDoc  = Excel.createExcel();
      final sheetName = title.replaceAll(RegExp(r'[\\\/?*:\[\]]'), '').trim();
      final safeSheet = sheetName.substring(0, sheetName.length.clamp(0, 31));
      excelDoc.rename('Sheet1', safeSheet);
      final sheet = excelDoc[safeSheet];

      sheet.appendRow(columns.map((c) => TextCellValue(c)).toList());
      for (final row in rows) {
        sheet.appendRow(row.map((cell) => TextCellValue(cell)).toList());
      }

      final fname = _fileBaseName(title);
      // En Web, excelDoc.save() ya dispara la descarga del navegador como
      // efecto secundario (con el fileName indicado); llamar además a
      // Share.shareXFiles ahí produciría una segunda descarga duplicada.
      final bytes = excelDoc.save(fileName: '$fname.xlsx');
      if (bytes == null) throw Exception('No se pudo generar el archivo Excel');

      if (!kIsWeb) {
        await Share.shareXFiles(
          [XFile.fromData(
            Uint8List.fromList(bytes),
            name: '$fname.xlsx',
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          )],
          subject: title,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Muestra un diálogo para elegir formato
  static Future<void> showExportDialog({
    required BuildContext context,
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
    String? subtitle,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Exportar a PDF'),
              onTap: () async {
                Navigator.pop(ctx);
                await exportPdf(context: context, title: title, columns: columns, rows: rows, subtitle: subtitle);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Exportar a Excel'),
              onTap: () async {
                Navigator.pop(ctx);
                await exportExcel(context: context, title: title, columns: columns, rows: rows);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
