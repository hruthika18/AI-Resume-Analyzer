import 'skill_dictionary.dart';

class JobSkillExtractionService {
  static Map<String, List<String>> extractSkills(String text) {
    final result = <String, List<String>>{};
    final lowerText = text.toLowerCase();

    for (final category in SkillDictionary.skills.entries) {
      final foundSkills = <String>[];

      for (final skill in category.value) {
        if (_containsSkill(lowerText, skill.toLowerCase())) {
          foundSkills.add(skill);
        }
      }

      if (foundSkills.isNotEmpty) {
        result[category.key] = foundSkills;
      }
    }

    return result;
  }

  static bool _containsSkill(String text, String skill) {
    final pattern = RegExp(
      r'(?<![a-z])' + RegExp.escape(skill) + r'(?![a-z])',
      caseSensitive: false,
    );

    return pattern.hasMatch(text);
  }
}
