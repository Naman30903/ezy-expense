/// Represents a parsed transaction from an SMS.
class ParsedTransaction {
  final double amount;
  final String merchant;
  final String originalBody;
  final DateTime? transactionDate;
  final String transactionType; // debit, credit, repayment
  final String? upiRef;
  final String suggestedCategory;

  ParsedTransaction({
    required this.amount,
    required this.merchant,
    required this.originalBody,
    this.transactionDate,
    required this.transactionType,
    this.upiRef,
    required this.suggestedCategory,
  });

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'merchant': merchant,
        'originalBody': originalBody,
        'transactionDate': transactionDate,
        'transactionType': transactionType,
        'upiRef': upiRef,
        'suggestedCategory': suggestedCategory,
      };
}

class SmsParser {
  // Keywords that indicate a debit transaction
  static const _debitKeywords = [
    'debited',
    'spent',
    'paid',
    'sent',
    'transaction',
    'withdrawn',
    'purchase',
  ];

  // Keywords that indicate a credit transaction
  static const _creditKeywords = [
    'credited',
    'received',
    'refund',
    'cashback',
    'repayment',
  ];

  // Category mapping based on merchant keywords
  static const _categoryKeywords = {
    'Food': ['swiggy', 'zomato', 'restaurant', 'cafe', 'food', 'pizza', 'burger', 'dominos', 'mcdonalds', 'kfc'],
    'Transport': ['uber', 'ola', 'rapido', 'metro', 'irctc', 'railway', 'petrol', 'fuel', 'parking'],
    'Shopping': ['amazon', 'flipkart', 'myntra', 'ajio', 'mall', 'store', 'mart', 'retail'],
    'Bills': ['electricity', 'water', 'gas', 'broadband', 'mobile', 'recharge', 'bill', 'dth', 'airtel', 'jio', 'vi'],
    'Entertainment': ['netflix', 'spotify', 'hotstar', 'prime', 'movie', 'cinema', 'pvr', 'inox', 'game'],
    'Health': ['pharmacy', 'medical', 'hospital', 'doctor', 'clinic', 'apollo', 'medplus', '1mg', 'pharmeasy'],
  };

  /// Main parse method - returns ParsedTransaction or null if not a valid transaction SMS.
  static ParsedTransaction? parse(String body, {DateTime? smsDate}) {
    final lower = body.toLowerCase();

    // 1. Determine transaction type
    String transactionType = _getTransactionType(lower);
    if (transactionType == 'unknown') return null;

    // 2. Extract Amount
    double? amount = _extractAmount(body);
    if (amount == null) return null;

    // 3. Extract Merchant
    String merchant = _extractMerchant(body);

    // 4. Extract Transaction Date (if present in SMS, otherwise use smsDate)
    DateTime? transactionDate = _extractDate(body) ?? smsDate;

    // 5. Extract UPI Reference (if present)
    String? upiRef = _extractUpiRef(body);

    // 6. Guess Category
    String category = _guessCategory(merchant, lower);

    return ParsedTransaction(
      amount: amount,
      merchant: merchant,
      originalBody: body,
      transactionDate: transactionDate,
      transactionType: transactionType,
      upiRef: upiRef,
      suggestedCategory: category,
    );
  }

  static String _getTransactionType(String lower) {
    // Check for credit first (repayments, refunds)
    for (var keyword in _creditKeywords) {
      if (lower.contains(keyword)) return 'credit';
    }
    // Then check for debit
    for (var keyword in _debitKeywords) {
      if (lower.contains(keyword)) return 'debit';
    }
    return 'unknown';
  }

  static double? _extractAmount(String body) {
    // Patterns to match:
    // Rs. 40, Rs.40, Rs 40, INR 40, ₹40, ₹ 40
    // Rs. 2,498.45, Rs.2,409.75
    final patterns = [
      RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*(?:Rs\.?|INR|₹)', caseSensitive: false),
    ];

    for (var regex in patterns) {
      final match = regex.firstMatch(body);
      if (match != null) {
        String rawAmount = match.group(1)!.replaceAll(',', '');
        return double.tryParse(rawAmount);
      }
    }
    return null;
  }

