import 'package:flutter/material.dart';
import 'dart:ui';
import '../config/theme.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard.dart';
import 'student/student_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool isAdmin = false;
  bool isLoading = false;
  String? error;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() { isLoading = true; error = null; });

    try {
      if (isAdmin) {
        final result = await AuthService.adminLogin(
          _emailController.text,
          _passwordController.text,
        );
        if (result != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminDashboard(adminData: result)),
          );
        } else {
          setState(() => error = 'Invalid email or password');
        }
      } else {
        final student = await AuthService.studentLogin(_phoneController.text);
        if (student != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentDashboard(student: student)),
          );
        } else {
          setState(() => error = 'Phone number not found or payment pending');
        }
      }
    } catch (e) {
      setState(() => error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryDark,
              AppTheme.primaryMid,
              AppTheme.primaryDark.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Logo
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          height: 80,
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Image.asset('assets/images/zyra_logo.png', fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Noor-e-Quran',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          'Illuminate your knowledge',
                          style: TextStyle(color: AppTheme.accentGold, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 40),

                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.surfaceLight.withValues(alpha: 0.5)),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Role Toggle
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surface.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.surfaceLight.withValues(alpha: 0.3)),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: Row(
                                children: [
                                  _roleTab('Student', !isAdmin, () => setState(() { isAdmin = false; error = null; })),
                                  _roleTab('Admin', isAdmin, () => setState(() { isAdmin = true; error = null; })),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Fields
                            if (isAdmin) ...[
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.accentGold),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.accentGold),
                                ),
                              ),
                            ] else ...[
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  hintText: 'Enter your registered number',
                                  prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.accentGold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Login with your registered phone number',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ),
                            ],

                            if (error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(error!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                                ]),
                              ),
                            ],

                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primaryDark))
                                    : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      const Text('© 2026 Zyra Edutech', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleTab(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.accentGold : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(label, style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive ? AppTheme.primaryDark : AppTheme.textSecondary,
              )),
            ),
          ),
        ),
      ),
    );
  }
}
