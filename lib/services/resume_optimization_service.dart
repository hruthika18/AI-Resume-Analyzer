class ResumeOptimizationResult {
  final List<String> recommendedSkills;
  final List<String> missingSkills;
  final List<String> recommendedKeywords;
  final List<String> missingKeywords;
  final List<String> missingSections;
  final List<String> contentImprovements;
  final List<String> atsImprovements;

  /// Skills/technologies found directly in the text the user typed
  /// (job title + job description). These are explicit requirements.
  final List<String> explicitSkills;

  /// Skills that are NOT present in the user's job description but are
  /// commonly expected for the detected role. These are recommendations,
  /// not requirements the employer actually stated.
  final List<String> roleRecommendedSkills;

  /// True when the job description the user provided was very short
  /// (a role name or just a few words), meaning most of the guidance
  /// below is role-based rather than drawn from explicit text.
  final bool isShortDescription;

  /// Human-readable label for the role that was detected from the
  /// job title/description, used in UI copy such as
  /// "Recommended for <role>".
  final String detectedRoleLabel;

  ResumeOptimizationResult({
    required this.recommendedSkills,
    required this.missingSkills,
    required this.recommendedKeywords,
    required this.missingKeywords,
    required this.missingSections,
    required this.contentImprovements,
    required this.atsImprovements,
    required this.explicitSkills,
    required this.roleRecommendedSkills,
    required this.isShortDescription,
    required this.detectedRoleLabel,
  });
}

class ResumeOptimizationService {
  static ResumeOptimizationResult optimize({
    required String resumeText,
    required String jobTitle,
    required String jobDescription,
  }) {
    final resume = resumeText.toLowerCase();

    final jobInput = '$jobTitle $jobDescription'.trim().toLowerCase();

    final role = _detectRole(jobInput);

    final roleSkills = _roleSkills[role] ?? [];
    final roleKeywords = _roleKeywords[role] ?? [];

    final jobSpecificSkills = _extractKnownTerms(jobInput);
    final jobSpecificKeywords = _extractKnownTerms(jobInput);

    final allSkills = <String>{...roleSkills, ...jobSpecificSkills};

    final allKeywords = <String>{...roleKeywords, ...jobSpecificKeywords};

    final missingSkills = allSkills
        .where((skill) => !_contains(resume, skill))
        .toList();

    final missingKeywords = allKeywords
        .where((keyword) => !_contains(resume, keyword))
        .toList();

    final missingSections = _findMissingSections(resume);

    final contentImprovements = _contentImprovements(
      resume,
      role,
      missingSections,
    );

    final atsImprovements = _atsImprovements(resume, missingSections);

    // Distinguish explicit requirements (found directly in the text the
    // user typed) from role-based recommendations (from the role
    // dictionary but not literally present in the job description).
    final explicitSkillsLower = jobSpecificSkills
        .map((skill) => skill.toLowerCase())
        .toSet();

    final roleRecommendedSkills = roleSkills
        .where((skill) => !explicitSkillsLower.contains(skill.toLowerCase()))
        .toList();

    // Treat a job description under ~15 words (or empty) as "short" --
    // in that case most guidance below leans on role knowledge rather
    // than the employer's own text.
    final wordCount = jobDescription
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final isShortDescription = wordCount < 15;

    return ResumeOptimizationResult(
      recommendedSkills: allSkills.toList(),
      missingSkills: missingSkills,
      recommendedKeywords: allKeywords.toList(),
      missingKeywords: missingKeywords,
      missingSections: missingSections,
      contentImprovements: contentImprovements,
      atsImprovements: atsImprovements,
      explicitSkills: jobSpecificSkills,
      roleRecommendedSkills: roleRecommendedSkills,
      isShortDescription: isShortDescription,
      detectedRoleLabel: _roleLabel(role),
    );
  }

  static String _roleLabel(String role) {
    const labels = {
      'java': 'Java Developer',
      'python': 'Python Developer',
      'flutter': 'Flutter Developer',
      'web': 'Web Developer',
      'aiml': 'AI/ML Intern',
      'data': 'Data Analyst',
      'general': 'this role',
    };

    return labels[role] ?? 'this role';
  }

  // ------------------------------------------------------------
  // ROLE DETECTION
  // ------------------------------------------------------------

  static String _detectRole(String text) {
    if (_containsAny(text, [
      'flutter',
      'dart',
      'mobile developer',
      'android developer',
    ])) {
      return 'flutter';
    }

    if (_containsAny(text, ['java', 'spring boot', 'spring', 'jdbc', 'j2ee'])) {
      return 'java';
    }

    if (_containsAny(text, ['python', 'django', 'flask', 'fastapi'])) {
      return 'python';
    }

    if (_containsAny(text, [
      'javascript',
      'typescript',
      'react',
      'angular',
      'node.js',
      'web developer',
      'frontend',
      'front end',
      'full stack',
    ])) {
      return 'web';
    }

    if (_containsAny(text, [
      'machine learning',
      'deep learning',
      'artificial intelligence',
      'ai/ml',
      'ai ml',
    ])) {
      return 'aiml';
    }

    if (_containsAny(text, [
      'data analyst',
      'data analysis',
      'data analytics',
      'power bi',
      'tableau',
    ])) {
      return 'data';
    }

    return 'general';
  }

