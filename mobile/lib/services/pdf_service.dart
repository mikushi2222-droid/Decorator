import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models.dart';
import '../utils.dart';

class PdfService {
  static Future<Uint8List> buildInvoicePdf(Invoice invoice, StoreSettings settings) async {
    final pdf = pw.Document();

    // Шрифты грузим из bundled-ассетов (работает офлайн). Если ассет почему-то
    // отсутствует — подстраховываемся загрузкой из сети, чтобы PDF не падал.
    final regularFont = await _loadFont('assets/fonts/NotoSans-Regular.ttf', PdfGoogleFonts.notoSansRegular);
    final boldFont    = await _loadFont('assets/fonts/NotoSans-Bold.ttf',    PdfGoogleFonts.notoSansBold);
    final italicFont  = await _loadFont('assets/fonts/NotoSans-Italic.ttf',  PdfGoogleFonts.notoSansItalic);

    final brand = PdfColor.fromHex('#1E3A4A');
    final logo = await _loadLogo('assets/logo_akcent.jpg');

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont, italic: italicFont),
      build: (ctx) => [
        // Header: seller info
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null) ...[
              pw.Container(
                width: 54,
                height: 54,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 10),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(settings.name.isEmpty ? 'Организация' : settings.name,
                      style: pw.TextStyle(font: boldFont, fontSize: 14, color: brand)),
                  if (settings.address.isNotEmpty)
                    pw.Text(settings.address, style: pw.TextStyle(fontSize: 9)),
                  if (settings.phone.isNotEmpty)
                    pw.Text('Тел.: ${settings.phone}', style: pw.TextStyle(fontSize: 9)),
                  if (settings.inn.isNotEmpty)
                    pw.Text('ИНН: ${settings.inn}  КПП: ${settings.kpp}', style: pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('НАКЛАДНАЯ', style: pw.TextStyle(font: boldFont, fontSize: 18, color: brand)),
                pw.Text('№ ${invoice.number}', style: pw.TextStyle(font: boldFont, fontSize: 13)),
                pw.Text('от ${formatDate(invoice.date)}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: brand, thickness: 1.5),
        pw.SizedBox(height: 8),

        // Buyer
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F0F4F6'),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            children: [
              pw.Text('ПОКУПАТЕЛЬ: ', style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.grey700)),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(invoice.clientName, style: pw.TextStyle(font: boldFont, fontSize: 12)),
                    if (invoice.clientPhone.isNotEmpty)
                      pw.Text(invoice.clientPhone, style: pw.TextStyle(fontSize: 9)),
                    if (invoice.clientAddress.isNotEmpty)
                      pw.Text(invoice.clientAddress, style: pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // Items table
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(0.5),
            1: const pw.FlexColumnWidth(4),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.8),
            4: const pw.FlexColumnWidth(1.8),
          },
          children: [
            // Table header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: brand),
              children: [
                _th('№', boldFont),
                _th('Наименование', boldFont),
                _th('Кол-во', boldFont, align: pw.TextAlign.center),
                _th('Цена, ₽', boldFont, align: pw.TextAlign.right),
                _th('Сумма, ₽', boldFont, align: pw.TextAlign.right),
              ],
            ),
            // Item rows
            ...invoice.items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              final bg = idx.isOdd ? PdfColor.fromHex('#F8FAFB') : PdfColors.white;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: bg),
                children: [
                  _td('${idx + 1}', regularFont, align: pw.TextAlign.center),
                  _td(item.productName, regularFont),
                  _td('${formatNumber(item.quantity)} ${item.unit}', regularFont, align: pw.TextAlign.center),
                  _td(formatCurrency(item.price), regularFont, align: pw.TextAlign.right),
                  _td(formatCurrency(item.total), boldFont, align: pw.TextAlign.right),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 10),

        // Totals
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 240,
            child: pw.Column(
              children: [
                _totRow('Подытог:', formatCurrency(invoice.subtotal), regularFont, boldFont),
                if (invoice.discount > 0)
                  _totRow('Скидка:', '− ${formatCurrency(invoice.discount)}', regularFont, boldFont,
                      valueColor: PdfColors.red700),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ИТОГО К ОПЛАТЕ:', style: pw.TextStyle(font: boldFont, fontSize: 12, color: brand)),
                    pw.Text(formatCurrency(invoice.total),
                        style: pw.TextStyle(font: boldFont, fontSize: 16, color: brand)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Notes
        if (invoice.notes.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text('Примечания:', style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(invoice.notes, style: pw.TextStyle(font: italicFont, fontSize: 10)),
        ],

        pw.SizedBox(height: 16),
        pw.Divider(color: brand),

        // Bank details
        if (settings.bankName.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text('Банковские реквизиты:', style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 3),
          pw.Wrap(
            spacing: 16,
            runSpacing: 2,
            children: [
              if (settings.bankName.isNotEmpty) _bankField('Банк', settings.bankName, regularFont, boldFont),
              if (settings.bankBik.isNotEmpty) _bankField('БИК', settings.bankBik, regularFont, boldFont),
              if (settings.bankAccount.isNotEmpty) _bankField('Р/с', settings.bankAccount, regularFont, boldFont),
              if (settings.bankCorrAccount.isNotEmpty) _bankField('К/с', settings.bankCorrAccount, regularFont, boldFont),
            ],
          ),
        ],

        // Ad text
        if (settings.adText.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(settings.adText,
                style: pw.TextStyle(font: italicFont, fontSize: 9, color: PdfColors.grey600)),
          ),
        ],
      ],
    ));

    return pdf.save();
  }

  static Future<pw.Font> _loadFont(String asset, Future<pw.Font> Function() fallback) async {
    try {
      return pw.Font.ttf(await rootBundle.load(asset));
    } catch (_) {
      return fallback();
    }
  }

  // Логотип в шапку PDF. Если ассет недоступен — просто не рисуем (PDF не падает).
  static Future<pw.ImageProvider?> _loadLogo(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _th(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(text,
            style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.white),
            textAlign: align),
      );

  static pw.Widget _td(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10), textAlign: align),
      );

  static pw.Widget _totRow(String label, String value, pw.Font regular, pw.Font bold,
          {PdfColor? valueColor}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(font: regular, fontSize: 10, color: PdfColors.grey700)),
            pw.Text(value,
                style: pw.TextStyle(font: bold, fontSize: 10, color: valueColor ?? PdfColors.black)),
          ],
        ),
      );

  static pw.Widget _bankField(String label, String value, pw.Font regular, pw.Font bold) =>
      pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(text: '$label: ', style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.grey700)),
          pw.TextSpan(text: value, style: pw.TextStyle(font: regular, fontSize: 8)),
        ]),
      );

  static Future<void> shareInvoice(Invoice invoice, StoreSettings settings) async {
    final bytes = await buildInvoicePdf(invoice, settings);
    final filename = 'Накладная_${invoice.number.replaceAll('/', '-')}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
