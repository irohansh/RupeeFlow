import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../transactions/repositories/transaction_repository.dart';
import '../../debts/repositories/loan_repository.dart';
import '../../transactions/models/transaction_model.dart';
import '../widgets/balance_card.dart';
import '../widgets/summary_chip.dart';
import '../widgets/recent_transaction_tile.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final summaryStream = ref.watch(
        StreamProvider((ref) => ref.watch(transactionRepositoryProvider).watchSummary()));
    final loanSummaryStream = ref.watch(
        StreamProvider((ref) => ref.watch(loanRepositoryProvider).watchLoanSummary()));
    final recentTxStream = ref.watch(
        StreamProvider((ref) => ref.watch(transactionRepositoryProvider).watchTransactions()));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.currency_rupee, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text('RupeeFlow',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outlined),
                onPressed: () => context.push(AppRoutes.profile),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(AppRoutes.reminders),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Balance card
                summaryStream.when(
                  data: (summary) => BalanceCard(
                    balance: summary['balance'] ?? 0,
                    credit: summary['credit'] ?? 0,
                    debit: summary['debit'] ?? 0,
                  ),
                  loading: () => const BalanceCardSkeleton(),
                  error: (e, _) => const SizedBox(),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Loan summary chips
                loanSummaryStream.when(
                  data: (ls) => Row(
                    children: [
                      Expanded(
                        child: SummaryChip(
                          label: 'Receivables',
                          amount: ls['pendingReceivables'] ?? 0,
                          isPositive: true,
                          onTap: () => context.go(AppRoutes.debts),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryChip(
                          label: 'Payables',
                          amount: ls['pendingPayables'] ?? 0,
                          isPositive: false,
                          onTap: () => context.go(AppRoutes.debts),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(height: 56),
                  error: (e, _) => const SizedBox(),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 20),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.addCredit),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Credit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.credit,
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.addDebit),
                        icon: const Icon(Icons.remove, size: 18),
                        label: const Text('Add Debit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.debit,
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 24),

                // Recent transactions header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Transactions',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.transactions),
                      child: const Text('See All'),
                    ),
                  ],
                ).animate().fadeIn(delay: 250.ms),

                // Recent transactions list
                recentTxStream.when(
                  data: (txs) {
                    final recent = txs.take(5).toList();
                    if (recent.isEmpty) {
                      return const _EmptyTransactions();
                    }
                    return Column(
                      children: recent
                          .asMap()
                          .entries
                          .map(
                            (e) => RecentTransactionTile(
                              transaction: e.value,
                              onTap: () => context.push(
                                  '/app/transactions/${e.value.id}'),
                            ).animate().fadeIn(
                                delay: Duration(milliseconds: 300 + e.key * 50)),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('No transactions yet',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'Inter')),
          const SizedBox(height: 8),
          const Text('Add your first credit or debit',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
        ],
      ),
    );
  }
}
