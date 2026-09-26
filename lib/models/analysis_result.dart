class AnalysisResult {
  final double overallScore;

  final double skillScore;
  final double keywordScore;
  final double similarityScore;
  final double experienceScore;
  final double completenessScore;
  final double structureScore;

  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> partialSkills;
  final List<String> missingKeywords;

  final List<String> strengths;
  final List<String> improvements;
  final List<String> suggestions;

  AnalysisResult({
    required this.overallScore,
    required this.skillScore,
    required this.keywordScore,
    required this.similarityScore,
    required this.experienceScore,
    required this.completenessScore,
    required this.structureScore,
    required this.matchedSkills,
    required this.missingSkills,
    required this.partialSkills,
    required this.missingKeywords,
    required this.strengths,
    required this.improvements,
    required this.suggestions,
  });
}
