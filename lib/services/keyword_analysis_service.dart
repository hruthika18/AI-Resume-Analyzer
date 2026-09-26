class KeywordAnalysisService {
  static const Set<String> stopWords = {
    'a',
    'an',
    'the',
    'and',
    'or',
    'but',
    'is',
    'are',
    'was',
    'were',
    'be',
    'been',
    'being',
    'to',
    'of',
    'in',
    'on',
    'for',
    'with',
    'by',
    'from',
    'as',
    'at',
    'this',
    'that',
    'these',
    'those',
    'it',
    'its',
    'we',
    'you',
    'your',
    'our',
    'they',
    'their',
    'will',
    'can',
    'should',
    'have',
    'has',
    'had',
    'do',
    'does',
    'did',
    'become',
    'looking',
    'work',
    'working',
    'role',
    'candidate',
    'required',
    'requirements',
    'responsibilities',
    'experience',
    'ability',
    'skills',
    'skill',
    'knowledge',
    'strong',
    'good',
    'using',
    'used',
    'including',
    'such',
    'also',
    'within',
    'through',
    'about',
    'into',
    'over',
    'more',
    'than',
    'who',
    'which',
    'what',
    'where',
    'when',
  };

  static const Set<String> importantKeywords = {
    'java',
    'python',
    'c',
    'c++',
    'c#',
    'javascript',
    'typescript',
    'dart',
    'kotlin',
    'swift',

    'flutter',
    'react',
    'react.js',
    'angular',
    'vue.js',
    'node.js',
    'express.js',
    'next.js',

    'html',
    'css',
    'sql',
    'mysql',
    'postgresql',
    'mongodb',
    'sqlite',

    'git',
    'github',
    'docker',
    'kubernetes',
    'jenkins',
    'aws',
    'azure',
    'linux',

    'machine learning',
    'deep learning',
    'artificial intelligence',
    'natural language processing',
    'nlp',
    'computer vision',
    'generative ai',
    'data science',
    'data analysis',
    'statistics',
    'pandas',
    'numpy',
    'scikit-learn',
    'tensorflow',
    'pytorch',
    'opencv',
    'xgboost',

    'rest api',
    'graphql',
    'microservices',
    'spring boot',
    'django',
    'flask',
    'fastapi',

    'data structures',
    'algorithms',
    'object oriented programming',
    'oop',
    'software testing',
    'unit testing',
    'debugging',
    'system design',

    'firebase',
    'android',
    'ios',
    'mobile development',

    'power bi',
    'tableau',
    'excel',

    'figma',
    'ui design',
    'ux design',

    'agile',
    'scrum',
    'project management',
  };

  static double calculateKeywordMatch({
    required String resumeText,
    required String jobDescription,
  }) {
    final resumeWords = _extractKeywords(resumeText);
    final jobWords = _extractKeywords(jobDescription);

    if (jobWords.isEmpty) {
      return 0;
    }

    final matchedWords = jobWords.intersection(resumeWords);

    double totalWeight = 0;
    double matchedWeight = 0;

    for (final word in jobWords) {
      final weight = _keywordWeight(word);

      totalWeight += weight;

      if (matchedWords.contains(word)) {
        matchedWeight += weight;
      }
    }

    if (totalWeight == 0) {
      return 0;
    }

    final score = (matchedWeight / totalWeight) * 100;

    return score.clamp(0, 100).toDouble();
  }

  static double _keywordWeight(String word) {
    if (importantKeywords.contains(word)) {
      return 3.0;
    }

    return 1.0;
  }

  static Set<String> _extractKeywords(String text) {
    final cleanedText = text.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9+#./-]'),
      ' ',
    );

    final words = cleanedText
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toSet();

    final keywords = <String>{...words};

    final multiWordKeywords = [
      'machine learning',
      'deep learning',
      'artificial intelligence',
      'natural language processing',
      'computer vision',
      'generative ai',
      'data science',
      'data analysis',
      'spring boot',
      'rest api',
      'object oriented programming',
      'data structures',
      'software testing',
      'unit testing',
      'system design',
      'mobile development',
      'project management',
      'power bi',
      'ui design',
      'ux design',
    ];

    for (final keyword in multiWordKeywords) {
      if (cleanedText.contains(keyword)) {
        keywords.add(keyword);
      }
    }

    return keywords;
  }
}
