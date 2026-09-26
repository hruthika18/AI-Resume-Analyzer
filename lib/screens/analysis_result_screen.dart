import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../widgets/app_scaffold.dart';
import 'resume_optimizer_screen.dart';

class _ScoreCategory {
  final String label;
  final double percentage;
  final int weight;

  const _ScoreCategory(this.label, this.percentage, this.weight);
}

class AnalysisResultScreen extends StatelessWidget {
  final AnalysisResult result;
  final String resumeFileName;
  final String jobTitle;
  final String resumeText;
  final String jobDescription;

  const AnalysisResultScreen({
    super.key,
    required this.result,
    required this.resumeFileName,
    required this.jobTitle,
    required this.resumeText,
    required this.jobDescription,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedItem: 'Resume Analysis',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),

            const SizedBox(height: 30),

            _scoreCard(),

            const SizedBox(height: 25),

            _scoreBreakdown(),

            const SizedBox(height: 25),

            _quickSummary(),

            const SizedBox(height: 25),

            _detailedAnalysis(),

            const SizedBox(height: 25),

            _improvementsCard(),

            const SizedBox(height: 25),

            _positiveFeedback(),

            const SizedBox(height: 30),

            _backButton(context),
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
          'Resume Analysis',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Color(0xFF102752),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Analysis for $jobTitle',
          style: const TextStyle(fontSize: 15, color: Color(0xFF60779D)),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SCORE CARD
  // ------------------------------------------------------------

  Widget _scoreCard() {
    final score = result.overallScore.round();

    String rating;

    if (score >= 80) {
      rating = 'Excellent Match';
    } else if (score >= 65) {
      rating = 'Good Match';
    } else if (score >= 50) {
      rating = 'Moderate Match';
    } else {
      rating = 'Needs Improvement';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE2F5)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 20,
        children: [
          // Circular score
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFFE9ECF7),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4D55DF),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF102752),
                      ),
                    ),
                    const Text(
                      '/100',
                      style: TextStyle(fontSize: 14, color: Color(0xFF60779D)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Score information
          SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    resumeFileName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF60779D),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Resume Compatibility Score',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF102752),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rating,
                      style: const TextStyle(
                        color: Color(0xFF4D55DF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    'Your resume has been analyzed against the '
                    'requirements of $jobTitle.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF60779D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SCORE BREAKDOWN (explainable score, per the weighting spec)
  // ------------------------------------------------------------

  Widget _scoreBreakdown() {
    final categories = [
      _ScoreCategory('Skill Match', result.skillScore, 25),
      _ScoreCategory('Keyword Match', result.keywordScore, 20),
      _ScoreCategory('Content Similarity', result.similarityScore, 20),
      _ScoreCategory('Projects & Experience', result.experienceScore, 15),
      _ScoreCategory('Resume Completeness', result.completenessScore, 10),
      _ScoreCategory('Resume Structure', result.structureScore, 10),
    ];

    return _card(
      title: 'Score Breakdown',
      subtitle: 'How your Resume Compatibility Score was calculated.',
      child: Column(
        children: categories.map(_breakdownRow).toList(),
      ),
    );
  }

  Widget _breakdownRow(_ScoreCategory category) {
    final earned = (category.percentage / 100) * category.weight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF102752),
                  ),
                ),
              ),
              Text(
                '${earned.toStringAsFixed(1)} / ${category.weight}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4D55DF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (category.percentage / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: const Color(0xFFE9ECF7),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4D55DF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // QUICK SUMMARY
  // ------------------------------------------------------------

  Widget _quickSummary() {
    return _card(
      title: 'Quick Summary',
      child: Column(
        children: [
          _summaryRow(
            Icons.check_circle_outline,
            'Skills Match',
            '${result.skillScore.round()}%',
          ),
          _summaryRow(
            Icons.key_outlined,
            'Keyword Match',
            '${result.keywordScore.round()}%',
          ),
          _summaryRow(
            Icons.compare_arrows,
            'Job Similarity',
            '${result.similarityScore.round()}%',
          ),
          _summaryRow(
            Icons.work_outline,
            'Experience',
            '${result.experienceScore.round()}%',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 21, color: const Color(0xFF4D55DF)),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, color: Color(0xFF30466D)),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF102752),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DETAILED ANALYSIS
  // ------------------------------------------------------------

  Widget _detailedAnalysis() {
    return _card(
      title: 'Skills Match',
      subtitle: 'Skills found in your resume compared with the target job.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.matchedSkills.isNotEmpty) ...[
            const Text(
              'Matched Skills',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF102752),
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.matchedSkills
                  .map((skill) => _skillChip(skill, true))
                  .toList(),
            ),

            const SizedBox(height: 20),
          ],

          if (result.partialSkills.isNotEmpty) ...[
            const Text(
              'Related Skills',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF102752),
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.partialSkills
                  .map((skill) => _skillChip(skill, null))
                  .toList(),
            ),

            const SizedBox(height: 20),
          ],

          if (result.missingSkills.isNotEmpty) ...[
            const Text(
              'Missing Skills',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF102752),
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.missingSkills
                  .map((skill) => _skillChip(skill, false))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _skillChip(String skill, bool? matched) {
    Color background;
    Color textColor;
    IconData icon;

    if (matched == true) {
      background = const Color(0xFFEAF8F0);
      textColor = const Color(0xFF218A52);
      icon = Icons.check;
    } else if (matched == false) {
      background = const Color(0xFFFFEEEE);
      textColor = const Color(0xFFD34A4A);
      icon = Icons.close;
    } else {
      background = const Color(0xFFFFF7E5);
      textColor = const Color(0xFFB27A00);
      icon = Icons.remove;
    }

    return Chip(
      avatar: Icon(icon, size: 15, color: textColor),
      label: Text(skill),
      backgroundColor: background,
      labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      side: BorderSide.none,
    );
  }

  // ------------------------------------------------------------
  // IMPROVEMENTS
  // ------------------------------------------------------------

  Widget _improvementsCard() {
    return _card(
      title: 'Improvements Needed',
      subtitle: 'Focus on these areas to strengthen your resume.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.improvements.isEmpty)
            const Text(
              'No major improvements were identified.',
              style: TextStyle(color: Color(0xFF60779D)),
            )
          else
            ...result.improvements.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
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
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // POSITIVE FEEDBACK
  // ------------------------------------------------------------

  Widget _positiveFeedback() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: Color(0xFF218A52)),

          SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're on the right track!",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF176B40),
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'With a few improvements, your resume can become even stronger and more relevant to the target role.',
                  style: TextStyle(height: 1.4, color: Color(0xFF3C6951)),
                ),
              ],
            ),
          ),
        ],
      ),
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

  // ------------------------------------------------------------
  // BACK BUTTON
  // ------------------------------------------------------------

  Widget _backButton(BuildContext context) {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: [
        SizedBox(
          width: 260,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4D55DF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF4D55DF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 260,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResumeOptimizerScreen(
                    result: result,
                    resumeFileName: resumeFileName,
                    jobTitle: jobTitle,
                    resumeText: resumeText,
                    jobDescription: jobDescription,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Optimize My Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D55DF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
