import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sms_reader_service.dart';
import '../services/sms_parser.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/local/database.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Repository provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseRepository(db);
});

// SMS Reader Service provider
final smsReaderServiceProvider = Provider<SmsReaderService>((ref) {
  return SmsReaderService();
});

/// State for the SMS Ledger screen
class SmsLedgerState {
  final List<ParsedTransaction> pendingTransactions;
  final bool isLoading;
  final String? error;

  const SmsLedgerState({
    this.pendingTransactions = const [],
    this.isLoading = false,
    this.error,
  });

  SmsLedgerState copyWith({
    List<ParsedTransaction>? pendingTransactions,
    bool? isLoading,
    String? error,
  }) {
    return SmsLedgerState(
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for SMS Ledger state management using modern Riverpod Notifier
class SmsLedgerNotifier extends Notifier<SmsLedgerState> {
  late SmsReaderService _smsReaderService;
  late ExpenseRepository _expenseRepository;

  @override
  SmsLedgerState build() {
    _smsReaderService = ref.watch(smsReaderServiceProvider);
    _expenseRepository = ref.watch(expenseRepositoryProvider);
    return const SmsLedgerState();
  }

  /// Fetch and parse new SMS messages
  Future<void> fetchNewSms() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final transactions = await _smsReaderService.readBankSms();
      state = state.copyWith(
        pendingTransactions: transactions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Confirm a transaction and save it to the database
  Future<void> confirmTransaction(int index) async {
    if (index < 0 || index >= state.pendingTransactions.length) return;

    final txn = state.pendingTransactions[index];
    
    try {
      await _expenseRepository.insertExpenseFromParsedTransaction(txn);
      
      // Remove from pending list
      final updatedList = List<ParsedTransaction>.from(state.pendingTransactions)
        ..removeAt(index);
      state = state.copyWith(pendingTransactions: updatedList);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save: $e');
    }
  }

  /// Reject (dismiss) a transaction
  void rejectTransaction(int index) {
    if (index < 0 || index >= state.pendingTransactions.length) return;

    final updatedList = List<ParsedTransaction>.from(state.pendingTransactions)
      ..removeAt(index);
    state = state.copyWith(pendingTransactions: updatedList);
  }

  /// Confirm all pending transactions
  Future<void> confirmAll() async {
    state = state.copyWith(isLoading: true);

    try {
      for (final txn in state.pendingTransactions) {
        await _expenseRepository.insertExpenseFromParsedTransaction(txn);
      }
      state = state.copyWith(pendingTransactions: [], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to save: $e');
    }
  }
}

/// Provider for the SMS Ledger notifier
final smsLedgerProvider =
    NotifierProvider<SmsLedgerNotifier, SmsLedgerState>(SmsLedgerNotifier.new);
