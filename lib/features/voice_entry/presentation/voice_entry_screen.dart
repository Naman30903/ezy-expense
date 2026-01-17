import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/voice_entry_provider.dart';
import '../services/voice_expense_parser.dart';
import '../../../core/theme/app_theme.dart';

/// Voice-activated expense entry screen.
class VoiceEntryScreen extends ConsumerWidget {
  const VoiceEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceEntryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Text(
              'Tap the mic and speak your expense',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Example: "Spent 50 rupees on Uber yesterday"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),

            // Animated Mic Button
            _MicButton(
              isListening: state.isListening,
              onPressed: () {
                if (state.isListening) {
                  ref.read(voiceEntryProvider.notifier).stopListening();
                } else {
                  ref.read(voiceEntryProvider.notifier).startListening();
                }
              },
            ),
            const SizedBox(height: 32),

            // Live Transcript
            if (state.currentTranscript.isNotEmpty || state.isListening)
              _TranscriptCard(
                transcript: state.currentTranscript,
                isListening: state.isListening,
              ),

            // Parsed Result
            if (state.parsedExpense != null && !state.isSaved)
              _ParsedExpenseCard(
                expense: state.parsedExpense!,
                onConfirm: () =>
                    ref.read(voiceEntryProvider.notifier).confirmExpense(),
                onCancel: () =>
                    ref.read(voiceEntryProvider.notifier).reset(),
              ),

            // Success Message
            if (state.isSaved)
              _SuccessCard(
                onAddAnother: () =>
                    ref.read(voiceEntryProvider.notifier).reset(),
              ),

            // Error Message
            if (state.error != null)
              _ErrorCard(
                error: state.error!,
                onDismiss: () =>
                    ref.read(voiceEntryProvider.notifier).reset(),
              ),

            // Processing Indicator
            if (state.isProcessing)
              const Center(child: CircularProgressIndicator()),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// Animated microphone button
class _MicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;

  const _MicButton({
    required this.isListening,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isListening ? 120 : 100,
          height: isListening ? 120 : 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isListening ? AppColors.error : AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: (isListening ? AppColors.error : AppColors.primary)
                    .withValues(alpha: 0.4),
                blurRadius: isListening ? 30 : 15,
                spreadRadius: isListening ? 10 : 5,
              ),
            ],
          ),
          child: Icon(
            isListening ? Icons.stop : Icons.mic,
            size: 48,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Live transcript display card
class _TranscriptCard extends StatelessWidget {
  final String transcript;
  final bool isListening;

  const _TranscriptCard({
    required this.transcript,
    required this.isListening,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isListening)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error,
                    ),
                  ),
                Text(
                  isListening ? 'Listening...' : 'You said:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              transcript.isEmpty ? '...' : transcript,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Parsed expense preview card
class _ParsedExpenseCard extends StatelessWidget {
  final ParsedVoiceExpense expense;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ParsedExpenseCard({
    required this.expense,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parsed Expense',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                  ),
            ),
            const SizedBox(height: 16),
            _buildRow(context, 'Amount', '₹${expense.amount.toStringAsFixed(2)}'),
            _buildRow(context, 'Merchant', expense.merchant),
            _buildRow(context, 'Category', expense.category),
            _buildRow(context, 'Date', DateFormat('dd MMM yyyy').format(expense.date)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Success confirmation card
class _SuccessCard extends StatelessWidget {
  final VoidCallback onAddAnother;

  const _SuccessCard({required this.onAddAnother});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.success.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 48),
            const SizedBox(height: 8),
            Text(
              'Expense Saved!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                  ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAddAnother,
              child: const Text('Add Another'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error display card
class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;

  const _ErrorCard({
    required this.error,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 32),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onDismiss,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
