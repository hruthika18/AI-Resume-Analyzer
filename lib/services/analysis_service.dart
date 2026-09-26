import '../models/analysis_result.dart';
import 'skill_matching_service.dart';
import 'keyword_analysis_service.dart';
import 'similarity_service.dart';

class AnalysisService {
  static AnalysisResult analyze({
    required String resumeText,
    required Map<String, String> resumeSections,
    required Map<String, List<String>> resumeSkills,
    required String jobTitle,
    required String jobDescription,
    required Map<String, List<String>> jobSkills,
  }) {
    // 1. Skill matching
    final skillMatch = SkillMatchingService.matchSkills(
      resumeSkills: resumeSkills,
      jobSkills: jobSkills,
    );

    final matchedSkills = skillMatch['matched'] ?? [];
    final missingSkills = skillMatch['missing'] ?? [];
    final partialSkills = skillMatch['partial'] ?? [];

    // 2. Skill score
    final totalJobSkills =
        matchedSkills.length + missingSkills.length + partialSkills.length;

    double skillScore = 0;

    if (totalJobSkills > 0) {
      skillScore =
          ((matchedSkills.length + (partialSkills.length * 0.5)) /
              totalJobSkills) *
          100;
    }

    // 3. Keyword score
    final keywordScore = KeywordAnalysisService.calculateKeywordMatch(
      resumeText: resumeText,
      jobDescription: '$jobTitle $jobDescription',
    );

    // 4. Text similarity
    final similarityScore = SimilarityService.calculateSimilarity(
      resumeText: resumeText,
      jobDescription: '$jobTitle $jobDescription',
    );

    // 5. Experience relevance
    final experienceScore = _calculateExperienceScore(
      resumeSections,
      resumeText,
      jobTitle,
      jobDescription,
    );

    // 6. Completeness
    final completenessScore = _calculateCompletenessScore(resumeSections);

    // 7. Structure
    final structureScore = _calculateStructureScore(resumeSections);

    // 8. Overall weighted score
    // Weights: Skill Match 25, Keyword Match 20, Content Similarity 20,
    // Projects & Experience 15, Completeness 10, Structure 10 (total 100).
    final overallScore =
        (skillScore * 0.25) +
        (keywordScore * 0.20) +
        (similarityScore * 0.20) +
        (experienceScore * 0.15) +
        (completenessScore * 0.10) +
        (structureScore * 0.10);

    // 9. Strengths
    final strengths = <String>[];

    if (skillScore >= 70) {
      strengths.add('Your skills match the target job well.');
    }

    if (keywordScore >= 70) {
      strengths.add('Your resume contains many relevant job keywords.');
    }

    if (similarityScore >= 60) {
      strengths.add('Your resume content is relevant to the target role.');
    }

    if (experienceScore >= 60) {
      strengths.add(
        'Your projects or experience show relevance to the target role.',
      );
    }

    if (resumeSections.containsKey('Projects')) {
      strengths.add('Projects are included in your resume.');
    }

    if (resumeSections.containsKey('Experience') ||
        resumeSections.containsKey('Internships')) {
      strengths.add('Relevant experience or internships are included.');
    }

    // 10. Improvements
    final improvements = <String>[];

    if (missingSkills.isNotEmpty) {
      improvements.add(
        'Consider adding relevant missing skills if you genuinely have experience with them.',
      );
    }

    if (keywordScore < 60) {
      improvements.add(
        'Add relevant keywords from the target job description where they accurately describe your experience.',
      );
    }

    if (similarityScore < 60) {
      improvements.add(
        'Tailor your resume content more closely to the target role.',
      );
    }

    if (experienceScore < 60) {
      improvements.add(
        'Highlight projects, internships, or experience that relate to the target role.',
      );
    }

    if (!resumeSections.containsKey('Projects')) {
      improvements.add(
        'Consider adding relevant academic or personal projects.',
      );
    }

    if (!resumeSections.containsKey('Experience') &&
        !resumeSections.containsKey('Internships')) {
      improvements.add(
        'Consider adding relevant experience, internships, or practical work.',
      );
    }

    if (!resumeSections.containsKey('Certifications')) {
      improvements.add(
        'Add relevant certifications if you have completed any.',
      );
    }

    // 11. Suggestions
    final suggestions = <String>[
      ...missingSkills.map(
        (skill) =>
            'Consider mentioning $skill if you have genuine experience with it.',
      ),
    ];

    if (suggestions.isEmpty) {
      suggestions.add('Continue tailoring your resume to each target job.');
    }

    final missingKeywords = _findMissingKeywords(
      resumeText,
      jobTitle,
      jobDescription,
    );

    return AnalysisResult(
      overallScore: overallScore.clamp(0, 100).toDouble(),
      skillScore: skillScore.clamp(0, 100).toDouble(),
      keywordScore: keywordScore.clamp(0, 100).toDouble(),
      similarityScore: similarityScore.clamp(0, 100).toDouble(),
      experienceScore: experienceScore.clamp(0, 100).toDouble(),
      completenessScore: completenessScore.clamp(0, 100).toDouble(),
      structureScore: structureScore.clamp(0, 100).toDouble(),
      matchedSkills: matchedSkills,
      missingSkills: missingSkills,
      partialSkills: partialSkills,
      missingKeywords: missingKeywords,
      strengths: strengths,
      improvements: improvements,
      suggestions: suggestions,
    );
  }

