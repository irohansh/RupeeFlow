import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../../transactions/repositories/transaction_repository.dart';

/// Android-only SMS detection service.
/// Reads SMS inbox and extracts bank transaction messages.
class SmsDetectionService {
  final TransactionRepository _txRepo;
  final FlutterSecureStorage _storage;

  static const _channel = MethodChannel('com.rupeeflow/sms');

  SmsDetectionService(this._txRepo)
      : _storage = const FlutterSecureStorage();

  // Regex patterns for Indian bank SMS
  static final _debitPattern = RegExp(
    r'(?:debited|withdrawn|debit|paid|payment)\s*(?:of|with|for)?\s*(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final _creditPattern = RegExp(
    r'(?:credited|received|credit)\s*(?:of|with)?\s*(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final _bankPattern = RegExp(
    r'\b(HDFC|SBI|ICICI|AXIS|KOTAK|PNB|BOB|CANARA|UNION|IDBI|YES BANK)\b',
    caseSensitive: false,
  );

  Future<int> importSmsTransactions() async {
    // Check daily limit
    await _checkDailyLimit();

    try {
      final messages = await _channel.invokeListMethod<Map>('getSmsList') ?? [];
      int imported = 0;

      for (final msg in messages) {
        if (imported >= AppConstants.maxDailySmsImports) break;

        final body = msg['body'] as String? ?? '';
        final smsId = msg['id'] as String? ?? '';
        final timestamp = msg['timestamp'] as int?;
        final date = timestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(timestamp)
            : DateTime.now();

        // Check if already imported via smsId
        final debitMatch = _debitPattern.firstMatch(body);
        final creditMatch = _creditPattern.firstMatch(body);
        final bankMatch = _bankPattern.firstMatch(body);

        if (debitMatch != null) {
          final amountStr =
              debitMatch.group(1)?.replaceAll(',', '') ?? '0';
          final amount = double.tryParse(amountStr) ?? 0;
          if (amount > 0) {
            try {
              await _txRepo.createTransaction(
                amount: amount,
                type: AppConstants.smsImported,
                category: 'Other',
                date: date,
                notes: body.length > 100 ? '${body.substring(0, 100)}...' : body,
                bankName: bankMatch?.group(1),
                smsId: smsId,
              );
              imported++;
            } catch (_) {}
          }
        } else if (creditMatch != null) {
          final amountStr =
              creditMatch.group(1)?.replaceAll(',', '') ?? '0';
          final amount = double.tryParse(amountStr) ?? 0;
          if (amount > 0) {
            try {
              await _txRepo.createTransaction(
                amount: amount,
                type: AppConstants.credit,
                category: 'Salary',
                date: date,
                notes: body.length > 100 ? '${body.substring(0, 100)}...' : body,
                bankName: bankMatch?.group(1),
                smsId: smsId,
              );
              imported++;
            } catch (_) {}
          }
        }
      }

      await _incrementDailyCount(imported);
      return imported;
    } on PlatformException {
      // SMS permission denied or not Android
      return 0;
    }
  }

  Future<void> _checkDailyLimit() async {
    final date = await _storage.read(key: AppConstants.smsImportDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (date != today) {
      await _storage.write(key: AppConstants.smsImportDateKey, value: today);
      await _storage.write(key: AppConstants.smsImportCountKey, value: '0');
    }
    final count = int.tryParse(
            await _storage.read(key: AppConstants.smsImportCountKey) ?? '0') ??
        0;
    if (count >= AppConstants.maxDailySmsImports) {
      throw Exception(
          'Daily SMS import limit (${AppConstants.maxDailySmsImports}) reached');
    }
  }

  Future<void> _incrementDailyCount(int n) async {
    final current = int.tryParse(
            await _storage.read(key: AppConstants.smsImportCountKey) ?? '0') ??
        0;
    await _storage.write(
        key: AppConstants.smsImportCountKey, value: '${current + n}');
  }
}

final smsDetectionServiceProvider = Provider<SmsDetectionService>((ref) {
  return SmsDetectionService(ref.read(transactionRepositoryProvider));
});
