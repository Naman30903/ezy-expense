import 'package:drift/drift.dart';
import '../../data/local/database.dart';
import '../../features/sms_reader/services/sms_parser.dart';

/// Repository for expense-related database operations.
class ExpenseRepository {
  final AppDatabase _db;

  ExpenseRepository(this._db);

  /// Get or create a merchant by name. Returns the merchant ID.
  Future<int> getOrCreateMerchant(String name) async {
    // Try to find existing merchant
    final existing = await (_db.select(_db.merchants)
          ..where((m) => m.name.equals(name)))
        .getSingleOrNull();

    if (existing != null) {
      return existing.id;
    }

    // Create new merchant
    return await _db.into(_db.merchants).insert(
          MerchantsCompanion(name: Value(name)),
        );
  }

  /// Get category ID by name.
  Future<int?> getCategoryIdByName(String name) async {
    final category = await (_db.select(_db.categories)
          ..where((c) => c.name.equals(name)))
        .getSingleOrNull();
    return category?.id;
  }

  /// Insert an expense from a parsed SMS transaction.
  Future<int> insertExpenseFromParsedTransaction(ParsedTransaction txn) async {
    // 1. Get or create merchant
    final merchantId = await getOrCreateMerchant(txn.merchant);

    // 2. Get category ID (fallback to "Other" if not found)
    int categoryId = await getCategoryIdByName(txn.suggestedCategory) ??
        await getCategoryIdByName('Other') ??
        1;

    // 3. Insert expense
    return await _db.into(_db.expenses).insert(
          ExpensesCompanion(
            amount: Value(txn.amount),
            merchantId: Value(merchantId),
            categoryId: Value(categoryId),
            date: Value(txn.transactionDate ?? DateTime.now()),
            description: Value(txn.upiRef != null ? 'UPI Ref: ${txn.upiRef}' : null),
            isManual: const Value(false),
            sourceSmsId: Value(txn.originalBody.hashCode.toString()),
          ),
        );
  }

  /// Get all expenses with merchant and category info, sorted by date descending.
  Future<List<ExpenseWithDetails>> getAllExpenses() async {
    final query = _db.select(_db.expenses).join([
      leftOuterJoin(_db.merchants, _db.merchants.id.equalsExp(_db.expenses.merchantId)),
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.expenses.categoryId)),
    ])
      ..orderBy([OrderingTerm.desc(_db.expenses.date)]);

    final results = await query.get();

    return results.map((row) {
      final expense = row.readTable(_db.expenses);
      final merchant = row.readTableOrNull(_db.merchants);
      final category = row.readTableOrNull(_db.categories);

      return ExpenseWithDetails(
        expense: expense,
        merchantName: merchant?.name ?? 'Unknown',
        categoryName: category?.name ?? 'Other',
      );
    }).toList();
  }

  /// Get expenses for a specific month.
  Future<List<ExpenseWithDetails>> getExpensesForMonth(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final query = _db.select(_db.expenses).join([
      leftOuterJoin(_db.merchants, _db.merchants.id.equalsExp(_db.expenses.merchantId)),
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.expenses.categoryId)),
    ])
      ..where(_db.expenses.date.isBetweenValues(startOfMonth, endOfMonth))
      ..orderBy([OrderingTerm.desc(_db.expenses.date)]);

    final results = await query.get();

    return results.map((row) {
      final expense = row.readTable(_db.expenses);
      final merchant = row.readTableOrNull(_db.merchants);
      final category = row.readTableOrNull(_db.categories);

      return ExpenseWithDetails(
        expense: expense,
        merchantName: merchant?.name ?? 'Unknown',
        categoryName: category?.name ?? 'Other',
      );
    }).toList();
  }

  /// Delete an expense by ID.
  Future<int> deleteExpense(int id) async {
    return await (_db.delete(_db.expenses)..where((e) => e.id.equals(id))).go();
  }
}

/// A helper class to hold expense data with joined merchant and category names.
class ExpenseWithDetails {
  final Expense expense;
  final String merchantName;
  final String categoryName;

  ExpenseWithDetails({
    required this.expense,
    required this.merchantName,
    required this.categoryName,
  });
}
