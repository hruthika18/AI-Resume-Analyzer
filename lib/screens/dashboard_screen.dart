import 'package:flutter/material.dart';

import '../services/database_service.dart';
import '../widgets/app_scaffold.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'resume_analysis_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await DatabaseService.getCurrentUser();

    if (user == null) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    final stats = await DatabaseService.getUserStats(user['id'] as int);

    if (!mounted) return;

    setState(() {
      _user = user;
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScaffold(
        selectedItem: 'Dashboard',
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4D55DF)),
        ),
      );
    }

    final user = _user!;
    final stats = _stats ?? {};
    final latestResume = stats['latestResume'] as Map<String, dynamic>?;
    final analysesCount = stats['analysesCount'] as int? ?? 0;
    final recentAnalyses =
        (stats['recentAnalyses'] as List<Map<String, dynamic>>?) ?? [];

    return AppScaffold(
      selectedItem: 'Dashboard',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(user),

            const SizedBox(height: 28),

            _welcomeSection(context, user, latestResume),

            const SizedBox(height: 28),

            _featureCards(context, analysesCount, latestResume),

            const SizedBox(height: 30),

            _middleSection(context, recentAnalyses),

            const SizedBox(height: 30),

            _howItWorks(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------

  Widget _topBar(Map<String, dynamic> user) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102752),
            ),
          ),
        ),

        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openProfile(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EBFF),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(user['name'] as String? ?? ''),
              style: const TextStyle(
                color: Color(0xFF4D55DF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(fade);

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // WELCOME SECTION
  // ------------------------------------------------------------

  Widget _welcomeSection(
    BuildContext context,
    Map<String, dynamic> user,
    Map<String, dynamic>? latestResume,
  ) {
    final firstName = (user['name'] as String? ?? '').trim().isEmpty
        ? 'there'
        : (user['name'] as String).trim().split(RegExp(r'\s+')).first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF0FF), Color(0xFFF8F9FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE2F5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $firstName',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF102752),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  latestResume == null
                      ? 'Upload your resume and compare it against a target role to see how you match up.'
                      : 'Ready for another analysis? Compare your resume against a new role, or review your past results.',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF60779D),
                  ),
                ),

                const SizedBox(height: 22),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ResumeAnalysisScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Resume Analysis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D55DF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 30),

          Container(
            width: 125,
            height: 125,
            decoration: BoxDecoration(
              color: const Color(0xFFE3E6FF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 58,
              color: Color(0xFF4D55DF),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FEATURE CARDS (now used as live stat cards)
  // ------------------------------------------------------------

  Widget _featureCards(
    BuildContext context,
    int analysesCount,
    Map<String, dynamic>? latestResume,
  ) {
    return Row(
      children: [
        Expanded(
          child: _featureCard(
            icon: Icons.description_outlined,
            title: latestResume == null ? 'No Resume Yet' : 'Resume Uploaded',
            description: latestResume == null
                ? 'Upload a resume to get started.'
                : (latestResume['file_name'] as String? ?? 'Resume on file'),
          ),
        ),

        const SizedBox(width: 18),

        Expanded(
          child: _featureCard(
            icon: Icons.analytics_outlined,
            title: 'Analyses Performed',
            description: '$analysesCount total analysis run(s).',
          ),
        ),

        const SizedBox(width: 18),

        Expanded(
          child: _featureCard(
            icon: Icons.trending_up,
            title: 'Improve Your Resume',
            description: 'Understand what can make your resume stronger.',
          ),
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF4D55DF), size: 24),
          ),

          const SizedBox(height: 17),

          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102752),
            ),
          ),

          const SizedBox(height: 7),

          Text(
            description,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF60779D),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // MIDDLE SECTION
  // ------------------------------------------------------------

  Widget _middleSection(
    BuildContext context,
    List<Map<String, dynamic>> recentAnalyses,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _recentActivity(context, recentAnalyses)),

        const SizedBox(width: 20),

        Expanded(flex: 2, child: _quickStart()),
      ],
    );
  }

  // ------------------------------------------------------------
  // RECENT ACTIVITY
  // ------------------------------------------------------------

  Widget _recentActivity(
    BuildContext context,
    List<Map<String, dynamic>> recentAnalyses,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF102752),
                  ),
                ),
              ),
              if (recentAnalyses.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF4D55DF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          if (recentAnalyses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 30,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.history, size: 35, color: Color(0xFF9AA8C2)),
                  SizedBox(height: 10),
                  Text(
                    'No recent analyses',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF30466D),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Start your first analysis to get started!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF7183A3)),
                  ),
                ],
              ),
            )
          else
            ...recentAnalyses.map((analysis) {
              final score = ((analysis['overall_score'] as num?) ?? 0)
                  .round();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              analysis['job_title'] as String? ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF102752),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              analysis['resume_file_name'] as String? ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7183A3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEFFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$score/100',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4D55DF),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // QUICK START
  // ------------------------------------------------------------

  Widget _quickStart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Start',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102752),
            ),
          ),

          const SizedBox(height: 18),

          _quickStartItem('1', 'Upload your resume'),

          _quickStartItem('2', 'Add a target job'),

          _quickStartItem('3', 'Analyze your resume'),

          _quickStartItem('4', 'Review AI insights'),
        ],
      ),
    );
  }

  Widget _quickStartItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
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
              number,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF4D55DF),
              ),
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF30466D)),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HOW IT WORKS
  // ------------------------------------------------------------

  Widget _howItWorks() {
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
          const Text(
            'How It Works',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102752),
            ),
          ),

          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final steps = [
                _step(
                  '01',
                  Icons.upload_file_outlined,
                  'Upload Resume',
                  'Upload your PDF resume.',
                ),
                _step(
                  '02',
                  Icons.work_outline,
                  'Add Job',
                  'Enter the target job description.',
                ),
                _step(
                  '03',
                  Icons.auto_awesome,
                  'Analyze',
                  'AI compares your resume with the job.',
                ),
                _step(
                  '04',
                  Icons.insights_outlined,
                  'Improve',
                  'Review your results and suggestions.',
                ),
              ];

              // On wide screens, stretch the four steps to fill the whole
              // card width evenly instead of leaving empty space on the
              // right. On narrow screens, fall back to a wrapping grid so
              // the text doesn't get squeezed.
              if (constraints.maxWidth >= 640) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: steps
                      .map((step) => Expanded(child: step))
                      .toList(),
                );
              }

              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: steps
                    .map((step) => SizedBox(width: 220, child: step))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _step(String number, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4D55DF),
                ),
              ),

              const SizedBox(width: 8),

              Icon(icon, size: 20, color: const Color(0xFF4D55DF)),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102752),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF7183A3),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
