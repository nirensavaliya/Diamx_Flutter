import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/invoice.dart';
import '../models/memo.dart';

class PdfService {
  const PdfService();

  Future<String> generateAndShareMemo({
    required Memo memo,
    required List<Diamond> diamonds,
    Uint8List? signature,
    Rect? sharePositionOrigin,
  }) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Montserrat-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Montserrat-Bold.ttf'),
    );
    final document = pw.Document();
    final emerald = PdfColor.fromHex('#013A2D');
    final darkEmerald = PdfColor.fromHex('#00271F');
    final cream = PdfColor.fromHex('#F7F3EC');

    document.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: emerald, width: 1.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'DIAMX',
                style: pw.TextStyle(
                  color: darkEmerald,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              pw.Text(
                'MEMO',
                style: pw.TextStyle(
                  color: emerald,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 22),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: cream,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  memo.name,
                  style: pw.TextStyle(
                    color: darkEmerald,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  memo.description,
                  style: const pw.TextStyle(
                    color: PdfColors.grey700,
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Row(
                  children: [
                    _info('Memo No.', memo.id),
                    _info('Customer', memo.customerName),
                    _info('Date', _date(memo.date)),
                    _info('Status', memo.statusLabel),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Selected Diamonds (${diamonds.length})',
            style: pw.TextStyle(
              color: darkEmerald,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Stock No.',
              'Shape',
              'Carat',
              'Color',
              'Clarity',
              'PPC',
              'Total',
            ],
            data: diamonds
                .map(
                  (diamond) => [
                    diamond.stockNumber,
                    diamond.shape,
                    diamond.carat.toStringAsFixed(2),
                    diamond.color,
                    diamond.clarity,
                    _money(diamond.ppc),
                    _money(diamond.total),
                  ],
                )
                .toList(),
            headerDecoration: pw.BoxDecoration(color: darkEmerald),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 7,
            ),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 210,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: cream,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  _totalRow(
                    'Total Carat',
                    diamonds
                        .fold<double>(0, (sum, item) => sum + item.carat)
                        .toStringAsFixed(2),
                  ),
                  pw.SizedBox(height: 6),
                  _totalRow(
                    'Grand Total',
                    _money(
                      diamonds.fold<double>(0, (sum, item) => sum + item.total),
                    ),
                    bold: true,
                    color: emerald,
                  ),
                ],
              ),
            ),
          ),
          if (signature != null) ...[
            pw.SizedBox(height: 32),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                children: [
                  pw.Container(
                    width: 150,
                    height: 65,
                    child: pw.Image(
                      pw.MemoryImage(signature),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                  pw.Container(width: 160, height: 0.5, color: darkEmerald),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Digital Signature',
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    final bytes = await document.save();
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Diamax_${memo.id}_Memo.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Diamax Memo ${memo.id}',
        text: 'Memo PDF for ${memo.name}',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );

    return file.path;
  }

  Future<String> generateAndShareInvoice({
    required Invoice invoice,
    required List<InvoiceItem> items,
    Uint8List? signature,
    Rect? sharePositionOrigin,
  }) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Montserrat-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Montserrat-Bold.ttf'),
    );
    final document = pw.Document();
    final emerald = PdfColor.fromHex('#013A2D');
    final darkEmerald = PdfColor.fromHex('#00271F');
    final cream = PdfColor.fromHex('#F7F3EC');
    final selectedSubtotal = items.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );
    final selectedTax = selectedSubtotal * invoice.taxRate / 100;
    final selectedGrandTotal = selectedSubtotal + selectedTax;

    document.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: emerald, width: 1.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'DIAMAX',
                style: pw.TextStyle(
                  color: darkEmerald,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  color: emerald,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 22),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: cream,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  invoice.title,
                  style: pw.TextStyle(
                    color: darkEmerald,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  invoice.description,
                  style: const pw.TextStyle(
                    color: PdfColors.grey700,
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(height: 14),
                pw.Row(
                  children: [
                    _info('Invoice No.', invoice.id),
                    _info('Customer', invoice.customerName),
                    _info('Date', _date(invoice.date)),
                    _info('Due Date', _date(invoice.dueDate)),
                    _info('Status', invoice.statusLabel),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Invoice Diamonds (${items.length})',
            style: pw.TextStyle(
              color: darkEmerald,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Stock No.',
              'Shape',
              'Carat',
              'Color',
              'Clarity',
              'PPC',
              'Total',
            ],
            data: items
                .map(
                  (item) => [
                    item.stockNumber,
                    item.shape,
                    item.carat.toStringAsFixed(2),
                    item.color,
                    item.clarity,
                    _money(item.pricePerCarat),
                    _money(item.total),
                  ],
                )
                .toList(),
            headerDecoration: pw.BoxDecoration(color: darkEmerald),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 7,
            ),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 220,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: cream,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  _totalRow('Subtotal', _money(selectedSubtotal)),
                  pw.SizedBox(height: 6),
                  _totalRow(
                    'Tax (${invoice.taxRate.toStringAsFixed(0)}%)',
                    _money(selectedTax),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 7),
                    child: pw.Divider(color: PdfColors.grey400),
                  ),
                  _totalRow(
                    'Grand Total',
                    _money(selectedGrandTotal),
                    bold: true,
                    color: emerald,
                  ),
                ],
              ),
            ),
          ),
          if (signature != null) ...[
            pw.SizedBox(height: 32),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                children: [
                  pw.SizedBox(
                    width: 150,
                    height: 65,
                    child: pw.Image(
                      pw.MemoryImage(signature),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                  pw.Container(width: 160, height: 0.5, color: darkEmerald),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Authorized Signature',
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    final bytes = await document.save();
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Diamx_${invoice.id}_Invoice.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Diamx Invoice ${invoice.id}',
        text: 'Invoice PDF for ${invoice.customerName}',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );

    return file.path;
  }

  pw.Widget _info(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 7),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColors.grey900,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
    PdfColor? color,
  }) {
    final style = pw.TextStyle(
      color: color ?? PdfColors.grey800,
      fontSize: bold ? 11 : 9,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    );
  }
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