  // ------------------------------------------------------------
  // ROLE SKILLS
  // ------------------------------------------------------------

  static const Map<String, List<String>> _roleSkills = {
    'java': [
      'Java',
      'Object-Oriented Programming',
      'Data Structures',
      'Algorithms',
      'Collections',
      'Exception Handling',
      'Multithreading',
      'JDBC',
      'SQL',
      'Git',
      'REST API',
      'Spring',
      'Spring Boot',
      'Unit Testing',
      'Debugging',
    ],

    'python': [
      'Python',
      'Object-Oriented Programming',
      'Data Structures',
      'Algorithms',
      'SQL',
      'Git',
      'REST API',
      'Django',
      'Flask',
      'FastAPI',
      'Pandas',
      'NumPy',
      'Unit Testing',
      'Debugging',
    ],

    'flutter': [
      'Flutter',
      'Dart',
      'Object-Oriented Programming',
      'Mobile Development',
      'Android',
      'REST API',
      'JSON',
      'Firebase',
      'SQLite',
      'Git',
      'GitHub',
      'State Management',
      'UI Development',
      'Debugging',
    ],

    'web': [
      'HTML',
      'CSS',
      'JavaScript',
      'TypeScript',
      'React',
      'Angular',
      'Node.js',
      'REST API',
      'SQL',
      'Git',
      'GitHub',
      'Responsive Design',
      'Web Development',
      'Debugging',
    ],

    'aiml': [
      'Python',
      'Machine Learning',
      'Deep Learning',
      'Artificial Intelligence',
      'Data Analysis',
      'Pandas',
      'NumPy',
      'Scikit-learn',
      'TensorFlow',
      'PyTorch',
      'SQL',
      'Git',
      'Natural Language Processing',
      'Model Evaluation',
    ],

    'data': [
      'Python',
      'SQL',
      'Data Analysis',
      'Data Visualization',
      'Pandas',
      'NumPy',
      'Excel',
      'Power BI',
      'Tableau',
      'Statistics',
      'Git',
      'Data Cleaning',
      'Data Interpretation',
    ],

    'general': [
      'Problem Solving',
      'Communication',
      'Teamwork',
      'Git',
      'GitHub',
      'SQL',
      'Data Structures',
      'Algorithms',
      'Object-Oriented Programming',
      'Debugging',
    ],
  };

  // ------------------------------------------------------------
  // ROLE KEYWORDS
  // ------------------------------------------------------------

  static const Map<String, List<String>> _roleKeywords = {
    'java': [
      'Core Java',
      'Backend Development',
      'Object-Oriented Programming',
      'Data Structures',
      'Algorithms',
      'API Development',
      'Database Integration',
      'Problem Solving',
      'Debugging',
      'Software Development',
    ],

    'python': [
      'Python Development',
      'Backend Development',
      'Object-Oriented Programming',
      'Data Structures',
      'Algorithms',
      'API Development',
      'Database Integration',
      'Automation',
      'Problem Solving',
      'Debugging',
    ],

    'flutter': [
      'Flutter Development',
      'Dart Development',
      'Mobile Application Development',
      'UI Development',
      'Responsive UI',
      'State Management',
      'API Integration',
      'Firebase',
      'SQLite',
      'Cross-Platform Development',
    ],

    'web': [
      'Web Development',
      'Frontend Development',
      'Backend Development',
      'Responsive Design',
      'API Integration',
      'Database Integration',
      'JavaScript Development',
      'Version Control',
      'Problem Solving',
      'Debugging',
    ],

    'aiml': [
      'Machine Learning',
      'Artificial Intelligence',
      'Data Analysis',
      'Feature Engineering',
      'Model Training',
      'Model Evaluation',
      'Data Preprocessing',
      'Natural Language Processing',
      'Deep Learning',
      'Predictive Modeling',
    ],

    'data': [
      'Data Analysis',
      'Data Visualization',
      'Data Cleaning',
      'Data Interpretation',
      'Statistical Analysis',
      'Dashboard Development',
      'Business Intelligence',
      'Reporting',
      'SQL Queries',
      'Data Insights',
    ],

    'general': [
      'Problem Solving',
      'Analytical Thinking',
      'Communication',
      'Teamwork',
      'Project Management',
      'Software Development',
      'Debugging',
      'Version Control',
    ],
  };

  // ------------------------------------------------------------
  // EXTRACT TERMS FROM JOB INPUT
  // ------------------------------------------------------------

