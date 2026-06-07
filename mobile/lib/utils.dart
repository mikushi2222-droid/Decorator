import 'package:intl/intl.dart';
import 'models.dart';

final _rub = NumberFormat('#,##0.00', 'ru_RU');
final _num = NumberFormat('#,##0.##', 'ru_RU');
final _dateFmt = DateFormat('d MMMM yyyy г.', 'ru_RU');
final _dateShort = DateFormat('dd.MM.yyyy', 'ru_RU');

String formatCurrency(double v) => '${_rub.format(v)} ₽';
String formatNumber(double v) => _num.format(v);
String formatDate(DateTime d) => _dateFmt.format(d);
String formatDateShort(DateTime d) => _dateShort.format(d);

String generateInvoiceNumber(int last) {
  final now = DateTime.now();
  final seq = (last + 1).toString().padLeft(3, '0');
  return 'АКЦ-${now.year}-$seq';
}

// ─── CSV helpers ─────────────────────────────────────────────────────────────

const _csvHeader = 'name,unit,price,coverage,pack_size,category,description';

String _csvQuote(String s) {
  if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

String productsAsCsv(List<Product> products) {
  final sb = StringBuffer()..writeln(_csvHeader);
  for (final p in products) {
    sb.writeln([
      _csvQuote(p.name),
      _csvQuote(p.unit),
      p.price.toStringAsFixed(2),
      p.coverage.toStringAsFixed(4),
      p.packSize.toStringAsFixed(2),
      _csvQuote(p.category),
      _csvQuote(p.description),
    ].join(','));
  }
  return sb.toString();
}

List<Map<String, dynamic>> parseCsvProducts(String csv) {
  final lines = csv.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  if (lines.length < 2) return [];
  final result = <Map<String, dynamic>>[];
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final f = _parseCsvLine(line);
    if (f.isEmpty || f[0].trim().isEmpty) continue;
    result.add({
      'name': f[0].trim(),
      'unit': f.length > 1 ? f[1].trim() : 'шт.',
      'price': f.length > 2 ? (double.tryParse(f[2]) ?? 0) : 0.0,
      'coverage': f.length > 3 ? (double.tryParse(f[3]) ?? 0) : 0.0,
      'pack_size': f.length > 4 ? (double.tryParse(f[4]) ?? 0) : 0.0,
      'category': f.length > 5 ? f[5].trim() : '',
      'description': f.length > 6 ? f[6].trim() : '',
    });
  }
  return result;
}

List<String> _parseCsvLine(String line) {
  final fields = <String>[];
  var buf = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buf.write(c);
      }
    } else {
      if (c == '"') {
        inQuotes = true;
      } else if (c == ',') {
        fields.add(buf.toString());
        buf = StringBuffer();
      } else {
        buf.write(c);
      }
    }
  }
  fields.add(buf.toString());
  return fields;
}
