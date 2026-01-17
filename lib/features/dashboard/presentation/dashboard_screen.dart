import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../sms_reader/providers/sms_ledger_provider.dart';

/// Dashboard screen showing expense summary and recent transactions.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<ExpenseWithDetails> _expenses = [];
  bool _isLoading = true;
  double _totalExpenses = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    
    try {
      final repository = ref.read(expenseRepositoryProvider);
      final now = DateTime.now();
      final expenses = await repository.getExpensesForMonth(now.year, now.month);
      
      double total = 0;
      for (var e in expenses) {
        total += e.expense.amount;
      }
      
      setState(() {
        _expenses = expenses;
        _totalExpenses = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadExpenses,
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Expense Tracker'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'This Month',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${_totalExpenses.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Recent Transactions Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${_expenses.length} items',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          // Transactions List
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_expenses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No expenses yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first expense using the + button',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final expense = _expenses[index];
                  return _ExpenseListItem(expense: expense);
                },
                childCount: _expenses.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpenseListItem extends StatelessWidget {
  final ExpenseWithDetails expense;

  const _ExpenseListItem({required this.expense});

  @override
  Widget build(BuildContext context) {
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

    final color = categoryColors[expense.categoryName] ?? AppColors.other;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            expense.categoryName[0],
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          expense.merchantName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          DateFormat('dd MMM, hh:mm a').format(expense.expense.date),
        ),
        trailing: Text(
          '₹${expense.expense.amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
