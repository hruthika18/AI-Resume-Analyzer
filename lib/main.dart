import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/database_service.dart';

void main() {
  runApp(const ResumeAnalyzerApp());
}

class ResumeAnalyzerApp extends StatelessWidget {
  const ResumeAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Resume Analyzer',
      theme: ThemeData(fontFamily: 'Arial', useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

/// Decides whether to show the login screen or jump straight to the
/// dashboard, based on whether a user session was already saved locally
/// (see DatabaseService's `app_session` table).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<int?> _currentUserIdFuture;

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = DatabaseService.getCurrentUserId();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: _currentUserIdFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F9FF),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF4D55DF)),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
