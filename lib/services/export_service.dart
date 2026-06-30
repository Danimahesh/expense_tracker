import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';
import '../utils/categories.dart';
import '../utils/payment_methods.dart';

/// Handles PDF / Excel export and database backup & restore.
class ExportService {
  ExportService._();

  static final DateFormat _df = DateFormat('dd MMM yyyy');

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------
  static Future<void> exportPdf(
    List<Expense> expenses, {
    required String currency,
  }) async {
    final doc = pw.Document();
    final total = expenses.fold<double>(0, (s, e) => s + e.amount);

    String money(num v) =>
        '$currency${NumberFormat('#,##0.00').format(v)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Expense Report',
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                'Generated ${_df.format(DateTime.now())}  •  ${expenses.length} transactions',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.Divider(thickness: 0.8, color: PdfColors.grey400),
            ],
          ),
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFF7C5CFC)),
            headerStyle: pw.TextStyle(
                color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
            },
            headers: ['Date', 'Category', 'Method', 'Description', 'Amount'],
            data: expenses
                .map((e) => [
                      _df.format(e.date),
                      Categories.byKey(e.category).label,
                      PaymentMethods.byKey(e.paymentMethod).shortLabel,
                      e.description.isEmpty ? '-' : e.description,
                      money(e.amount),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Total: ${money(total)}',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'expense_report_${_stamp()}.pdf',
    );
  }

  // ---------------------------------------------------------------------------
  // Excel
  // ---------------------------------------------------------------------------
  static Future<void> exportExcel(
    List<Expense> expenses, {
    required String currency,
  }) async {
    final book = xls.Excel.createExcel();
    final sheetName = 'Expenses';
    final xls.Sheet sheet = book[sheetName];
    book.setDefaultSheet(sheetName);

    sheet.appendRow([
      xls.TextCellValue('Date'),
      xls.TextCellValue('Category'),
      xls.TextCellValue('Payment Method'),
      xls.TextCellValue('Description'),
      xls.TextCellValue('Notes'),
      xls.TextCellValue('Amount ($currency)'),
    ]);

    for (final e in expenses) {
      sheet.appendRow([
        xls.TextCellValue(_df.format(e.date)),
        xls.TextCellValue(Categories.byKey(e.category).label),
        xls.TextCellValue(PaymentMethods.byKey(e.paymentMethod).label),
        xls.TextCellValue(e.description),
        xls.TextCellValue(e.notes),
        xls.DoubleCellValue(e.amount),
      ]);
    }

    final total = expenses.fold<double>(0, (s, e) => s + e.amount);
    sheet.appendRow([
      xls.TextCellValue(''),
      xls.TextCellValue(''),
      xls.TextCellValue(''),
      xls.TextCellValue(''),
      xls.TextCellValue('Total'),
      xls.DoubleCellValue(total),
    ]);

    final bytes = book.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel file.');
    }

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'expense_report_${_stamp()}.xlsx'));
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Expense Report',
      text: 'Expense report exported from Expense Tracker.',
    );
  }

  // ---------------------------------------------------------------------------
  // Backup & Restore
  // ---------------------------------------------------------------------------

  static Future<Directory> _backupsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copies the live DB into the backups folder and shares the file.
  /// Returns the saved backup path.
  static Future<String> backupDatabase() async {
    final dbPath = await DatabaseHelper.instance.databaseFilePath();
    final backups = await _backupsDir();
    final dest = p.join(backups.path, 'expense_backup_${_stamp()}.db');
    await File(dbPath).copy(dest);

    await Share.shareXFiles(
      [XFile(dest)],
      subject: 'Expense Tracker Backup',
      text: 'Database backup created on ${_df.format(DateTime.now())}.',
    );
    return dest;
  }

  /// Lists existing backups (newest first).
  static Future<List<FileSystemEntity>> listBackups() async {
    final backups = await _backupsDir();
    final files = backups
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList();
    files.sort((a, b) => b
        .statSync()
        .modified
        .compareTo(a.statSync().modified));
    return files;
  }

  /// Restores the database from a backup file path.
  static Future<void> restoreDatabase(String backupPath) async {
    final dbPath = await DatabaseHelper.instance.databaseFilePath();
    await DatabaseHelper.instance.close();
    await File(backupPath).copy(dbPath);
    await DatabaseHelper.instance.reopen();
  }

  static String _stamp() =>
      DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
}
