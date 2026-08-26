import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(double value) {
    return _currencyFormatter.format(value);
  }

  static String formatShort(double value) {
    if (value >= 1000000000) {
      double milyar = value / 1000000000;
      return 'Rp ${milyar.toStringAsFixed(milyar.truncateToDouble() == milyar ? 0 : 2)} M';
    } else if (value >= 1000000) {
      double juta = value / 1000000;
      return 'Rp ${juta.toStringAsFixed(juta.truncateToDouble() == juta ? 0 : 1)} Jt';
    }
    return _currencyFormatter.format(value);
  }
}
