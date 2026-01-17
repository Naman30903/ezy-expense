import 'package:drift/drift.dart';
import '../local/database.dart';

/// Repository for budget-related database operations.
class BudgetRepository {
  final AppDatabase _db;

  BudgetRepository(this._db);

  /// Set or update budget for a specific month/year.
  Future<int> setBudget(double amount, {int? month, int? year}) async {
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    // Upsert: Update if exists, insert if not
    return await _db.into(_db.budgets).insertOnConflictUpdate(
      BudgetsCompanion(
        amount: Value(amount),
        month: Value(targetMonth),
        year: Value(targetYear),
      ),
    );
  }

  /// Get budget for a specific month/year.
  Future<Budget?> getBudgetForMonth({int? month, int? year}) async {
    final now = DateTime.now();
    final targetMonth = month ?? now.month;
    final targetYear = year ?? now.year;

    return await (_db.select(_db.budgets)
          ..where((b) => b.month.equals(targetMonth) & b.year.equals(targetYear)))
        .getSingleOrNull();
  }

  /// Get current month's budget.
  Future<Budget?> getCurrentMonthBudget() {
    return getBudgetForMonth();
  }

  /// Delete budget for a specific month.
  Future<int> deleteBudget(int month, int year) {
    return (_db.delete(_db.budgets)
          ..where((b) => b.month.equals(month) & b.year.equals(year)))
        .go();
  }
}
