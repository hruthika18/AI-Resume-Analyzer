import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../services/database_service.dart';
import '../widgets/app_scaffold.dart';
import 'analysis_result_screen.dart';
import 'login_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> history = [];
  bool isLoading = true;
  int? _openingAnalysisId;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final userId = await DatabaseService.getCurrentUserId();

    if (userId == null) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    final data = await DatabaseService.getAnalysisHistoryForUser(userId);

    if (!mounted) return;

    setState(() {
      history = data;
      isLoading = false;
    });
  }

  Future<void> _openAnalysis(int analysisId) async {
    setState(() => _openingAnalysisId = analysisId);

    try {
      final analysisContext = await DatabaseService.getAnalysisWithContext(
        analysisId,
      );

      if (!mounted) return;

      if (analysisContext == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This analysis could not be found anymore.'),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultScreen(
            result: analysisContext['result'] as AnalysisResult,
            resumeFileName: analysisContext['resumeFileName'] as String,
            jobTitle: analysisContext['jobTitle'] as String,
            resumeText: analysisContext['resumeText'] as String,
            jobDescription: analysisContext['jobDescription'] as String,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this analysis.')),
      );
    } finally {
      if (mounted) setState(() => _openingAnalysisId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedItem: 'Analysis History',
      backgroundColor: const Color(0xFFF6F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analysis History',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xFF102752),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'View your previous resume analysis results.',
              style: TextStyle(fontSize: 15, color: Color(0xFF60779D)),
            ),

            const SizedBox(height: 30),

            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF4D55DF)),
                ),
              )
            else if (history.isEmpty)
              _emptyHistory()
            else
              ...history.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _historyCard(
                    analysisId: item['id'] as int,
                    fileName: item['resume_file_name'] ?? '',
                    jobTitle: item['job_title'] ?? '',
                    score: ((item['overall_score'] as num?) ?? 0).round(),
                    date: item['analysis_date'] ?? '',
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _historyCard({
    required int analysisId,
    required String fileName,
    required String jobTitle,
    required int score,
    required String date,
  }) {
    final formattedDate = _formatDate(date);
    final isOpening = _openingAnalysisId == analysisId;

    return InkWell(
      onTap: isOpening ? null : () => _openAnalysis(analysisId),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E4F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFF4D55DF),
                size: 25,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF102752),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    jobTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF60779D),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A98B2),
                    ),
                  ),
                ],
              ),
            ),

            if (isOpening)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4D55DF),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F1FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$score / 100',
                  style: const TextStyle(
                    color: Color(0xFF4D55DF),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.history,
              size: 35,
              color: Color(0xFF4D55DF),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'No Analysis History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102752),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Your completed resume analyses will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF60779D)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);

      return '${_monthName(parsedDate.month)} '
          '${parsedDate.day}, '
          '${parsedDate.year}';
    } catch (_) {
      return date;
    }
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }
}
