import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://dndkyhrfwclnigmlcfqh.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRuZGt5aHJmd2NsbmlnbWxjZnFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5NDEzMjMsImV4cCI6MjA3NjUxNzMyM30.g-aRIGRzLECpYwvx-qV9TNO6ikAbTb0b6jSK-aMt5D8';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
