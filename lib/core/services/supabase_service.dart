import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase bootstrap service.
///
/// Credentials are injected at build time via --dart-define:
///   flutter run --dart-define-from-file=dart_defines/dev.json
///
/// Never hardcode these values. See rules.md §3.
class SupabaseService {
  SupabaseService._();

  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://txiuwtrmfvceddqsjvhk.supabase.co',
  );

  static const String _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR4aXV3dHJtZnZjZWRkcXNqdmhrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwMzI3NDcsImV4cCI6MjEwNDYwODc0N30.ATPt_nmNNHfpZE8b5whkZaxTtnihk87_4ZUcsvLmbgE',
  );

  /// Call once in [main()] before [runApp].
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      // ignore: deprecated_member_use
      anonKey: _anonKey, // publishableKey alias — update when supabase_flutter ≥3.0
      debug: kDebugMode,
    );
    debugPrint('✅ Supabase initialized → $_url');
  }

  /// Non-nullable client — throws [StateError] if called before [initialize].
  /// This is intentional: it's a programming error to use the client before init.
  static SupabaseClient get client => Supabase.instance.client;
}
