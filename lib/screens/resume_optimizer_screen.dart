import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../services/resume_optimization_service.dart';
import '../widgets/app_scaffold.dart';

class ResumeOptimizerScreen extends StatelessWidget {
  final AnalysisResult result;
  final String resumeFileName;
  final String jobTitle;
  final String resumeText;
  final String jobDescription;

  const ResumeOptimizerScreen({
    super.key,
    required this.result,
    required this.resumeFileName,
    required this.jobTitle,
    required this.resumeText,
    required this.jobDescription,
  });

  @override
  Widget build(BuildContext context) {
    final optimization = ResumeOptimizationService.optimize(
      resumeText: resumeText,
      jobTitle: jobTitle,
      jobDescription: jobDescription,
    );

    return AppScaffold(
      selectedItem: 'Resume Optimizer',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),

            const SizedBox(height: 28),

            _resumeInfo(),

            if (optimization.isShortDescription) ...[
              const SizedBox(height: 20),
              _shortDescriptionNotice(optimization),
            ],

            const SizedBox(height: 20),

            _resumeGaps(),

            const SizedBox(height: 20),

            _skillsToAdd(optimization),

            const SizedBox(height: 20),

            _missingSections(optimization),

            const SizedBox(height: 20),

            _keywordsToAdd(optimization),

            const SizedBox(height: 20),

            _contentImprovements(optimization),

            const SizedBox(height: 20),

            _atsImprovements(optimization),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resume Optimizer',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Color(0xFF102752),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Find what your resume is missing for the $jobTitle role.',
          style: const TextStyle(fontSize: 15, color: Color(0xFF60779D)),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // RESUME INFORMATION
  // ------------------------------------------------------------

  Widget _resumeInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF1FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE2F5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            color: Color(0xFF4D55DF),
            size: 28,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resume analyzed',
                  style: TextStyle(fontSize: 13, color: Color(0xFF60779D)),
                ),

                const SizedBox(height: 4),

                Text(
                  resumeFileName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF102752),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SHORT DESCRIPTION NOTICE
  // ------------------------------------------------------------

