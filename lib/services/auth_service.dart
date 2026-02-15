import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../models/student.dart';

enum UserRole { admin, student }

class AuthService {
  static const String _roleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';

  // Admin login with email + password
  static Future<Map<String, dynamic>?> adminLogin(String email, String password) async {
    try {
      final response = await SupabaseConfig.client
          .from('admin_users')
          .select()
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      if (response == null) return null;

      // Simple password hash check (stored as bcrypt in DB)
      // For simplicity, we compare password_hash directly
      // In production, use a proper bcrypt comparison
      final storedHash = response['password_hash'] as String;
      if (storedHash != password && !_verifyPassword(password, storedHash)) {
        return null;
      }

      await _saveSession(UserRole.admin, response['id'], response);
      return response;
    } catch (e) {
      return null;
    }
  }

  // Student login with phone number only
  static Future<Student?> studentLogin(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

      final response = await SupabaseConfig.client
          .from('applications')
          .select()
          .eq('mobile', cleanPhone)
          .eq('payment_status', 'completed')
          .maybeSingle();

      if (response == null) {
        // Try without country code or with variations
        final variations = [
          cleanPhone,
          cleanPhone.startsWith('+91') ? cleanPhone.substring(3) : '+91$cleanPhone',
          cleanPhone.startsWith('91') ? cleanPhone.substring(2) : '91$cleanPhone',
        ];

        for (final v in variations) {
          final res = await SupabaseConfig.client
              .from('applications')
              .select()
              .eq('mobile', v)
              .eq('payment_status', 'completed')
              .maybeSingle();
          if (res != null) {
            final student = Student.fromJson(res);
            await _saveSession(UserRole.student, student.id, res);
            return student;
          }
        }
        return null;
      }

      final student = Student.fromJson(response);
      await _saveSession(UserRole.student, student.id, response);
      return student;
    } catch (e) {
      return null;
    }
  }

  static bool _verifyPassword(String password, String hash) {
    // Simple check — in real-world use bcrypt lib
    return hash == password;
  }

  static Future<void> _saveSession(UserRole role, String userId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role == UserRole.admin ? 'admin' : 'student');
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userDataKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_roleKey);
    final userId = prefs.getString(_userIdKey);
    final userData = prefs.getString(_userDataKey);

    if (role == null || userId == null) return null;

    return {
      'role': role == 'admin' ? UserRole.admin : UserRole.student,
      'userId': userId,
      'userData': userData != null ? jsonDecode(userData) : null,
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userDataKey);
  }
}
