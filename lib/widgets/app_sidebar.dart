import 'package:flutter/material.dart';

import '../screens/dashboard_screen.dart';
import '../screens/history_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/resume_analysis_screen.dart';
import '../services/auth_service.dart';

class AppSidebar extends StatelessWidget {
  final String selectedItem;

  const AppSidebar({super.key, required this.selectedItem});

  void _openPage(BuildContext context, String item) {
    // Close the drawer first if we're on a narrow screen where the
    // sidebar is shown inside a Drawer.
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.pop(context);
    }

    if (item == 'Logout') {
      _confirmLogout(context);
      return;
    }

    if (item == selectedItem) {
      return;
    }

    if (item == 'Dashboard') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }

    if (item == 'Resume Analysis') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResumeAnalysisScreen()),
      );
    }

    if (item == 'Analysis History') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HistoryScreen()),
      );
    }

    if (item == 'Profile') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }

    if (item == 'Resume Optimizer') {
      // There's no standalone Optimizer screen to jump to until a resume
      // has been analyzed (it needs an AnalysisResult to work with), so
      // send the user to Resume Analysis to run one first.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ResumeAnalysisScreen()),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text('You will need to log in again to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D55DF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await AuthService.logout();
    } catch (_) {
      // Even if clearing the session record fails, still send the user
      // back to the login screen rather than leaving them stuck.
    }

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF102752),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Logo
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF4D55DF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 26,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'AI Resume Analyzer',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 35),

            // Navigation
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _navItem(
                      context,
                      icon: Icons.dashboard_outlined,
                      title: 'Dashboard',
                    ),

                    _navItem(
                      context,
                      icon: Icons.analytics_outlined,
                      title: 'Resume Analysis',
                    ),

                    _navItem(
                      context,
                      icon: Icons.history,
                      title: 'Analysis History',
                    ),

                    _navItem(
                      context,
                      icon: Icons.auto_fix_high_outlined,
                      title: 'Resume Optimizer',
                    ),

                    _navItem(
                      context,
                      icon: Icons.person_outline,
                      title: 'Profile',
                    ),

                    const Divider(color: Color(0x33FFFFFF), height: 28),

                    _navItem(context, icon: Icons.logout, title: 'Logout'),
                  ],
                ),
              ),
            ),

            // Bottom information
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Resume Analyzer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Analyze. Improve. Grow.',
                      style: TextStyle(color: Color(0xFFB9C5DF), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    final bool isSelected = selectedItem == title;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: InkWell(
        onTap: () {
          _openPage(context, title);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4D55DF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: isSelected ? Colors.white : const Color(0xFFB9C5DF),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFB9C5DF),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
