import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  final format =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  return format.format(amount);
}

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy, HH:mm').format(date);
}
