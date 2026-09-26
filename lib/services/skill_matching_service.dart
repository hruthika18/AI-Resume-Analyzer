class SkillMatchingService {
  static Map<String, List<String>> matchSkills({
    required Map<String, List<String>> resumeSkills,
    required Map<String, List<String>> jobSkills,
  }) {
    final matchedSkills = <String>[];
    final missingSkills = <String>[];
    final partialSkills = <String>[];

    final resumeSkillSet = <String>{};

    for (final skills in resumeSkills.values) {
      for (final skill in skills) {
        resumeSkillSet.add(_normalize(skill));
      }
    }

    final processedSkills = <String>{};

    for (final skills in jobSkills.values) {
      for (final skill in skills) {
        final normalizedSkill = _normalize(skill);

        if (processedSkills.contains(normalizedSkill)) {
          continue;
        }

        processedSkills.add(normalizedSkill);

        if (resumeSkillSet.contains(normalizedSkill)) {
          matchedSkills.add(skill);
        } else if (_hasRelatedSkill(normalizedSkill, resumeSkillSet)) {
          partialSkills.add(skill);
        } else {
          missingSkills.add(skill);
        }
      }
    }

    return {
      'matched': matchedSkills,
      'missing': missingSkills,
      'partial': partialSkills,
    };
  }

  static String _normalize(String skill) {
    return skill.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool _hasRelatedSkill(String jobSkill, Set<String> resumeSkills) {
    final relatedSkills = <String, Set<String>>{
      'flutter': {'dart', 'android', 'mobile development'},
      'dart': {'flutter'},
      'machine learning': {'python', 'scikit-learn', 'tensorflow', 'pytorch'},
      'deep learning': {'machine learning', 'tensorflow', 'pytorch', 'python'},
      'data science': {'python', 'pandas', 'numpy', 'scikit-learn'},
      'data analysis': {
        'python',
        'pandas',
        'numpy',
        'sql',
        'excel',
        'power bi',
        'tableau',
      },
      'sql': {'mysql', 'postgresql', 'sqlite', 'oracle', 'database management'},
      'mysql': {'sql', 'database management'},
      'postgresql': {'sql', 'database management'},
      'javascript': {'html', 'css', 'react', 'node.js'},
      'web development': {'html', 'css', 'javascript'},
      'frontend development': {
        'html',
        'css',
        'javascript',
        'react',
        'angular',
        'vue.js',
      },
      'backend development': {
        'node.js',
        'express.js',
        'spring boot',
        'django',
        'flask',
        'fastapi',
        'rest api',
      },
      'android': {'flutter', 'dart', 'kotlin', 'java'},
      'java': {'spring', 'spring boot', 'android'},
      'python': {'machine learning', 'data science', 'data analysis'},
      'react': {'javascript', 'html', 'css'},
      'rest api': {'api development', 'web services'},
      'devops': {
        'docker',
        'kubernetes',
        'jenkins',
        'ci/cd',
        'linux',
        'aws',
        'azure',
      },
      'cloud computing': {'aws', 'azure', 'google cloud', 'gcp'},
    };

    final related = relatedSkills[jobSkill];

    if (related == null) {
      return false;
    }

    for (final resumeSkill in resumeSkills) {
      if (related.contains(resumeSkill)) {
        return true;
      }
    }

    return false;
  }
}
