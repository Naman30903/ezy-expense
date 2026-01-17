import 'package:flutter/material.dart';
import '../../../data/repositories/expense_repository.dart';
import 'package:intl/intl.dart';

class TransactionList extends StatelessWidget {
  final List<ExpenseWithDetails> expenses;

  const TransactionList({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(child: Text("No expenses yet. Scan SMS or Add Manual!"));
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final item = expenses[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              child: Text(item.categoryName[0]), // Icon placeholder
            ),
            title: Text(item.merchantName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('MMM dd, hh:mm a').format(item.expense.date)),
            trailing: Text(
              "₹${item.expense.amount.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}
