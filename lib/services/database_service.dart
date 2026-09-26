import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/analysis_result.dart';
import '../utils/password_utils.dart';

/// Central data-access layer for the app.
///
/// Entities (matching the intended schema: User, Resume, JobDescription,
/// Analysis, SkillMatch, Suggestion):
///   users             - registered accounts
///   resumes           - uploaded resumes per user
///   job_descriptions  - target jobs a user analyzed against
///   analyses          - one row per analysis run, with the six score
///                       categories and a link back to the resume/job
///   skill_matches     - matched / partial / missing skills per analysis
///   suggestions       - missing keywords, strengths, improvements and
///                       general suggestions per analysis (differentiated
///                       by `category`)
///   app_session       - tiny key/value table used to remember who is
///                       currently logged in across app restarts
///
/// `analysis_history` is the original table from the first version of this
/// project. It is kept (but no longer written to) so upgrading the app on
/// a device that already has data never deletes anything.
class DatabaseService {
  static Database? _database;
  static int? _cachedCurrentUserId;

  static const int _schemaVersion = 2;
  static const String _sessionKeyCurrentUser = 'current_user_id';

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    if (kIsWeb) {
      return await databaseFactoryFfiWeb.openDatabase(
        'resume_analyzer.db',
        options: OpenDatabaseOptions(
          version: _schemaVersion,
          onCreate: (db, version) async => _createAllTables(db),
          onUpgrade: (db, oldVersion, newVersion) async =>
              _createAllTables(db),
        ),
      );
    }

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'resume_analyzer.db');

    return await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: (db, version) async => _createAllTables(db),
      onUpgrade: (db, oldVersion, newVersion) async => _createAllTables(db),
    );
  }

  /// Creates every table with `IF NOT EXISTS` so this is safe to call both
  /// for a brand-new database (onCreate) and when upgrading an existing one
  /// (onUpgrade) without ever dropping existing data.
  static Future<void> _createAllTables(Database db) async {
    // Legacy table from the original project version - preserved as-is.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS analysis_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        resume_file_name TEXT NOT NULL,
        job_title TEXT NOT NULL,
        score REAL NOT NULL,
        analysis_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS resumes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        file_name TEXT NOT NULL,
        extracted_text TEXT NOT NULL,
        upload_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS job_descriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        created_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS analyses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        resume_id INTEGER NOT NULL,
        job_description_id INTEGER NOT NULL,
        resume_file_name TEXT NOT NULL,
        job_title TEXT NOT NULL,
        overall_score REAL NOT NULL,
        skill_score REAL NOT NULL,
        keyword_score REAL NOT NULL,
        similarity_score REAL NOT NULL,
        experience_score REAL NOT NULL,
        completeness_score REAL NOT NULL,
        structure_score REAL NOT NULL,
        analysis_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS skill_matches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        analysis_id INTEGER NOT NULL,
        skill TEXT NOT NULL,
        match_type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS suggestions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        analysis_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        suggestion_text TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_session (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // ------------------------------------------------------------
  // AUTH / USERS
  // ------------------------------------------------------------

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await database;
    final normalizedEmail = email.trim().toLowerCase();

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
    );

    if (existing.isNotEmpty) {
      throw Exception('An account with this email already exists.');
    }

    final id = await db.insert('users', {
      'name': name.trim(),
      'email': normalizedEmail,
      'password_hash': PasswordUtils.hash(password),
      'created_at': DateTime.now().toIso8601String(),
    });

    await _setSession(id);

    return {'id': id, 'name': name.trim(), 'email': normalizedEmail};
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final normalizedEmail = email.trim().toLowerCase();

    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
    );

    if (rows.isEmpty) {
      throw Exception('No account found with this email.');
    }

    final user = rows.first;
    final storedHash = user['password_hash'] as String;

    if (!PasswordUtils.matches(password, storedHash)) {
      throw Exception('Incorrect password. Please try again.');
    }

    await _setSession(user['id'] as int);

    return user;
  }

  static Future<void> logout() async {
    final db = await database;
    await db.delete(
      'app_session',
      where: 'key = ?',
      whereArgs: [_sessionKeyCurrentUser],
    );
    _cachedCurrentUserId = null;
  }

  static Future<void> _setSession(int userId) async {
    final db = await database;

    await db.insert('app_session', {
      'key': _sessionKeyCurrentUser,
      'value': '$userId',
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    _cachedCurrentUserId = userId;
  }

  static Future<int?> getCurrentUserId() async {
    if (_cachedCurrentUserId != null) {
      return _cachedCurrentUserId;
    }

    final db = await database;

    final rows = await db.query(
      'app_session',
      where: 'key = ?',
      whereArgs: [_sessionKeyCurrentUser],
    );

    if (rows.isEmpty) {
      return null;
    }

    final storedValue = rows.first['value'] as String?;
    final id = storedValue == null ? null : int.tryParse(storedValue);

    _cachedCurrentUserId = id;
    return id;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final id = await getCurrentUserId();

    if (id == null) {
      return null;
    }

    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  static Future<void> updateProfileName({
    required int userId,
    required String name,
  }) async {
    final db = await database;

    await db.update(
      'users',
      {'name': name.trim()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ------------------------------------------------------------
  // RESUME
  // ------------------------------------------------------------

  static Future<int> saveResume({
    required int userId,
    required String fileName,
    required String extractedText,
  }) async {
    final db = await database;

    return db.insert('resumes', {
      'user_id': userId,
      'file_name': fileName,
      'extracted_text': extractedText,
      'upload_date': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>?> getLatestResume(int userId) async {
    final db = await database;

    final rows = await db.query(
      'resumes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  // ------------------------------------------------------------
  // JOB DESCRIPTION
  // ------------------------------------------------------------

  static Future<int> saveJobDescription({
    required int userId,
    required String title,
    required String description,
  }) async {
    final db = await database;

    return db.insert('job_descriptions', {
      'user_id': userId,
      'title': title,
      'description': description,
      'created_date': DateTime.now().toIso8601String(),
    });
  }

  // ------------------------------------------------------------
  // ANALYSIS (full, explainable result)
  // ------------------------------------------------------------

  static Future<int> saveFullAnalysis({
    required int userId,
    required int resumeId,
    required int jobDescriptionId,
    required String resumeFileName,
    required String jobTitle,
    required AnalysisResult result,
  }) async {
    final db = await database;
    final analysisDate = DateTime.now().toIso8601String();

    return db.transaction<int>((txn) async {
      final analysisId = await txn.insert('analyses', {
        'user_id': userId,
        'resume_id': resumeId,
        'job_description_id': jobDescriptionId,
        'resume_file_name': resumeFileName,
        'job_title': jobTitle,
        'overall_score': result.overallScore,
        'skill_score': result.skillScore,
        'keyword_score': result.keywordScore,
        'similarity_score': result.similarityScore,
        'experience_score': result.experienceScore,
        'completeness_score': result.completenessScore,
        'structure_score': result.structureScore,
        'analysis_date': analysisDate,
      });

      Future<void> insertSkills(List<String> skills, String matchType) async {
        for (final skill in skills) {
          await txn.insert('skill_matches', {
            'analysis_id': analysisId,
            'skill': skill,
            'match_type': matchType,
          });
        }
      }

      await insertSkills(result.matchedSkills, 'matched');
      await insertSkills(result.partialSkills, 'partial');
      await insertSkills(result.missingSkills, 'missing');

      Future<void> insertSuggestions(
        List<String> items,
        String category,
      ) async {
        for (final text in items) {
          await txn.insert('suggestions', {
            'analysis_id': analysisId,
            'category': category,
            'suggestion_text': text,
          });
        }
      }

      await insertSuggestions(result.missingKeywords, 'MissingKeyword');
      await insertSuggestions(result.strengths, 'Strength');
      await insertSuggestions(result.improvements, 'Improvement');
      await insertSuggestions(result.suggestions, 'Suggestion');

      return analysisId;
    });
  }

  static Future<List<Map<String, dynamic>>> getAnalysisHistoryForUser(
    int userId,
  ) async {
    final db = await database;

    return db.query(
      'analyses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> getRecentAnalyses(
    int userId, {
    int limit = 3,
  }) async {
    final db = await database;

    return db.query(
      'analyses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
      limit: limit,
    );
  }

  static Future<AnalysisResult?> getAnalysisResultById(int analysisId) async {
    final db = await database;

    final rows = await db.query(
      'analyses',
      where: 'id = ?',
      whereArgs: [analysisId],
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;

    final skillRows = await db.query(
      'skill_matches',
      where: 'analysis_id = ?',
      whereArgs: [analysisId],
    );

    final matched = <String>[];
    final partial = <String>[];
    final missing = <String>[];

    for (final skillRow in skillRows) {
      final type = skillRow['match_type'] as String;
      final skill = skillRow['skill'] as String;

      if (type == 'matched') {
        matched.add(skill);
      } else if (type == 'partial') {
        partial.add(skill);
      } else {
        missing.add(skill);
      }
    }

    final suggestionRows = await db.query(
      'suggestions',
      where: 'analysis_id = ?',
      whereArgs: [analysisId],
    );

    final missingKeywords = <String>[];
    final strengths = <String>[];
    final improvements = <String>[];
    final suggestions = <String>[];

    for (final suggestionRow in suggestionRows) {
      final category = suggestionRow['category'] as String;
      final text = suggestionRow['suggestion_text'] as String;

      switch (category) {
        case 'MissingKeyword':
          missingKeywords.add(text);
          break;
        case 'Strength':
          strengths.add(text);
          break;
        case 'Improvement':
          improvements.add(text);
          break;
        default:
          suggestions.add(text);
      }
    }

    return AnalysisResult(
      overallScore: (row['overall_score'] as num).toDouble(),
      skillScore: (row['skill_score'] as num).toDouble(),
      keywordScore: (row['keyword_score'] as num).toDouble(),
      similarityScore: (row['similarity_score'] as num).toDouble(),
      experienceScore: (row['experience_score'] as num).toDouble(),
      completenessScore: (row['completeness_score'] as num).toDouble(),
      structureScore: (row['structure_score'] as num).toDouble(),
      matchedSkills: matched,
      missingSkills: missing,
      partialSkills: partial,
      missingKeywords: missingKeywords,
      strengths: strengths,
      improvements: improvements,
      suggestions: suggestions,
    );
  }

  /// Reconstructs everything [AnalysisResultScreen] and
  /// [ResumeOptimizerScreen] need to fully re-render a past analysis,
  /// including the original resume text and job description so the
  /// Resume Optimizer keeps working when opened from History.
  static Future<Map<String, dynamic>?> getAnalysisWithContext(
    int analysisId,
  ) async {
    final db = await database;

    final rows = await db.query(
      'analyses',
      where: 'id = ?',
      whereArgs: [analysisId],
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    final result = await getAnalysisResultById(analysisId);

    if (result == null) {
      return null;
    }

    String resumeText = '';
    final resumeRows = await db.query(
      'resumes',
      where: 'id = ?',
      whereArgs: [row['resume_id']],
    );
    if (resumeRows.isNotEmpty) {
      resumeText = resumeRows.first['extracted_text'] as String? ?? '';
    }

    String jobDescription = '';
    final jobRows = await db.query(
      'job_descriptions',
      where: 'id = ?',
      whereArgs: [row['job_description_id']],
    );
    if (jobRows.isNotEmpty) {
      jobDescription = jobRows.first['description'] as String? ?? '';
    }

    return {
      'result': result,
      'resumeFileName': row['resume_file_name'] as String,
      'jobTitle': row['job_title'] as String,
      'resumeText': resumeText,
      'jobDescription': jobDescription,
    };
  }

  // ------------------------------------------------------------
  // DASHBOARD STATS
  // ------------------------------------------------------------

  static Future<Map<String, dynamic>> getUserStats(int userId) async {
    final db = await database;

    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM analyses WHERE user_id = ?',
      [userId],
    );

    final analysesCount = Sqflite.firstIntValue(countResult) ?? 0;
    final latestResume = await getLatestResume(userId);
    final recentAnalyses = await getRecentAnalyses(userId, limit: 3);

    return {
      'analysesCount': analysesCount,
      'latestResume': latestResume,
      'recentAnalyses': recentAnalyses,
    };
  }
}
