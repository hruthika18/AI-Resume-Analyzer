import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../services/analysis_service.dart';
import '../services/database_service.dart';
import '../services/job_skill_extraction_service.dart';
import '../services/resume_optimization_service.dart';
import '../services/section_detection_service.dart';
import '../services/skill_extraction_service.dart';
import '../widgets/app_scaffold.dart';
import 'analysis_result_screen.dart';

class ResumeAnalysisScreen extends StatefulWidget {
  const ResumeAnalysisScreen({super.key});

  @override
  State<ResumeAnalysisScreen> createState() => _ResumeAnalysisScreenState();
}

class _ResumeAnalysisScreenState extends State<ResumeAnalysisScreen> {
  static const List<String> _predefinedRoles = [
    'Flutter Developer',
    'Java Developer',
    'Python Developer',
    'Web Developer',
    'Data Analyst',
    'AI/ML Intern',
  ];

  bool resumeSelected = false;
  String selectedFileName = '';
  Uint8List? selectedFileBytes;

  String extractedText = '';

  Map<String, String> resumeSections = {};
  Map<String, List<String>> extractedSkills = {};

  final TextEditingController jobTitleController = TextEditingController();

  final TextEditingController jobDescriptionController =
      TextEditingController();

  String? _selectedRole;
  bool isExtracting = false;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    jobTitleController.dispose();
    jobDescriptionController.dispose();
    super.dispose();
  }

  Future<void> selectResume() async {
    try {
      final PlatformFile? picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (picked == null) {
        // User canceled the picker.
        return;
      }

      final bytes = await picked.readAsBytes();

      setState(() {
        resumeSelected = true;
        selectedFileName = picked.name;
        selectedFileBytes = bytes;
        isExtracting = true;
      });

      await extractResumeText();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the file picker: ${_shortError(e)}')),
      );
    }
  }

  String cleanResumeText(String text) {
    String cleaned = text;

    cleaned = cleaned.replaceAll('—', ' ');
    cleaned = cleaned.replaceAll('–', ' ');
    cleaned = cleaned.replaceAll('•', ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    return cleaned.trim();
  }

  Future<void> extractResumeText() async {
    if (selectedFileBytes == null) {
      return;
    }

    try {
      final document = PdfDocument(inputBytes: selectedFileBytes!);

      final text = PdfTextExtractor(document).extractText(layoutText: true);

      document.dispose();

      final cleanedText = cleanResumeText(text);

      // Guard against scanned/image-only PDFs that extract to little or
      // no usable text.
      if (cleanedText.length < 30) {
        setState(() {
          isExtracting = false;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This PDF does not contain enough readable text. It may be a '
              'scanned image -- please upload a text-based PDF resume.',
            ),
          ),
        );

        removeResume();
        return;
      }

      final detectedSections = SectionDetectionService.detectSections(
        cleanedText,
      );

      final detectedSkills = SkillExtractionService.extractSkills(cleanedText);

      setState(() {
        extractedText = cleanedText;
        resumeSections = detectedSections;
        extractedSkills = detectedSkills;
        isExtracting = false;
      });
    } catch (e) {
      setState(() {
        isExtracting = false;
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not read this PDF: ${_shortError(e)}')),
      );

      removeResume();
    }
  }

  void removeResume() {
    setState(() {
      resumeSelected = false;
      selectedFileName = '';
      selectedFileBytes = null;
      extractedText = '';
      resumeSections = {};
      extractedSkills = {};
    });
  }

  Future<void> analyzeResume() async {
    final jobTitle = jobTitleController.text.trim();

    final jobDescription = jobDescriptionController.text.trim();

    if (!resumeSelected || extractedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your resume first.')),
      );
      return;
    }

    if (jobTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a target job title.'),
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // 1. Extract skills the job actually mentions (title + description).
      final combinedJobText = '$jobTitle $jobDescription'.trim();
      var jobSkills = JobSkillExtractionService.extractSkills(
        combinedJobText,
      );

      final explicitSkillCount = jobSkills.values.fold<int>(
        0,
        (sum, list) => sum + list.length,
      );

      // 2. If the job description is short/one-word (few explicit skills
      // found), supplement with role-based industry-standard skills so the
      // analysis stays meaningful, per the app's short-JD requirement.
      if (explicitSkillCount < 3) {
        final roleBased = ResumeOptimizationService.optimize(
          resumeText: extractedText,
          jobTitle: jobTitle,
          jobDescription: jobDescription,
        );

        final existing = <String>{
          for (final list in jobSkills.values)
            ...list.map((skill) => skill.toLowerCase()),
        };

        final additional = roleBased.recommendedSkills
            .where((skill) => !existing.contains(skill.toLowerCase()))
            .toList();

        if (additional.isNotEmpty) {
          jobSkills = {...jobSkills, 'Recommended for Role': additional};
        }
      }

      // 3. Run the core weighted analysis.
      final result = AnalysisService.analyze(
        resumeText: extractedText,
        resumeSections: resumeSections,
        resumeSkills: extractedSkills,
        jobTitle: jobTitle,
        jobDescription: jobDescription,
        jobSkills: jobSkills,
      );

      // 4. Persist the resume, job description and full explainable
      // analysis so it can be reopened later from History.
      final userId = await DatabaseService.getCurrentUserId();

      if (userId != null) {
        final resumeId = await DatabaseService.saveResume(
          userId: userId,
          fileName: selectedFileName,
          extractedText: extractedText,
        );

        final jobDescriptionId = await DatabaseService.saveJobDescription(
          userId: userId,
          title: jobTitle,
          description: jobDescription,
        );

        await DatabaseService.saveFullAnalysis(
          userId: userId,
          resumeId: resumeId,
          jobDescriptionId: jobDescriptionId,
          resumeFileName: selectedFileName,
          jobTitle: jobTitle,
          result: result,
        );
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultScreen(
            result: result,
            resumeFileName: selectedFileName,
            jobTitle: jobTitle,
            resumeText: extractedText,
            jobDescription: jobDescription,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: ${_shortError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  String _shortError(Object e) {
    final text = e.toString();
    return text.length > 140 ? '${text.substring(0, 140)}...' : text;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedItem: 'Resume Analysis',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
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

            const Text(
              'Upload your resume and compare it with a target job description.',
              style: TextStyle(fontSize: 15, color: Color(0xFF60779D)),
            ),

            const SizedBox(height: 30),

            _uploadSection(),

            if (resumeSelected) ...[
              const SizedBox(height: 25),
              _resumeInformation(),
            ],

            const SizedBox(height: 30),

            _jobSection(),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isExtracting || _isAnalyzing)
                    ? null
                    : analyzeResume,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isAnalyzing ? 'Analyzing...' : 'Analyze Resume',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4D55DF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. Upload Resume',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102752),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Upload your resume in PDF format.',
            style: TextStyle(fontSize: 14, color: Color(0xFF60779D)),
          ),

          const SizedBox(height: 20),

          if (!resumeSelected) _uploadBox() else _selectedResume(),
        ],
      ),
    );
  }

  Widget _uploadBox() {
    return InkWell(
      onTap: selectResume,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCCD5EF)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 45,
              color: Color(0xFF4D55DF),
            ),

            const SizedBox(height: 15),

            const Text(
              'Click to upload your resume',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF102752),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'PDF files only',
              style: TextStyle(fontSize: 13, color: Color(0xFF7183A3)),
            ),

            const SizedBox(height: 18),

            ElevatedButton(
              onPressed: selectResume,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D55DF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Choose Resume'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedResume() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            color: Color(0xFF4D55DF),
            size: 30,
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedFileName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF102752),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  isExtracting
                      ? 'Extracting resume content...'
                      : 'Resume uploaded successfully',
                  style: const TextStyle(fontSize: 13, color: Colors.green),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: removeResume,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _resumeInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resume Information',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102752),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Extracted Text: ${extractedText.length} characters',
            style: const TextStyle(color: Color(0xFF60779D)),
          ),

          const SizedBox(height: 8),

          Text(
            'Sections Detected: ${resumeSections.length}',
            style: const TextStyle(color: Color(0xFF60779D)),
          ),

          const SizedBox(height: 8),

          Text(
            'Skill Categories: ${extractedSkills.length}',
            style: const TextStyle(color: Color(0xFF60779D)),
          ),
        ],
      ),
    );
  }

  Widget _jobSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '2. Target Job',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102752),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Pick a predefined role for quick industry-standard analysis, '
            'or enter your own job title and description.',
            style: TextStyle(fontSize: 14, color: Color(0xFF60779D)),
          ),

          const SizedBox(height: 20),

          const Text(
            'Predefined Role (optional)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF102752),
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _predefinedRoles.map((role) {
              final isSelected = _selectedRole == role;

              return ChoiceChip(
                label: Text(role),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedRole = selected ? role : null;
                    if (selected) {
                      jobTitleController.text = role;
                    }
                  });
                },
                selectedColor: const Color(0xFF4D55DF),
                backgroundColor: const Color(0xFFF0F1FF),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF30466D),
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide.none,
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          const Text(
            'Job Title',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF102752),
            ),
          ),

          const SizedBox(height: 9),

          TextField(
            controller: jobTitleController,
            onChanged: (_) {
              if (_selectedRole != null &&
                  jobTitleController.text != _selectedRole) {
                setState(() => _selectedRole = null);
              }
            },
            decoration: InputDecoration(
              hintText: 'e.g. Software Engineer',
              filled: true,
              fillColor: const Color(0xFFF7F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Job Description (optional)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF102752),
            ),
          ),

          const SizedBox(height: 9),

          TextField(
            controller: jobDescriptionController,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: 'Paste the job description here...',
              filled: true,
              fillColor: const Color(0xFFF7F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'You can leave this short or even blank -- for a selected role '
            'we will also compare your resume against general industry '
            'requirements for that role.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF7183A3),
            ),
          ),
        ],
      ),
    );
  }
}
