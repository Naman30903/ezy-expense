import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../sms_reader/providers/sms_ledger_provider.dart';

/// Provider for BudgetRepository
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetRepository(db);
});

/// Budget status enum
enum BudgetStatus {
  safe,     // Spend % < Time %
  caution,  // Spend % ~ Time % (+/- 10%)
  danger,   // Spend % > Time %
  noBudget, // No budget set
}

/// State for budget tracking
class BudgetState {
  final double? budgetLimit;
  final double totalSpent;
  final int daysInMonth;
  final int dayOfMonth;
  final BudgetStatus status;
  final bool isLoading;
  final String? error;

  const BudgetState({
    this.budgetLimit,
    this.totalSpent = 0,
    this.daysInMonth = 30,
    this.dayOfMonth = 1,
    this.status = BudgetStatus.noBudget,
    this.isLoading = false,
    this.error,
  });

  double get remaining => (budgetLimit ?? 0) - totalSpent;
  double get spendPercentage => budgetLimit != null && budgetLimit! > 0 
      ? (totalSpent / budgetLimit!) * 100 
      : 0;
  double get timePercentage => (dayOfMonth / daysInMonth) * 100;
  double get projectedMonthEnd => dayOfMonth > 0 
      ? (totalSpent / dayOfMonth) * daysInMonth 
      : 0;
  double get safeDaily => remaining > 0 && (daysInMonth - dayOfMonth + 1) > 0
      ? remaining / (daysInMonth - dayOfMonth + 1)
      : 0;

  String get statusMessage {
    switch (status) {
      case BudgetStatus.safe:
        return 'You\'re on track! ✅';
      case BudgetStatus.caution:
        return 'Slow down a bit ⚠️';
      case BudgetStatus.danger:
        return 'Over budget pace! 🚨';
      case BudgetStatus.noBudget:
        return 'Set a budget to track';
    }
  }

  BudgetState copyWith({
    double? budgetLimit,
    double? totalSpent,
    int? daysInMonth,
    int? dayOfMonth,
    BudgetStatus? status,
    bool? isLoading,
    String? error,
    bool clearBudget = false,
  }) {
    return BudgetState(
      budgetLimit: clearBudget ? null : (budgetLimit ?? this.budgetLimit),
      totalSpent: totalSpent ?? this.totalSpent,
      daysInMonth: daysInMonth ?? this.daysInMonth,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for budget state management
class BudgetNotifier extends Notifier<BudgetState> {
  @override
  BudgetState build() {
    // Auto-load on initialization
    Future.microtask(() => refresh());
    return const BudgetState(isLoading: true);
  }

  /// Refresh budget data from DB and calculate status
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final budgetRepo = ref.read(budgetRepositoryProvider);
      final expenseRepo = ref.read(expenseRepositoryProvider);

      // Get current month's budget
      final budget = await budgetRepo.getCurrentMonthBudget();

      // Get current month's expenses
      final now = DateTime.now();
      final expenses = await expenseRepo.getExpensesForMonth(now.year, now.month);
      final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.expense.amount);

      // Calculate days
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final dayOfMonth = now.day;

      // Calculate status
      BudgetStatus status;
      if (budget == null) {
        status = BudgetStatus.noBudget;
      } else {
        final spendPct = (totalSpent / budget.amount) * 100;
        final timePct = (dayOfMonth / daysInMonth) * 100;

        if (spendPct <= timePct - 5) {
          status = BudgetStatus.safe;
        } else if (spendPct <= timePct + 10) {
          status = BudgetStatus.caution;
        } else {
          status = BudgetStatus.danger;
        }
      }

      state = BudgetState(
        budgetLimit: budget?.amount,
        totalSpent: totalSpent,
        daysInMonth: daysInMonth,
        dayOfMonth: dayOfMonth,
        status: status,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Set a new budget for current month
  Future<void> setBudget(double amount) async {
    try {
      final budgetRepo = ref.read(budgetRepositoryProvider);
      await budgetRepo.setBudget(amount);
      await refresh();
    } catch (e) {
      state = state.copyWith(error: 'Failed to set budget: $e');
    }
  }
}

/// Provider for budget state
final budgetProvider = NotifierProvider<BudgetNotifier, BudgetState>(
  BudgetNotifier.new,
);
