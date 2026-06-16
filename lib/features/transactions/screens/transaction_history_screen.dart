import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../utils/category_utils.dart';
import '../../dashboard/widgets/recent_transaction_tile.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  String _filter = 'All'; // All, Credit, Debit, Cash, Bank
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final _filters = ['All', 'Credit', 'Debit', 'Cash', 'Bank'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> txs) {
    return txs.where((tx) {
      // Type filter
      if (_filter == 'Credit' && !tx.isCredit) return false;
      if (_filter == 'Debit' && !tx.isDebit) return false;
      if (_filter == 'Cash' && !tx.isCash) return false;
      if (_filter == 'Bank' && tx.bankName == null) return false;
      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!tx.category.toLowerCase().contains(q) &&
            !(tx.notes?.toLowerCase().contains(q) ?? false) &&
            !(tx.bankName?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<String, List<TransactionModel>> _groupByMonth(
      List<TransactionModel> txs) {
    return groupBy(txs, (tx) => DateFormatter.formatMonthYear(tx.date));
  }

  @override
  Widget build(BuildContext context) {
    final txStream = ref.watch(
        StreamProvider((ref) => ref.watch(transactionRepositoryProvider).watchTransactions()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.addCredit),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filters.length,
              itemBuilder: (context, i) {
                final f = _filters[i];
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.secondary.withOpacity(0.2),
                    checkmarkColor: AppColors.secondary,
                    labelStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? AppColors.secondary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),

          // Transaction list
          Expanded(
            child: txStream.when(
              data: (txs) {
                final filtered = _applyFilters(txs);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('No transactions found',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                final grouped = _groupByMonth(filtered);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: grouped.length,
                  itemBuilder: (context, i) {
                    final month = grouped.keys.elementAt(i);
                    final monthTxs = grouped[month]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            month,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        ...monthTxs.map(
                          (tx) => RecentTransactionTile(
                            transaction: tx,
                            onTap: () =>
                                context.push('/app/transactions/${tx.id}'),
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addDebit),
        tooltip: 'Add Debit',
        child: const Icon(Icons.remove),
      ),
    );
  }
}