  Widget _shortDescriptionNotice(ResumeOptimizationResult optimization) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF4E3B8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF9A6B00)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'The job description you provided was short, so several '
              'recommendations below are based on general industry '
              'expectations for ${optimization.detectedRoleLabel} rather '
              'than requirements you explicitly entered.',
              style: const TextStyle(color: Color(0xFF6B4E00), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // RESUME GAPS (from the core analysis result)
  // ------------------------------------------------------------

  Widget _resumeGaps() {
    final gaps = <Map<String, dynamic>>[];

    if (result.missingSkills.isNotEmpty) {
      gaps.add({
        'icon': Icons.psychology_outlined,
        'title': 'Relevant Skills',
        'description':
            '${result.missingSkills.length} relevant skill(s) from the job description were not detected in your resume.',
        'color': const Color(0xFFD34A4A),
      });
    }

    if (result.missingKeywords.isNotEmpty) {
      gaps.add({
        'icon': Icons.key_outlined,
        'title': 'Job Keywords',
        'description':
            '${result.missingKeywords.length} important job keyword(s) are missing or underrepresented.',
        'color': const Color(0xFFB27A00),
      });
    }

    if (result.experienceScore < 60) {
      gaps.add({
        'icon': Icons.work_outline,
        'title': 'Experience Relevance',
        'description':
            'Your projects or experience could be connected more clearly to the target role.',
        'color': const Color(0xFFB27A00),
      });
    }

    if (result.completenessScore < 70) {
      gaps.add({
        'icon': Icons.checklist_outlined,
        'title': 'Resume Completeness',
        'description':
            'Some common resume sections may be missing or incomplete.',
        'color': const Color(0xFFD34A4A),
      });
    }

    return _card(
      title: 'Where Your Resume Lacks',
      subtitle: 'Areas that may be reducing your compatibility with this job.',
      child: gaps.isEmpty
          ? const Text(
              'No major gaps were detected.',
              style: TextStyle(color: Color(0xFF60779D)),
            )
          : Column(
              children: gaps
                  .map(
                    (gap) => _gapRow(
                      icon: gap['icon'],
                      title: gap['title'],
                      description: gap['description'],
                      color: gap['color'],
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _gapRow({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E7F3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 23),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF102752),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: const TextStyle(height: 1.4, color: Color(0xFF60779D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SKILLS TO ADD (explicit JD requirements vs role recommendations)
  // ------------------------------------------------------------

  Widget _skillsToAdd(ResumeOptimizationResult optimization) {
    final missingLower = optimization.missingSkills
        .map((skill) => skill.toLowerCase())
        .toSet();

    final missingExplicit = optimization.explicitSkills
        .where((skill) => missingLower.contains(skill.toLowerCase()))
        .toList();

    final missingRoleOnly = optimization.roleRecommendedSkills
        .where((skill) => missingLower.contains(skill.toLowerCase()))
        .toList();

    return _card(
      title: 'Skills You Can Add',
      subtitle:
          'Skills relevant to this role that were not detected in your resume.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (missingExplicit.isNotEmpty) ...[
            const Text(
              'From the Job Description',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF102752),
              ),
            ),
            const SizedBox(height: 10),
            _chipWrap(
              missingExplicit,
              const Color(0xFFF0F1FF),
              const Color(0xFF30466D),
            ),
            const SizedBox(height: 18),
          ],
          if (missingRoleOnly.isNotEmpty) ...[
            Text(
              'Recommended for ${optimization.detectedRoleLabel} (industry standard)',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF102752),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Not explicitly requested in the job description, but commonly expected for this role.',
              style: TextStyle(fontSize: 12, color: Color(0xFF7183A3)),
            ),
            const SizedBox(height: 10),
            _chipWrap(
              missingRoleOnly,
              const Color(0xFFFFF7E5),
              const Color(0xFF9A6B00),
            ),
            const SizedBox(height: 12),
          ],
          if (missingExplicit.isEmpty && missingRoleOnly.isEmpty)
            const Text(
              'No additional skills were identified.',
              style: TextStyle(color: Color(0xFF60779D)),
            ),
          const SizedBox(height: 6),
          const Text(
            'Only add a skill if you genuinely have experience with it.',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Color(0xFF60779D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipWrap(List<String> items, Color background, Color textColor) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => Chip(
              avatar: Icon(Icons.add, size: 16, color: textColor),
              label: Text(item),
              backgroundColor: background,
              labelStyle: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide.none,
            ),
          )
          .toList(),
    );
  }

  // ------------------------------------------------------------
  // MISSING SECTIONS
  // ------------------------------------------------------------

  Widget _missingSections(ResumeOptimizationResult optimization) {
    return _card(
      title: 'Sections You Could Add',
      subtitle: 'Common resume sections that were not clearly detected.',
      child: optimization.missingSections.isEmpty
          ? const Text(
              'All key sections were detected in your resume.',
              style: TextStyle(color: Color(0xFF60779D)),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: optimization.missingSections
                  .map(
                    (section) => Chip(
                      avatar: const Icon(
                        Icons.add_box_outlined,
                        size: 16,
                        color: Color(0xFF4D55DF),
                      ),
                      label: Text(section),
                      backgroundColor: const Color(0xFFF0F1FF),
                      labelStyle: const TextStyle(
                        color: Color(0xFF30466D),
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
    );
  }

  // ------------------------------------------------------------
  // KEYWORDS TO ADD
  // ------------------------------------------------------------

  Widget _keywordsToAdd(ResumeOptimizationResult optimization) {
    return _card(
      title: 'Keywords You Can Add',
      subtitle:
          'Important terms for this role that are not detected in your resume.',
      child: optimization.missingKeywords.isEmpty
          ? const Text(
              'No major missing keywords were identified.',
              style: TextStyle(color: Color(0xFF60779D)),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: optimization.missingKeywords
                  .map(
                    (keyword) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        keyword,
                        style: const TextStyle(
                          color: Color(0xFF9A6B00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  // ------------------------------------------------------------
  // CONTENT / ATS IMPROVEMENTS
  // ------------------------------------------------------------

  Widget _contentImprovements(ResumeOptimizationResult optimization) {
    return _card(
      title: 'Content That Could Be Improved',
      subtitle:
          'Ways to make your resume content more relevant to the target role.',
      child: _numberedList(optimization.contentImprovements),
    );
  }

  Widget _atsImprovements(ResumeOptimizationResult optimization) {
    return _card(
      title: 'Formatting & Structure Tips',
      subtitle: 'Improve how reliably your resume can be read and parsed.',
      child: _numberedList(optimization.atsImprovements),
    );
  }

  Widget _numberedList(List<String> items) {
    if (items.isEmpty) {
      return const Text(
        'No suggestions were identified.',
        style: TextStyle(color: Color(0xFF60779D)),
      );
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${entry.key + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4D55DF),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    height: 1.4,
                    color: Color(0xFF30466D),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------
  // COMMON CARD
  // ------------------------------------------------------------

  Widget _card({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102752),
            ),
          ),

          if (subtitle != null) ...[
            const SizedBox(height: 6),

            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Color(0xFF60779D)),
            ),
          ],

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }
}
