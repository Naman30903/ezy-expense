import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sms_ledger_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/sms_expense_card.dart';

/// Screen displaying auto-parsed SMS transactions for user review.
class SmsLedgerScreen extends ConsumerStatefulWidget {
  const SmsLedgerScreen({super.key});

  @override
  ConsumerState<SmsLedgerScreen> createState() => _SmsLedgerScreenState();
}

class _SmsLedgerScreenState extends ConsumerState<SmsLedgerScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-fetch SMS on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smsLedgerProvider.notifier).fetchNewSms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsLedgerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Ledger'),
        actions: [
          if (state.pendingTransactions.isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  ref.read(smsLedgerProvider.notifier).confirmAll(),
              icon: const Icon(Icons.done_all),
              label: const Text('Confirm All'),
            ),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.read(smsLedgerProvider.notifier).fetchNewSms(),
        icon: const Icon(Icons.refresh),
        label: const Text('Scan SMS'),
      ),
    );
  }

  Widget _buildBody(SmsLedgerState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning SMS messages...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(smsLedgerProvider.notifier).fetchNewSms(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.pendingTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No new transactions found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Scan SMS" to check for new transactions',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: state.pendingTransactions.length,
      itemBuilder: (context, index) {
        final transaction = state.pendingTransactions[index];
        return SmsExpenseCard(
          transaction: transaction,
          onConfirm: () =>
              ref.read(smsLedgerProvider.notifier).confirmTransaction(index),
          onReject: () =>
              ref.read(smsLedgerProvider.notifier).rejectTransaction(index),
        );
      },
    );
  }
}
