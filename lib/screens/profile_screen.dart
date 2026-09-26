import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/app_scaffold.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  bool _isSaving = false;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
      _nameController.text = user['name'] as String? ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveName() async {
    final user = _user;
    if (user == null) return;

    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await DatabaseService.updateProfileName(
        userId: user['id'] as int,
        name: newName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update your profile.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
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

    if (confirmed != true) return;

    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScaffold(
        selectedItem: 'Profile',
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4D55DF)),
        ),
      );
    }

    final user = _user!;
    final stats = _stats ?? {};
    final latestResume = stats['latestResume'] as Map<String, dynamic>?;
    final analysesCount = stats['analysesCount'] as int? ?? 0;

    return AppScaffold(
      selectedItem: 'Profile',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xFF102752),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your account information.',
              style: TextStyle(fontSize: 15, color: Color(0xFF60779D)),
            ),
            const SizedBox(height: 28),

            _card(
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EBFF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(user['name'] as String? ?? ''),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4D55DF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF102752),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['email'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF60779D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.description_outlined,
                    label: 'Resume Status',
                    value: latestResume == null
                        ? 'Not uploaded'
                        : 'Uploaded',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _statCard(
                    icon: Icons.analytics_outlined,
                    label: 'Analyses Performed',
                    value: '$analysesCount',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Name',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF102752),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF7F9FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveName,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4D55DF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Color(0xFFD34A4A)),
                label: const Text(
                  'Log Out',
                  style: TextStyle(color: Color(0xFFD34A4A)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFD34A4A)),
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE2F5)),
      ),
      child: child,
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF4D55DF)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF102752),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF60779D)),
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
