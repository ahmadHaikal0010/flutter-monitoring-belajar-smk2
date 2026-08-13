import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DateHelper {
  static const List<String> _monthsIndonesian = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static Future<void> initLocale() async {
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (_) {}
  }

  static String formatDateTime(String? isoDate) {
    if (isoDate == null || isoDate.trim().isEmpty) {
      return 'Tidak ada tenggat';
    }

    try {
      final cleanIso = isoDate.trim().replaceAll(' ', 'T');
      final dt = DateTime.parse(cleanIso).toLocal();
      
      try {
        return DateFormat('d MMM y, HH:mm', 'id_ID').format(dt);
      } catch (_) {
        // Fallback manual formatting if intl locale symbols fail
        final day = dt.day;
        final month = _monthsIndonesian[dt.month - 1];
        final year = dt.year;
        final hour = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        return '$day $month $year, $hour:$minute';
      }
    } catch (_) {
      return isoDate;
    }
  }
}
