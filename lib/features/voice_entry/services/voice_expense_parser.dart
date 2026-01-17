/// Offline NLP parser for extracting expense data from natural language voice input.
/// Uses regex-based pattern matching - no ML models required, works 100% offline.
class VoiceExpenseParser {
  /// Parse a natural language expense statement.
  /// Example: "Spent 50 rupees on Uber yesterday"
  /// Returns ParsedVoiceExpense or null if parsing fails.
  static ParsedVoiceExpense? parse(String input) {
    if (input.trim().isEmpty) return null;

    final lower = input.toLowerCase().trim();

    // 1. Extract Amount
    final amount = _extractAmount(lower);
    if (amount == null) return null;

    // 2. Extract Merchant/Description
    final merchant = _extractMerchant(lower);

    // 3. Guess Category
    final category = _guessCategory(merchant, lower);

    // 4. Extract Relative Date
    final date = _extractRelativeDate(lower);

    return ParsedVoiceExpense(
      amount: amount,
      merchant: merchant,
      category: category,
      date: date,
      originalText: input,
    );
  }

  static double? _extractAmount(String input) {
    // Patterns to match:
    // "50 rupees", "fifty rupees", "Rs 50", "₹50", "50 rs", "50 bucks"
    // Number words: one, two, ..., hundred, thousand
    
    // First try numeric extraction
    final numericPatterns = [
      // "50 rupees", "50 rs", "50 bucks"
      RegExp(r'(\d+(?:\.\d{1,2})?)\s*(?:rupees?|rs\.?|bucks?|₹)', caseSensitive: false),
      // "Rs 50", "₹ 50"
      RegExp(r'(?:rs\.?|₹)\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false),
      // "spent 50 on"
      RegExp(r'(?:spent|paid|gave)\s+(\d+(?:\.\d{1,2})?)', caseSensitive: false),
      // Just a number with context
      RegExp(r'(\d+(?:\.\d{1,2})?)\s+(?:on|for|at)', caseSensitive: false),
    ];

    for (var regex in numericPatterns) {
      final match = regex.firstMatch(input);
      if (match != null) {
        return double.tryParse(match.group(1)!);
      }
    }

    // Try word-based numbers
    final wordAmount = _parseWordNumber(input);
    if (wordAmount != null) return wordAmount;

    return null;
  }

  static double? _parseWordNumber(String input) {
    // Map of word numbers
    const wordToNum = {
      'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
      'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15,
      'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
      'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
      'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
      'hundred': 100, 'thousand': 1000,
    };

    // Simple pattern: "fifty rupees", "twenty five bucks"
    final wordPattern = RegExp(
      r'((?:' + wordToNum.keys.join('|') + r')(?:\s+(?:' + wordToNum.keys.join('|') + r'))*)\s*(?:rupees?|rs\.?|bucks?)',
      caseSensitive: false,
    );

    final match = wordPattern.firstMatch(input);
    if (match == null) return null;

    final words = match.group(1)!.toLowerCase().split(RegExp(r'\s+'));
    double total = 0;
    double current = 0;

    for (var word in words) {
      final value = wordToNum[word];
      if (value == null) continue;

      if (value == 100) {
        current = current == 0 ? 100 : current * 100;
      } else if (value == 1000) {
        current = current == 0 ? 1000 : current * 1000;
        total += current;
        current = 0;
      } else {
        current += value;
      }
    }
    total += current;

    return total > 0 ? total : null;
  }

  static String _extractMerchant(String input) {
    // Patterns: "on [merchant]", "at [merchant]", "to [merchant]", "for [merchant]"
    final patterns = [
      // "on Uber", "at Starbucks"
      RegExp(r'(?:on|at|to)\s+([A-Za-z][A-Za-z0-9\s]*?)(?:\s+(?:yesterday|today|last|this|for|$))', caseSensitive: false),
      // "for coffee"
      RegExp(r'for\s+([A-Za-z][A-Za-z0-9\s]*?)(?:\s+(?:yesterday|today|last|this|$))', caseSensitive: false),
    ];

    for (var regex in patterns) {
      final match = regex.firstMatch(input);
      if (match != null) {
        return _cleanMerchant(match.group(1)!);
      }
    }

    return 'Unknown';
  }

  static String _cleanMerchant(String raw) {
    // Remove trailing words like "yesterday", "today"
    var cleaned = raw.replaceAll(RegExp(r'\s*(yesterday|today|last|this)\s*$', caseSensitive: false), '');
    cleaned = cleaned.trim();
    
    // Capitalize each word
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static String _guessCategory(String merchant, String input) {
    final searchText = '${merchant.toLowerCase()} $input';

    const categoryKeywords = {
      'Food': ['food', 'eat', 'lunch', 'dinner', 'breakfast', 'coffee', 'tea', 'snack', 
               'restaurant', 'cafe', 'swiggy', 'zomato', 'pizza', 'burger', 'biryani'],
      'Transport': ['uber', 'ola', 'cab', 'taxi', 'auto', 'metro', 'bus', 'train', 
                    'fuel', 'petrol', 'diesel', 'parking', 'toll', 'rapido'],
      'Shopping': ['amazon', 'flipkart', 'myntra', 'shopping', 'clothes', 'shoes', 
                   'store', 'mall', 'market'],
      'Bills': ['electricity', 'water', 'gas', 'bill', 'recharge', 'mobile', 
                'internet', 'broadband', 'rent', 'emi'],
      'Entertainment': ['movie', 'netflix', 'spotify', 'game', 'subscription', 
                        'concert', 'show', 'pvr', 'inox'],
      'Health': ['medicine', 'pharmacy', 'doctor', 'hospital', 'medical', 
                 'gym', 'fitness', 'health'],
    };

    for (var entry in categoryKeywords.entries) {
      for (var keyword in entry.value) {
        if (searchText.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return 'Other';
  }

  static DateTime _extractRelativeDate(String input) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (input.contains('yesterday')) {
      return today.subtract(const Duration(days: 1));
    }
    if (input.contains('day before yesterday')) {
      return today.subtract(const Duration(days: 2));
    }
    if (input.contains('last week')) {
      return today.subtract(const Duration(days: 7));
    }
    if (input.contains('last month')) {
      return DateTime(now.year, now.month - 1, now.day);
    }

    // Default to today
    return today;
  }
}

/// Represents a parsed expense from voice input.
class ParsedVoiceExpense {
  final double amount;
  final String merchant;
  final String category;
  final DateTime date;
  final String originalText;

  ParsedVoiceExpense({
    required this.amount,
    required this.merchant,
    required this.category,
    required this.date,
    required this.originalText,
  });

  @override
  String toString() {
    return 'ParsedVoiceExpense(amount: $amount, merchant: $merchant, category: $category, date: $date)';
  }
}
