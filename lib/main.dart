import 'package:flutter/material.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'models/student.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/student/student_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const NoorEQuranApp());
}

class NoorEQuranApp extends StatelessWidget {
  const NoorEQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noor-e-Quran',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0)));
    _ctrl.forward();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final session = await AuthService.getSession();
    if (session == null) {
      _navigateTo(const LoginScreen());
      return;
    }

    final role = session['role'] as UserRole;
    final userData = session['userData'] as Map<String, dynamic>?;

    if (role == UserRole.admin && userData != null) {
      _navigateTo(AdminDashboard(adminData: userData));
    } else if (role == UserRole.student && userData != null) {
      _navigateTo(StudentDashboard(student: Student.fromJson(userData)));
    } else {
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [AppTheme.primaryDark, AppTheme.primaryMid, AppTheme.primaryDark],
          ),
        ),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ScaleTransition(scale: _scale, child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 12))]),
              child: const Icon(Icons.menu_book_rounded, size: 50, color: Colors.white))),
            const SizedBox(height: 24),
            FadeTransition(opacity: _fade, child: Text('Noor-e-Quran',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(letterSpacing: 1))),
            const SizedBox(height: 8),
            FadeTransition(opacity: _fade, child: Text('Illuminate your knowledge',
              style: TextStyle(color: AppTheme.accentGold, fontSize: 14))),
            const SizedBox(height: 40),
            FadeTransition(opacity: _fade, child: const SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.accent))),
          ]),
        ),
      ),
    );
  }
}
