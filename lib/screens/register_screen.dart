import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final validationError = AuthService.validateRegistration(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object e) {
    final message = e.toString().replaceFirst('Exception: ', '');
    return message.isEmpty
        ? 'Something went wrong. Please try again.'
        : message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDE2F5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF60779D),
                    ),
                  ),

                  const Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF102752),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Start analyzing your resume against real job roles.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF60779D)),
                  ),

                  const SizedBox(height: 26),

                  _fieldLabel('Full Name'),
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration('Jane Doe'),
                  ),

                  const SizedBox(height: 16),

                  _fieldLabel('Email'),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('you@example.com'),
                  ),

                  const SizedBox(height: 16),

                  _fieldLabel('Password'),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration('At least 6 characters').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _fieldLabel('Confirm Password'),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration('Re-enter your password'),
                    onSubmitted: (_) {
                      if (!_isLoading) _register();
                    },
                  ),

                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4D55DF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(color: Color(0xFF60779D)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            color: Color(0xFF4D55DF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF102752),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F9FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
