import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/budget_provider.dart';

/// Dialog for setting monthly budget.
class BudgetSetupDialog extends ConsumerStatefulWidget {
  const BudgetSetupDialog({super.key});

  @override
  ConsumerState<BudgetSetupDialog> createState() => _BudgetSetupDialogState();
}

class _BudgetSetupDialogState extends ConsumerState<BudgetSetupDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing budget if any
    final currentBudget = ref.read(budgetProvider).budgetLimit;
    if (currentBudget != null) {
      _controller.text = currentBudget.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_controller.text);
      ref.read(budgetProvider.notifier).setBudget(amount);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Monthly Budget'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Budget Amount',
            prefixText: '₹ ',
            prefixIcon: Icon(Icons.savings_outlined),
            hintText: 'e.g., 10000',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            final parsed = double.tryParse(value);
            if (parsed == null || parsed <= 0) {
              return 'Enter a valid positive number';
            }
            return null;
          },
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveBudget,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
