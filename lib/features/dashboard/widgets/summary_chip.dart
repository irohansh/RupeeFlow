import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_theme.dart';

class SummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final bool isPositive;
  final VoidCallback? onTap;

  const SummaryChip({
    super.key,
    required this.label,
    required this.amount,
    required this.isPositive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.credit : AppColors.debit;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPositive ? Icons.call_received : Icons.call_made,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: color)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              CurrencyFormatter.formatShort(amount),
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}
