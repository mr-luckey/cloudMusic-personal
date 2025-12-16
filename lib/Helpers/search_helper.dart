// Coded by Naseer Ahmed

import 'dart:math';

/// Helper class for search-related operations including fuzzy matching,
/// result ranking, and query normalization
class SearchHelper {
  /// Calculate Levenshtein distance between two strings
  /// Returns the minimum number of edits needed to transform s1 into s2
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final len1 = s1.length;
    final len2 = s2.length;
    final List<List<int>> d = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    for (int i = 0; i <= len1; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      d[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        d[i][j] = min(
          min(d[i - 1][j] + 1, d[i][j - 1] + 1),
          d[i - 1][j - 1] + cost,
        );
      }
    }

    return d[len1][len2];
  }

  /// Calculate similarity score between two strings (0.0 to 1.0)
  /// 1.0 means identical, 0.0 means completely different
  static double similarityScore(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = levenshteinDistance(s1.toLowerCase(), s2.toLowerCase());
    final maxLen = max(s1.length, s2.length);
    return 1.0 - (distance / maxLen);
  }

  /// Normalize a search query by removing special characters,
  /// converting to lowercase, and trimming whitespace
  static String normalizeQuery(String query) {
    return query
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Calculate a comprehensive relevance score for a search result
  /// Returns a score from 0 to 100
  static double calculateRelevanceScore({
    required String query,
    required String title,
    String? subtitle,
    int? viewCount,
    DateTime? publishDate,
  }) {
    final normalizedQuery = normalizeQuery(query);
    final normalizedTitle = normalizeQuery(title);
    final normalizedSubtitle = subtitle != null ? normalizeQuery(subtitle) : '';

    double score = 0.0;

    // Exact match (100 points)
    if (normalizedTitle == normalizedQuery) {
      score += 100.0;
      return score; // Perfect match, return immediately
    }

    // Starts with query (80 points)
    if (normalizedTitle.startsWith(normalizedQuery)) {
      score += 80.0;
    }
    // Contains query (60 points)
    else if (normalizedTitle.contains(normalizedQuery)) {
      score += 60.0;
    }
    // Fuzzy match based on similarity (0-50 points)
    else {
      final similarity = similarityScore(normalizedQuery, normalizedTitle);
      score += similarity * 50.0;
    }

    // Bonus: Query words in title (up to 20 points)
    final queryWords = normalizedQuery.split(' ');
    final titleWords = normalizedTitle.split(' ');
    int matchingWords = 0;
    for (final queryWord in queryWords) {
      if (queryWord.isEmpty) continue;
      for (final titleWord in titleWords) {
        if (titleWord.contains(queryWord) || queryWord.contains(titleWord)) {
          matchingWords++;
          break;
        }
      }
    }
    if (queryWords.isNotEmpty) {
      score += (matchingWords / queryWords.length) * 20.0;
    }

    // Bonus: Query in subtitle (up to 15 points)
    if (subtitle != null && normalizedSubtitle.contains(normalizedQuery)) {
      score += 15.0;
    }

    // Bonus: Popularity score based on view count (up to 10 points)
    if (viewCount != null && viewCount > 0) {
      // Logarithmic scale for view count
      final popularityScore =
          min(10.0, (log(viewCount + 1) / log(1000000)) * 10);
      score += popularityScore;
    }

    // Bonus: Recency score (up to 5 points)
    if (publishDate != null) {
      final daysSincePublish = DateTime.now().difference(publishDate).inDays;
      if (daysSincePublish < 7) {
        score += 5.0; // Very recent
      } else if (daysSincePublish < 30) {
        score += 3.0; // Recent
      } else if (daysSincePublish < 90) {
        score += 1.0; // Somewhat recent
      }
    }

    return min(100.0, score);
  }

  /// Check if a result matches the query with fuzzy matching
  /// OPTIMIZED: Removed expensive similarity calculations
  static bool fuzzyMatch(
    String query,
    String text, {
    double threshold = 0.6,
  }) {
    final normalizedQuery = normalizeQuery(query);
    final normalizedText = normalizeQuery(text);

    // Exact match or contains
    if (normalizedText.contains(normalizedQuery)) {
      return true;
    }

    // Check if most query words are present (simple and fast)
    final queryWords = normalizedQuery.split(' ');
    final textWords = normalizedText.split(' ');
    int matchingWords = 0;

    for (final queryWord in queryWords) {
      if (queryWord.isEmpty) continue;
      for (final textWord in textWords) {
        if (textWord.contains(queryWord) || queryWord.contains(textWord)) {
          matchingWords++;
          break;
        }
      }
    }

    return queryWords.isNotEmpty &&
        (matchingWords / queryWords.length) >= threshold;
  }

  /// Sort search results by relevance score
  /// OPTIMIZED: Removed expensive Levenshtein calculations to prevent frame drops
  static List<Map> sortByRelevance(
    List<Map> results,
    String query, {
    String titleKey = 'title',
    String subtitleKey = 'subtitle',
  }) {
    final normalizedQuery = normalizeQuery(query);

    final scoredResults = results.map((result) {
      final title = result[titleKey]?.toString() ?? '';
      final normalizedTitle = normalizeQuery(title);

      double score = 0.0;

      // Exact match (100 points)
      if (normalizedTitle == normalizedQuery) {
        score = 100.0;
      }
      // Starts with query (80 points)
      else if (normalizedTitle.startsWith(normalizedQuery)) {
        score = 80.0;
      }
      // Contains query (60 points)
      else if (normalizedTitle.contains(normalizedQuery)) {
        score = 60.0;
      }
      // Simple word matching (0-40 points) - MUCH faster than Levenshtein
      else {
        final queryWords = normalizedQuery.split(' ');
        final titleWords = normalizedTitle.split(' ');
        int matchingWords = 0;

        for (final queryWord in queryWords) {
          if (queryWord.isEmpty) continue;
          for (final titleWord in titleWords) {
            if (titleWord.contains(queryWord) ||
                queryWord.contains(titleWord)) {
              matchingWords++;
              break;
            }
          }
        }

        if (queryWords.isNotEmpty) {
          score = (matchingWords / queryWords.length) * 40.0;
        }
      }

      return {
        ...result,
        '_relevanceScore': score,
      };
    }).toList();

    // Sort by relevance score (highest first)
    scoredResults.sort((a, b) {
      final scoreA = a['_relevanceScore'] as double? ?? 0.0;
      final scoreB = b['_relevanceScore'] as double? ?? 0.0;
      return scoreB.compareTo(scoreA);
    });

    // Remove the temporary score field
    return scoredResults.map((result) {
      result.remove('_relevanceScore');
      return result;
    }).toList();
  }

  /// Filter results by type
  static List<Map> filterByType(
    List<Map> results,
    String? filterType, {
    String typeKey = 'type',
  }) {
    if (filterType == null || filterType.isEmpty || filterType == 'all') {
      return results;
    }

    return results.where((result) {
      final type = result[typeKey]?.toString().toLowerCase() ?? '';
      return type == filterType.toLowerCase();
    }).toList();
  }

  /// Generate search suggestions based on query
  static List<String> generateSuggestions(
    String query,
    List<String> history,
    List<String> trending,
  ) {
    final suggestions = <String>[];
    final normalizedQuery = normalizeQuery(query);

    if (normalizedQuery.isEmpty) {
      return trending.take(5).toList();
    }

    // Add matching history items
    for (final item in history) {
      if (normalizeQuery(item).contains(normalizedQuery)) {
        suggestions.add(item);
      }
    }

    // Add matching trending items
    for (final item in trending) {
      if (!suggestions.contains(item) &&
          normalizeQuery(item).contains(normalizedQuery)) {
        suggestions.add(item);
      }
    }

    // Limit to 10 suggestions
    return suggestions.take(10).toList();
  }

  /// Extract keywords from a query for better matching
  static List<String> extractKeywords(String query) {
    final normalized = normalizeQuery(query);
    final words = normalized.split(' ');

    // Remove common stop words
    final stopWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
    };

    return words
        .where((word) => word.isNotEmpty && !stopWords.contains(word))
        .toList();
  }

  /// Check if a query contains any of the keywords
  static bool containsKeywords(String text, List<String> keywords) {
    final normalizedText = normalizeQuery(text);
    return keywords.any((keyword) => normalizedText.contains(keyword));
  }
}
