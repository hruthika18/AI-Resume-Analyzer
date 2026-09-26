import 'dart:math';

class SimilarityService {
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

  static const Set<String> importantTerms = {
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

  static double calculateSimilarity({
    required String resumeText,
    required String jobDescription,
  }) {
    final resumeWords = _wordFrequency(resumeText);
    final jobWords = _wordFrequency(jobDescription);

    if (resumeWords.isEmpty || jobWords.isEmpty) {
      return 0;
    }

    final allWords = <String>{...resumeWords.keys, ...jobWords.keys};

    double dotProduct = 0;
    double resumeMagnitude = 0;
    double jobMagnitude = 0;

    for (final word in allWords) {
      final weight = _weight(word);

      final resumeValue = (resumeWords[word] ?? 0) * weight;

      final jobValue = (jobWords[word] ?? 0) * weight;

      dotProduct += resumeValue * jobValue;
      resumeMagnitude += resumeValue * resumeValue;
      jobMagnitude += jobValue * jobValue;
    }

    if (resumeMagnitude == 0 || jobMagnitude == 0) {
      return 0;
    }

    final similarity =
        dotProduct / (sqrt(resumeMagnitude) * sqrt(jobMagnitude));

    return (similarity * 100).clamp(0, 100).toDouble();
  }

  static double _weight(String word) {
    if (importantTerms.contains(word)) {
      return 3.0;
    }

    return 1.0;
  }

  static Map<String, double> _wordFrequency(String text) {
    final cleanedText = text.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9+#./-]'),
      ' ',
    );

    final words = cleanedText
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .toList();

    final frequency = <String, double>{};

    for (final word in words) {
      frequency[word] = (frequency[word] ?? 0) + 1;
    }

    final multiWordTerms = [
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

    for (final term in multiWordTerms) {
      if (cleanedText.contains(term)) {
        frequency[term] = (frequency[term] ?? 0) + 1;
      }
    }

    return frequency;
  }
}
