import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database.dart';
import '../data/repositories/expense_repository.dart';

// Database Provider (Singleton)
final dbProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Repository Provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(dbProvider);
  return ExpenseRepository(db);
});
