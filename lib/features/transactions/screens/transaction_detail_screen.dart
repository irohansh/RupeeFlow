import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../utils/category_utils.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txFuture = ref.watch(FutureProvider<TransactionModel?>(
        (ref) => ref.read(transactionRepositoryProvider).getTransaction(transactionId)));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Transaction'),
                  content: const Text('Are you sure you want to delete this transaction?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(transactionRepositoryProvider).deleteTransaction(transactionId);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: txFuture.when(
        data: (tx) {
          if (tx == null) {
            return const Center(child: Text('Transaction not found'));
          }
          final isCredit = tx.isCredit;
          final amountColor = isCredit ? AppColors.credit : AppColors.debit;
          final catData = CategoryUtils.getCategoryData(tx.category);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Amount hero
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: amountColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: catData.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(catData.icon, color: catData.color, size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        CurrencyFormatter.formatWithSign(tx.amount, isCredit: isCredit),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: amountColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: amountColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isCredit ? 'Credit' : (tx.isCash ? 'Cash Debit' : 'Bank Debit'),
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: amountColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Details card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _DetailRow(label: 'Category', value: tx.category),
                        _DetailRow(label: 'Date', value: DateFormatter.formatDate(tx.date)),
                        _DetailRow(label: 'Time', value: DateFormatter.formatTime(tx.date)),
                        if (tx.bankName != null)
                          _DetailRow(label: 'Bank', value: tx.bankName!),
                        if (tx.notes != null)
                          _DetailRow(label: 'Notes', value: tx.notes!),
                        _DetailRow(
                          label: 'Transaction ID',
                          value: tx.id.substring(0, 8).toUpperCase(),
                        ),
                        _DetailRow(
                          label: 'Added On',
                          value: DateFormatter.formatDateTime(tx.createdAt),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
