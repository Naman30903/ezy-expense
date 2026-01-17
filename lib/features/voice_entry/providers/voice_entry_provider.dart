import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../services/voice_service.dart';
import '../services/voice_expense_parser.dart';
import '../../../data/local/database.dart';
import '../../sms_reader/providers/sms_ledger_provider.dart';

// Voice Service provider
final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

/// State for voice entry
class VoiceEntryState {
  final bool isListening;
  final bool isProcessing;
  final String currentTranscript;
  final ParsedVoiceExpense? parsedExpense;
  final String? error;
  final bool isSaved;

  const VoiceEntryState({
    this.isListening = false,
    this.isProcessing = false,
    this.currentTranscript = '',
    this.parsedExpense,
    this.error,
    this.isSaved = false,
  });

  VoiceEntryState copyWith({
    bool? isListening,
    bool? isProcessing,
    String? currentTranscript,
    ParsedVoiceExpense? parsedExpense,
    String? error,
    bool? isSaved,
    bool clearParsed = false,
    bool clearError = false,
  }) {
    return VoiceEntryState(
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      currentTranscript: currentTranscript ?? this.currentTranscript,
      parsedExpense: clearParsed ? null : (parsedExpense ?? this.parsedExpense),
      error: clearError ? null : (error ?? this.error),
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

/// Notifier for voice entry
class VoiceEntryNotifier extends Notifier<VoiceEntryState> {
  late VoiceService _voiceService;

  @override
  VoiceEntryState build() {
    _voiceService = ref.watch(voiceServiceProvider);
    return const VoiceEntryState();
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    state = state.copyWith(
      isListening: true,
      currentTranscript: '',
      clearParsed: true,
      clearError: true,
      isSaved: false,
    );

    try {
      await _voiceService.startListening(
        onResult: (text) {
          state = state.copyWith(currentTranscript: text);
        },
        onFinalResult: (text) {
          state = state.copyWith(
            isListening: false,
            currentTranscript: text,
            isProcessing: true,
          );
          _parseTranscript(text);
        },
      );
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        error: e.toString(),
      );
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _voiceService.stop();
    state = state.copyWith(isListening: false);
  }

  /// Parse the transcribed text
  void _parseTranscript(String text) {
    final parsed = VoiceExpenseParser.parse(text);
    
    if (parsed != null) {
      state = state.copyWith(
        parsedExpense: parsed,
        isProcessing: false,
      );
    } else {
      state = state.copyWith(
        isProcessing: false,
        error: 'Could not parse expense. Try saying something like "Spent 50 rupees on Uber"',
      );
    }
  }

  /// Manually trigger parsing (for editing)
  void reparseText(String text) {
    state = state.copyWith(currentTranscript: text);
    _parseTranscript(text);
  }

  /// Confirm and save the expense
  Future<void> confirmExpense() async {
    final parsed = state.parsedExpense;
    if (parsed == null) return;

    state = state.copyWith(isProcessing: true);

    try {
      final repository = ref.read(expenseRepositoryProvider);
      
      // Get or create merchant
      final merchantId = await repository.getOrCreateMerchant(parsed.merchant);
      
      // Get category ID
      final categoryId = await repository.getCategoryIdByName(parsed.category) ?? 
                         await repository.getCategoryIdByName('Other') ?? 1;
      
      // Insert expense
      final db = ref.read(databaseProvider);
      await db.into(db.expenses).insert(
        ExpensesCompanion(
          amount: Value(parsed.amount),
          merchantId: Value(merchantId),
          categoryId: Value(categoryId),
          date: Value(parsed.date),
          description: Value('Voice: ${parsed.originalText}'),
          isManual: const Value(true),
        ),
      );

      state = state.copyWith(
        isProcessing: false,
        isSaved: true,
        clearParsed: true,
        currentTranscript: '',
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Failed to save: $e',
      );
    }
  }

  /// Reset state for new entry
  void reset() {
    state = const VoiceEntryState();
  }
}

/// Provider for voice entry
final voiceEntryProvider =
    NotifierProvider<VoiceEntryNotifier, VoiceEntryState>(VoiceEntryNotifier.new);
