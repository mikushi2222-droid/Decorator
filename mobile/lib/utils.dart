import 'package:intl/intl.dart';

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
