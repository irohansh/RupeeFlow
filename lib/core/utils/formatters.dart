import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static final _indianFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  static final _indianFormatterWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  /// Format amount as ₹1,25,000
  static String format(double amount) {
    if (amount == amount.truncate()) {
      return _indianFormatter.format(amount);
    }
    return _indianFormatterWithDecimals.format(amount);
  }

  /// Format with sign: +₹5,000 or -₹1,200
  static String formatWithSign(double amount, {bool isCredit = true}) {
    final formatted = format(amount.abs());
    return isCredit ? '+$formatted' : '-$formatted';
  }

  /// Parse ₹ string to double
  static double? parse(String value) {
    final cleaned = value.replaceAll(AppConstants.currencySymbol, '').replaceAll(',', '').trim();
    return double.tryParse(cleaned);
  }

  /// Short format: ₹1.25L, ₹25K
  static String formatShort(double amount) {
    if (amount >= 10000000) {
      return '${AppConstants.currencySymbol}${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '${AppConstants.currencySymbol}${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${AppConstants.currencySymbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }
}

class DateFormatter {
  static String formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(date);

  static String formatTime(DateTime date) =>
      DateFormat('hh:mm a').format(date);

  static String formatMonthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return formatDate(date);
  }

  static String formatDueDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.inDays < 0) return 'Overdue by ${(-diff.inDays)} days';
    if (diff.inDays == 0) return 'Due Today';
    if (diff.inDays == 1) return 'Due Tomorrow';
    if (diff.inDays < 7) return 'Due in ${diff.inDays} days';
    return 'Due on ${formatDate(date)}';
  }
}