  static double _calculateExperienceScore(
    Map<String, String> sections,
    String resumeText,
    String jobTitle,
    String jobDescription,
  ) {
    double score = 0;

    if (sections.containsKey('Experience')) {
      score += 40;
    }

    if (sections.containsKey('Internships')) {
      score += 25;
    }

    if (sections.containsKey('Projects')) {
      score += 25;
    }

    if (sections.containsKey('Education')) {
      score += 10;
    }

    final resumeLower = resumeText.toLowerCase();
    final jobText = '$jobTitle $jobDescription'.toLowerCase();

    final importantWords = _importantWords(jobText);

    int relevantMatches = 0;

    for (final word in importantWords) {
      if (resumeLower.contains(word)) {
        relevantMatches++;
      }
    }

    if (importantWords.isNotEmpty) {
      final relevance = (relevantMatches / importantWords.length) * 100;

      score = (score * 0.60) + (relevance * 0.40);
    }

    return score.clamp(0, 100).toDouble();
  }

  static Set<String> _importantWords(String text) {
    const ignoredWords = {
      'the',
      'and',
      'for',
      'with',
      'this',
      'that',
      'from',
      'your',
      'their',
      'have',
      'has',
      'will',
      'are',
      'you',
      'our',
      'job',
      'role',
      'work',
      'working',
      'experience',
      'skills',
      'required',
      'requirements',
    };

    final words = text
        .replaceAll(RegExp(r'[^a-z0-9+#.]'), ' ')
        .split(RegExp(r'\s+'));

    return words
        .where((word) => word.length > 2 && !ignoredWords.contains(word))
        .toSet();
  }

  static double _calculateCompletenessScore(Map<String, String> sections) {
    const importantSections = [
      'Education',
      'Skills',
      'Projects',
      'Experience',
      'Certifications',
    ];

    int found = 0;

    for (final section in importantSections) {
      if (sections.containsKey(section)) {
        found++;
      }
    }

    return (found / importantSections.length) * 100;
  }

  static double _calculateStructureScore(Map<String, String> sections) {
    if (sections.isEmpty) {
      return 0;
    }

    if (sections.length >= 5) {
      return 100;
    }

    return (sections.length / 5) * 100;
  }

  static List<String> _findMissingKeywords(
    String resumeText,
    String jobTitle,
    String jobDescription,
  ) {
    final resumeLower = resumeText.toLowerCase();

    final jobText = '$jobTitle $jobDescription'.toLowerCase();

    final importantKeywords = {
      'java',
      'python',
      'javascript',
      'typescript',
      'dart',
      'c++',
      'c#',
      'flutter',
      'react',
      'angular',
      'node.js',
      'html',
      'css',
      'sql',
      'mysql',
      'postgresql',
      'mongodb',
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
      'data science',
      'data analysis',
      'pandas',
      'numpy',
      'scikit-learn',
      'tensorflow',
      'pytorch',
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
      'software testing',
      'unit testing',
      'debugging',
      'system design',
      'firebase',
      'android',
      'mobile development',
      'power bi',
      'tableau',
      'excel',
      'figma',
      'agile',
      'scrum',
      'project management',
      'communication',
      'problem solving',
      'teamwork',
    };

    final missing = <String>[];

    for (final keyword in importantKeywords) {
      if (jobText.contains(keyword) && !resumeLower.contains(keyword)) {
        missing.add(keyword);
      }
    }

    return missing;
  }
}