  static List<String> _extractKnownTerms(String text) {
    const knownTerms = [
      'Java',
      'Python',
      'C++',
      'C#',
      'JavaScript',
      'TypeScript',
      'Dart',
      'Flutter',
      'React',
      'Angular',
      'Node.js',
      'HTML',
      'CSS',
      'SQL',
      'MySQL',
      'PostgreSQL',
      'MongoDB',
      'Git',
      'GitHub',
      'Docker',
      'Kubernetes',
      'AWS',
      'Azure',
      'Linux',
      'Firebase',
      'SQLite',
      'Spring',
      'Spring Boot',
      'Django',
      'Flask',
      'FastAPI',
      'REST API',
      'GraphQL',
      'Machine Learning',
      'Deep Learning',
      'Artificial Intelligence',
      'Natural Language Processing',
      'Data Science',
      'Data Analysis',
      'Pandas',
      'NumPy',
      'Scikit-learn',
      'TensorFlow',
      'PyTorch',
      'Power BI',
      'Tableau',
      'Excel',
      'Figma',
      'Agile',
      'Scrum',
      'Problem Solving',
      'Communication',
      'Teamwork',
      'Data Structures',
      'Algorithms',
      'Object-Oriented Programming',
      'Unit Testing',
      'Debugging',
    ];

    return knownTerms.where((term) => _contains(text, term)).toList();
  }

  // ------------------------------------------------------------
  // MISSING RESUME SECTIONS
  // ------------------------------------------------------------

  static List<String> _findMissingSections(String resume) {
    final sections = <String>[];

    final sectionChecks = {
      'Professional Summary': ['summary', 'profile', 'objective'],
      'Education': ['education', 'academic', 'qualification'],
      'Technical Skills': ['skills', 'technical skills', 'technologies'],
      'Experience': ['experience', 'work experience', 'employment'],
      'Projects': ['projects', 'project experience'],
      'Certifications': ['certifications', 'certificates'],
      'Achievements': ['achievements', 'awards'],
    };

    for (final entry in sectionChecks.entries) {
      final found = entry.value.any((keyword) => resume.contains(keyword));

      if (!found) {
        sections.add(entry.key);
      }
    }

    return sections;
  }

  // ------------------------------------------------------------
  // CONTENT IMPROVEMENTS
  // ------------------------------------------------------------

  static List<String> _contentImprovements(
    String resume,
    String role,
    List<String> missingSections,
  ) {
    final suggestions = <String>[];

    if (!resume.contains('summary') &&
        !resume.contains('objective') &&
        !resume.contains('profile')) {
      suggestions.add(
        'Add a short professional summary tailored to the target role.',
      );
    }

    if (!resume.contains('project')) {
      suggestions.add(
        'Add relevant projects that demonstrate skills related to the target role.',
      );
    }

    if (!resume.contains('experience')) {
      suggestions.add(
        'Add relevant internship, training, freelance, or work experience if applicable.',
      );
    }

    if (!resume.contains('github')) {
      suggestions.add(
        'Add GitHub or relevant project links when they demonstrate your technical work.',
      );
    }

    if (!resume.contains('achievements') && !resume.contains('award')) {
      suggestions.add(
        'Add relevant achievements, competitions, hackathons, or measurable accomplishments.',
      );
    }

    suggestions.add(
      'Rewrite project and experience bullets to describe your action, technology used, and measurable result.',
    );

    suggestions.add(
      'Prioritize information that directly relates to the target role.',
    );

    return suggestions;
  }

  // ------------------------------------------------------------
  // ATS IMPROVEMENTS
  // ------------------------------------------------------------

  static List<String> _atsImprovements(
    String resume,
    List<String> missingSections,
  ) {
    final suggestions = <String>[];

    if (missingSections.isNotEmpty) {
      suggestions.add(
        'Use clear standard section headings such as Skills, Education, Experience, Projects, and Certifications.',
      );
    }

    suggestions.add(
      'Use the exact relevant technical terms naturally when they accurately describe your experience.',
    );

    suggestions.add(
      'Avoid putting important skills or contact information only inside images, graphics, or decorative elements.',
    );

    suggestions.add(
      'Keep job-relevant skills in a dedicated Technical Skills section.',
    );

    suggestions.add(
      'Use simple, consistent formatting so resume sections can be parsed reliably.',
    );

    suggestions.add(
      'Use bullet points for projects and experience instead of long paragraphs.',
    );

    suggestions.add(
      'Quantify achievements with numbers when the information is genuinely available.',
    );

    suggestions.add(
      'Do not add skills, technologies, or experience that you do not actually have.',
    );

    return suggestions;
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  static bool _contains(String text, String value) {
    final normalizedText = text.toLowerCase();
    final normalizedValue = value.toLowerCase();

    return normalizedText.contains(normalizedValue);
  }

  static bool _containsAny(String text, List<String> values) {
    for (final value in values) {
      if (_contains(text, value)) {
        return true;
      }
    }

    return false;
  }
}
