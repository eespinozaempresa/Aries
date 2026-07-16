import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
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

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  /// Exporta a Excel y comparte el archivo
  static Future<void> exportExcel({
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[title.replaceAll(RegExp(r'[^\w\s]'), '').trim().substring(0, title.length.clamp(0, 31))];

    // Encabezados
    final headerRow = columns.map((c) => TextCellValue(c)).toList();
    sheet.appendRow(headerRow);

    // Datos
    for (final row in rows) {
      sheet.appendRow(row.map((cell) => TextCellValue(cell)).toList());
    }

    // Guardar archivo temporal
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/${title.replaceAll(' ', '_')}.xlsx');
    final bytes = excel.save();
    if (bytes == null) return;
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], subject: title);
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
                await exportExcel(title: title, columns: columns, rows: rows);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
