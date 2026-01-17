class VoiceParser {
  /// Parse spoken text into expense data
  static Map<String, dynamic>? parse(String text) {
    if (text.isEmpty) return null;
    final lower = text.toLowerCase();

    // 1. Extract Amount
    // Matches: 50, 50.5, 50 dollars, 50 bucks
    final amountRegex = RegExp(r'(\d+(?:\.\d{2})?)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(text);
    
    if (amountMatch == null) return null; // No amount found
    
    double amount = double.parse(amountMatch.group(1)!);

    // 2. Extract Category/Description
    // Remove amount and common filler words to find the "content"
    String remainingInfo = lower
        .replaceAll(amountMatch.group(0)!, '') // Remove amount
        .replaceAll(RegExp(r'\b(spent|pay|paid|for|on|bucks|dollars|rupees|inr|rs)\b'), '') // Remove fillers
        .trim();
    
    // Capitalize first letter
    if (remainingInfo.isNotEmpty) {
      remainingInfo = remainingInfo[0].toUpperCase() + remainingInfo.substring(1);
    } else {
      remainingInfo = "Voice Data";
    }

    return {
      'amount': amount,
      'description': remainingInfo,
      'categoryCandidate': remainingInfo, // Can be used to match against DB categories
    };
  }
}
