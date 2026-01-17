import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/sms_parser.dart';
import '../../../../core/theme/app_theme.dart';

/// A card widget displaying a parsed SMS expense for user review.
class SmsExpenseCard extends StatelessWidget {
  final ParsedTransaction transaction;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  const SmsExpenseCard({
    super.key,
    required this.transaction,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.transactionType == 'credit';
    final amountColor = isCredit ? AppColors.success : AppColors.error;
    final amountPrefix = isCredit ? '+' : '-';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Merchant + Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction.merchant,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$amountPrefix₹${transaction.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Category Chip + Date
            Row(
              children: [
                _buildCategoryChip(context),
                const Spacer(),
                if (transaction.transactionDate != null)
                  Text(
                    DateFormat('dd MMM, hh:mm a')
                        .format(transaction.transactionDate!),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // UPI Reference if available
            if (transaction.upiRef != null) ...[
              Text(
                'UPI Ref: ${transaction.upiRef}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    final categoryColors = {
      'Food': AppColors.food,
      'Transport': AppColors.transport,
      'Shopping': AppColors.shopping,
      'Entertainment': AppColors.entertainment,
      'Health': AppColors.health,
      'Bills': AppColors.bills,
      'Education': AppColors.education,
      'Other': AppColors.other,
    };

    final color = categoryColors[transaction.suggestedCategory] ?? AppColors.other;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        transaction.suggestedCategory,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
