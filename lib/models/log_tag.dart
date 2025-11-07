class Tag {
  final String name;
  final Map<String, bool> _patternMatchCache = {};

  Tag(this.name);

  bool matchesPattern(String pattern) {
    return _patternMatchCache.putIfAbsent(pattern, () => wildcardMatch(pattern));
  }

  bool match(String pattern) {
    if (pattern == '*') return true;

    if (pattern.contains('*')) return wildcardMatch(pattern);

    return name == pattern;
  }

  bool wildcardMatch(String pattern) {
    int p = 0, t = 0;
    int starIdx = -1, match = 0;

    while (t < name.length) {
      if (p < pattern.length && (pattern[p] == name[t] || pattern[p] == '*')) {
        if (pattern[p] == '*') {
          starIdx = p;
          match = t;
          p++;
        } else {
          p++;
          t++;
        }
      } else if (starIdx != -1) {
        p = starIdx + 1;
        match++;
        t = match;
      } else {
        return false;
      }
    }

    while (p < pattern.length && pattern[p] == '*') {
      p++;
    }

    return p == pattern.length;
  }
}
