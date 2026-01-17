import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'sms_parser.dart';

class SmsReaderService {
  final SmsQuery _query = SmsQuery();
  
  // Track processed SMS IDs to avoid duplicates
  final Set<int> _processedSmsIds = {};

  /// Request permission and read SMS. Returns list of parsed transactions.
  /// Only returns NEW transactions that haven't been processed before.
  Future<List<ParsedTransaction>> readBankSms({
    int count = 100,
    Set<int>? alreadyProcessedIds,
  }) async {
    // Merge any externally tracked IDs
    if (alreadyProcessedIds != null) {
      _processedSmsIds.addAll(alreadyProcessedIds);
    }

    // 1. Check/Request Permission
    if (await Permission.sms.request().isGranted) {
      // 2. Fetch SMS (Inbox only)
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: count,
      );

      final List<ParsedTransaction> expenses = [];

      for (final msg in messages) {
        // Skip if already processed
        if (msg.id != null && _processedSmsIds.contains(msg.id)) {
          continue;
        }

        final body = msg.body;
        if (body == null) continue;

        // 3. Parse with the enhanced parser
        final parsed = SmsParser.parse(
          body,
          smsDate: msg.date,
        );

        if (parsed != null) {
          expenses.add(parsed);
          
          // Mark as processed
          if (msg.id != null) {
            _processedSmsIds.add(msg.id!);
          }
        }
      }
      
      return expenses;
    } else {
      throw Exception('SMS Permission Denied');
    }
  }

  /// Get all processed SMS IDs (for persistence)
  Set<int> get processedSmsIds => Set.from(_processedSmsIds);

  /// Clear processed IDs (for testing or reset)
  void clearProcessedIds() {
    _processedSmsIds.clear();
  }
}

