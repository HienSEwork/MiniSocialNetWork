import 'dart:math' as math;

/// Lightweight on-device TF-IDF moderation used before user content is stored.
class LocalContentFilter {
  const LocalContentFilter();

  static const _blockedSamples = [
    'đồ ngu cút khỏi đây',
    'đồ khốn tao ghét mày',
    'đe dọa giết người',
    'lừa đảo chuyển tiền ngay',
    'spam quảng cáo kiếm tiền nhanh',
  ];

  bool isAllowed(String content) {
    final text = content.trim().toLowerCase();
    if (text.isEmpty) return true;
    final documents = [text, ..._blockedSamples];
    final tokens = documents.map(_tokenize).toList();
    final vocabulary = tokens.expand((items) => items).toSet();
    final vectors = tokens.map((items) {
      final counts = <String, int>{};
      for (final token in items) {
        counts[token] = (counts[token] ?? 0) + 1;
      }
      return {
        for (final term in vocabulary)
          term:
              (counts[term] ?? 0) /
              math.max(1, items.length) *
              (math.log(
                    documents.length /
                        (1 + tokens.where((doc) => doc.contains(term)).length),
                  ) +
                  1),
      };
    }).toList();
    for (var index = 1; index < vectors.length; index++) {
      if (_cosine(vectors.first, vectors[index]) >= .52) return false;
    }
    return true;
  }

  List<String> _tokenize(String value) => value
      .replaceAll(RegExp(r'[^a-z0-9à-ỹ\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((token) => token.length > 1)
      .toList();

  double _cosine(Map<String, double> a, Map<String, double> b) {
    var dot = 0.0;
    var magnitudeA = 0.0;
    var magnitudeB = 0.0;
    for (final term in a.keys) {
      dot += (a[term] ?? 0) * (b[term] ?? 0);
      magnitudeA += math.pow(a[term] ?? 0, 2);
      magnitudeB += math.pow(b[term] ?? 0, 2);
    }
    if (magnitudeA == 0 || magnitudeB == 0) return 0;
    return dot / (math.sqrt(magnitudeA) * math.sqrt(magnitudeB));
  }
}
