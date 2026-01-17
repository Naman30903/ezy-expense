import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/budget_provider.dart';
import '../budget_setup_dialog.dart';

/// A card widget showing budget status on the dashboard.
class BudgetCard extends ConsumerWidget {
  const BudgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(budgetProvider);

    if (state.isLoading) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => _showBudgetDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: state.status == BudgetStatus.noBudget
              ? _buildNoBudgetView(context)
              : _buildBudgetView(context, state),
        ),
      ),
    );
  }

  Widget _buildNoBudgetView(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.savings_outlined, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set a Budget',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Track your monthly spending',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 16),
      ],
    );
  }

  Widget _buildBudgetView(BuildContext context, BudgetState state) {
    final statusColor = _getStatusColor(state.status);
    final progress = state.spendPercentage / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly Budget',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.statusMessage,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(statusColor),
          ),
        ),
        const SizedBox(height: 12),

        // Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              context,
              'Spent',
              '₹${state.totalSpent.toStringAsFixed(0)}',
            ),
            _buildStatItem(
              context,
              'Budget',
              '₹${state.budgetLimit?.toStringAsFixed(0) ?? '0'}',
            ),
            _buildStatItem(
              context,
              'Remaining',
              '₹${state.remaining.toStringAsFixed(0)}',
              color: state.remaining < 0 ? AppColors.error : null,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Insight
        Text(
          'Safe daily: ₹${state.safeDaily.toStringAsFixed(0)} • Day ${state.dayOfMonth}/${state.daysInMonth}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getStatusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.safe:
        return AppColors.success;
      case BudgetStatus.caution:
        return AppColors.warning;
      case BudgetStatus.danger:
        return AppColors.error;
      case BudgetStatus.noBudget:
        return AppColors.onSurfaceVariant;
    }
  }

  void _showBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const BudgetSetupDialog(),
    );
  }
}
