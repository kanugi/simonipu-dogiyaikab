import 'package:intl/intl.dart';

class DateFormatter {
  static String formatFull(DateTime dateTime) {
    return DateFormat('EEEE, d MMMM yyyy - HH:mm', 'id_ID').format(dateTime);
  }

  static String formatDateOnly(DateTime dateTime) {
    return DateFormat('d MMMM yyyy', 'id_ID').format(dateTime);
  }

  static String formatTimeOnly(DateTime dateTime) {
    return DateFormat('HH:mm:ss', 'id_ID').format(dateTime);
  }

  static String formatShortDate(DateTime dateTime) {
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  /// Format compact untuk watermark foto — singkat, jelas, padat
  static String formatWatermark(DateTime dateTime) {
    return DateFormat('dd-MM-yyyy HH:mm:ss', 'id_ID').format(dateTime);
  }
}
