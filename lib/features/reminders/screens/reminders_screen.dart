import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../repositories/reminder_repository.dart';
import '../models/reminder_model.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersStream = ref.watch(
        StreamProvider((ref) => ref.watch(reminderRepositoryProvider).watchReminders()));

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: remindersStream.when(
        data: (reminders) {
          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No reminders set',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Add reminders for due dates or payments',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13)),
                ],
              ),
            );
          }

          final pending =
              reminders.where((r) => !r.isDone).toList();
          final done = reminders.where((r) => r.isDone).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                Text('Upcoming',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...pending.asMap().entries.map((e) => _ReminderCard(
                      reminder: e.value,
                      ref: ref,
                    ).animate().fadeIn(delay: Duration(milliseconds: e.key * 60))),
                const SizedBox(height: 24),
              ],
              if (done.isNotEmpty) ...[
                Text('Completed',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                const SizedBox(height: 8),
                ...done.map((r) => _ReminderCard(reminder: r, ref: ref)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addReminder),
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final WidgetRef ref;

  const _ReminderCard({required this.reminder, required this.ref});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (reminder.isDone) {
      statusColor = AppColors.credit;
    } else if (reminder.isOverdue) {
      statusColor = AppColors.debit;
    } else if (reminder.isDueToday) {
      statusColor = AppColors.pending;
    } else {
      statusColor = AppColors.secondary;
    }

    final typeIcon = reminder.type == 'due_date'
        ? Icons.event_outlined
        : reminder.type == 'payment'
            ? Icons.payment_outlined
            : Icons.call_received_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(typeIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.title,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: reminder.isDone
                              ? TextDecoration.lineThrough
                              : null)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.formatDueDate(reminder.dueDate),
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: reminder.isOverdue && !reminder.isDone
                            ? AppColors.debit
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  if (reminder.notes != null) ...[
                    const SizedBox(height: 4),
                    Text(reminder.notes!,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ],
              ),
            ),
            // Actions
            if (!reminder.isDone)
              IconButton(
                icon: const Icon(Icons.check_circle_outline, size: 20),
                color: AppColors.credit,
                onPressed: () => ref
                    .read(reminderRepositoryProvider)
                    .markDone(reminder.id),
                tooltip: 'Mark done',
              ),
          ],
        ),
      ),
    );
  }
}
