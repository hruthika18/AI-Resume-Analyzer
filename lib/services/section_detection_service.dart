class SectionDetectionService {
  static final Map<String, List<String>> sectionAliases = {
    'Education': [
      'education',
      'academic background',
      'academic qualifications',
      'educational background',
      'qualifications',
      'education background',
      'academic history',
    ],

    'Experience': [
      'experience',
      'work experience',
      'professional experience',
      'employment history',
      'career history',
      'work history',
      'professional background',
    ],

    'Internships': [
      'internships',
      'internship',
      'industrial training',
      'training experience',
      'internship experience',
    ],

    'Projects': [
      'projects',
      'academic projects',
      'personal projects',
      'technical projects',
      'key projects',
      'project experience',
    ],

    'Skills': [
      'skills',
      'technical skills',
      'technical expertise',
      'core skills',
      'core competencies',
      'skills summary',
      'areas of expertise',
      'professional skills',
    ],

    'Certifications': [
      'certifications',
      'certificates',
      'professional certifications',
      'credentials',
      'licenses and certifications',
    ],

    'Achievements': [
      'achievements',
      'awards',
      'honors',
      'accomplishments',
      'recognitions',
      'honors and awards',
    ],

    'Hackathons': [
      'hackathons',
      'hackathon',
      'coding competitions',
      'coding competition',
      'competitions',
    ],

    'Publications': [
      'publications',
      'research publications',
      'papers',
      'research papers',
      'research work',
      'published work',
    ],

    'Training': [
      'training',
      'professional training',
      'trainings',
      'workshops',
      'workshop',
    ],

    'Volunteer Experience': [
      'volunteer experience',
      'volunteering',
      'community service',
      'social activities',
      'volunteer work',
    ],

    'Leadership': [
      'leadership',
      'leadership experience',
      'leadership activities',
      'positions of responsibility',
    ],

    'Extracurricular Activities': [
      'extracurricular activities',
      'extra curricular activities',
      'activities',
      'co-curricular activities',
      'campus activities',
    ],

    'Interests': ['interests', 'hobbies', 'personal interests'],

    'Languages': ['languages', 'language skills', 'spoken languages'],

    'References': ['references', 'professional references'],
  };

  static Map<String, String> detectSections(String text) {
    final sections = <String, String>{};

    final normalizedText = text
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (match) => ' ')
        .replaceAllMapped(RegExp(r'(?<=[0-9])(?=[A-Z])'), (match) => ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final matches = <MapEntry<String, int>>[];

    for (final entry in sectionAliases.entries) {
      for (final alias in entry.value) {
        final pattern = RegExp(
          r'(?<![A-Za-z])' + RegExp.escape(alias) + r'(?![A-Za-z])',
          caseSensitive: false,
        );

        final match = pattern.firstMatch(normalizedText);

        if (match != null) {
          matches.add(MapEntry(entry.key, match.start));
          break;
        }
      }
    }

    matches.sort((a, b) => a.value.compareTo(b.value));

    for (int i = 0; i < matches.length; i++) {
      final sectionName = matches[i].key;
      final start = matches[i].value;

      final end = i + 1 < matches.length
          ? matches[i + 1].value
          : normalizedText.length;

      sections[sectionName] = normalizedText.substring(start, end).trim();
    }

    return sections;
  }
}
