class FuzzySearchService {
  static double calculateSimilarity(String source, String target) {
    if (source.isEmpty || target.isEmpty) return 0.0;

    final sourceLower = source.toLowerCase();
    final targetLower = target.toLowerCase();

    // Exact match
    if (sourceLower == targetLower) return 1.0;

    // Contains match
    if (sourceLower.contains(targetLower)) return 0.8;
    if (targetLower.contains(sourceLower)) return 0.7;

    // Character-based similarity (simple implementation)
    int matches = 0;
    for (int i = 0; i < targetLower.length; i++) {
      if (sourceLower.contains(targetLower[i])) {
        matches++;
      }
    }

    return matches / targetLower.length;
  }

  static bool isFuzzyMatch(String source, String target, {double threshold = 0.6}) {
    return calculateSimilarity(source, target) >= threshold;
  }
}