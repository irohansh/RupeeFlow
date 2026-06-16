import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../repositories/loan_repository.dart';
import '../models/loan_model.dart';

class DebtTrackerScreen extends ConsumerStatefulWidget {
  const DebtTrackerScreen({super.key});

  @override
  ConsumerState<DebtTrackerScreen> createState() => _DebtTrackerScreenState();
}

class _DebtTrackerScreenState extends ConsumerState<DebtTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loanSummary = ref.watch(
        StreamProvider((ref) => ref.watch(loanRepositoryProvider).watchLoanSummary()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lent'),
            Tab(text: 'Borrowed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary
          loanSummary.when(
            data: (s) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Total Lent',
                      amount: s['lent'] ?? 0,
                      pending: s['pendingReceivables'] ?? 0,
                      color: AppColors.credit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Total Borrowed',
                      amount: s['borrowed'] ?? 0,
                      pending: s['pendingPayables'] ?? 0,
                      color: AppColors.debit,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(height: 80),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 12),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _LoanList(type: 'lent'),
                _LoanList(type: 'borrowed'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addDebt),
        icon: const Icon(Icons.add),
        label: const Text('Add Debt'),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final double pending;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.pending,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color)),
          const SizedBox(height: 4),
          Text(CurrencyFormatter.formatShort(amount),
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 2),
          Text('Pending: ${CurrencyFormatter.formatShort(pending)}',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _LoanList extends ConsumerWidget {
  final String type;

  const _LoanList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansStream = ref.watch(StreamProvider((ref) =>
        ref.watch(loanRepositoryProvider).watchLoansByType(type)));

    return loansStream.when(
      data: (loans) {
        if (loans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  type == 'lent'
                      ? 'No money lent yet'
                      : 'No borrowed money tracked',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: loans.length,
          itemBuilder: (ctx, i) => _LoanCard(loan: loans[i]).animate().fadeIn(
              delay: Duration(milliseconds: i * 60)),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _LoanCard extends ConsumerWidget {
  final LoanModel loan;

  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = loan.computedStatus;
    final statusColor = status == 'completed'
        ? AppColors.credit
        : status == 'overdue'
            ? AppColors.debit
            : AppColors.pending;
    final statusLabel = status == 'completed'
        ? 'Completed'
        : status == 'overdue'
            ? 'Overdue'
            : 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      loan.personName.isNotEmpty
                          ? loan.personName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loan.personName,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(loan.phoneNumber,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Amount row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    Text(CurrencyFormatter.format(loan.amount),
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Remaining',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    Text(
                      CurrencyFormatter.format(loan.remainingAmount),
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: loan.isFullyPaid
                              ? AppColors.credit
                              : AppColors.debit),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: loan.amount > 0 ? loan.amountPaid / loan.amount : 0,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                  loan.isFullyPaid ? AppColors.credit : statusColor),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Text(
              DateFormatter.formatDueDate(loan.dueDate),
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: status == 'overdue'
                      ? AppColors.debit
                      : Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (!loan.isFullyPaid) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _recordPayment(context, ref),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40)),
                  child: const Text('Record Payment'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _recordPayment(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            prefixText: '₹ ',
            hintText: 'Amount paid',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final a = double.tryParse(controller.text);
              Navigator.pop(ctx, a);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount != null && amount > 0) {
      await ref.read(loanRepositoryProvider).recordPayment(loan.id, amount);
    }
  }
}