  static String _extractMerchant(String body) {
    // Pattern 1: "on [Merchant] is successful" (Slice card format)
    // Example: "transaction of Rs. 40 on Pintoo is successful"
    final slicePattern = RegExp(
      r'(?:of\s+Rs\.?\s*[\d,\.]+\s+)?on\s+([A-Za-z][A-Za-z0-9\s\.]+?)(?:\s+is\s+successful|\s*\(|\s*$)',
      caseSensitive: false,
    );
    var match = slicePattern.firstMatch(body);
    if (match != null) {
      String merchant = match.group(1)!.trim();
      // Exclude date patterns like "06-Jan-26"
      if (!RegExp(r'^\d{2}-[A-Za-z]{3}-\d{2}$').hasMatch(merchant)) {
        return _cleanMerchantName(merchant);
      }
    }

    // Pattern 2: "to [Merchant]" (UPI format)
    // Example: "sent from a/c xx1870 on 06-Jan-26 to HEMANT SINGH"
    final upiPattern = RegExp(
      r'to\s+([A-Za-z][A-Za-z0-9\s\.]+?)(?:\s*\(|\s*\.|$)',
      caseSensitive: false,
    );
    match = upiPattern.firstMatch(body);
    if (match != null) {
      return _cleanMerchantName(match.group(1)!.trim());
    }

    // Pattern 3: "at [Merchant]" (Standard bank format)
    final atPattern = RegExp(
      r'at\s+([A-Za-z0-9\s\.]+?)(?:\s+on|\s*\.|$)',
      caseSensitive: false,
    );
    match = atPattern.firstMatch(body);
    if (match != null) {
      return _cleanMerchantName(match.group(1)!.trim());
    }

    return 'Unknown';
  }

  static String _cleanMerchantName(String name) {
    // Remove trailing "if not you" type phrases
    name = name.replaceAll(RegExp(r'\s*if\s+not.*$', caseSensitive: false), '');
    // Remove extra spaces
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Capitalize first letter of each word
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static DateTime? _extractDate(String body) {
    // Pattern 1: "on DD-Mon-YY" (e.g., "on 06-Jan-26")
    final datePattern1 = RegExp(
      r'on\s+(\d{1,2})-([A-Za-z]{3})-(\d{2})',
      caseSensitive: false,
    );
    var match = datePattern1.firstMatch(body);
    if (match != null) {
      return _parseDate(match.group(1)!, match.group(2)!, match.group(3)!);
    }

    // Pattern 2: "DD/MM/YY" or "DD-MM-YY" or "DD-MM-YYYY"
    final datePattern2 = RegExp(
      r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})',
    );
    match = datePattern2.firstMatch(body);
    if (match != null) {
      int day = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int year = int.parse(match.group(3)!);
      if (year < 100) year += 2000;
      try {
        return DateTime(year, month, day);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  static DateTime? _parseDate(String day, String monthStr, String year) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    
    int? month = months[monthStr.toLowerCase()];
    if (month == null) return null;

    int d = int.parse(day);
    int y = int.parse(year);
    if (y < 100) y += 2000;

    try {
      return DateTime(y, month, d);
    } catch (_) {
      return null;
    }
  }

  static String? _extractUpiRef(String body) {
    // Pattern: "UPI Ref: 600567899756" or "UPI ref no. 12345"
    final upiPattern = RegExp(
      r'UPI\s*(?:Ref|ref\.?\s*no\.?)[:\s]*(\d+)',
      caseSensitive: false,
    );
    final match = upiPattern.firstMatch(body);
    return match?.group(1);
  }

  static String _guessCategory(String merchant, String lowerBody) {
    final searchText = '${merchant.toLowerCase()} $lowerBody';
    
    for (var entry in _categoryKeywords.entries) {
      for (var keyword in entry.value) {
        if (searchText.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'Other';
  }
}

