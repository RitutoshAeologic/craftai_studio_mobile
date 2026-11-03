import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'i_supabase_service.dart';

/// Supabase bootstrap and client service implementing [ISupabaseService].
///
/// Credentials are injected at build time via --dart-define:
///   flutter run --dart-define-from-file=dart_defines/dev.json
///
/// Follows DIP & Clean Architecture:
/// - Provides a singleton instance implementing [ISupabaseService].
/// - Allows injecting mock instances via [setMockInstance] for unit testing.
/// - Preserves static [client] getter for full backward compatibility.
class SupabaseService implements ISupabaseService {
  SupabaseService._internal();

  static final SupabaseService _defaultInstance = SupabaseService._internal();
  static ISupabaseService _instance = _defaultInstance;

  /// Global singleton accessor implementing [ISupabaseService]
  static ISupabaseService get instance => _instance;

  /// Injects a custom or mock [ISupabaseService] for testing
  static void setMockInstance(ISupabaseService? mock) {
    _instance = mock ?? _defaultInstance;
  }

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
      anonKey: _anonKey,
      debug: kDebugMode,
    );
    debugPrint('✅ Supabase initialized → $_url');
  }

  /// Backward-compatible static client getter
  static SupabaseClient get client => instance.supabaseClient;

  @override
  bool get isInitialized {
    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  @override
  SupabaseClient get supabaseClient => Supabase.instance.client;

  @override
  User? get currentUser {
    if (!isInitialized) return null;
    try {
      return supabaseClient.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Session? get currentSession {
    if (!isInitialized) return null;
    try {
      return supabaseClient.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  @override
  SupabaseQueryBuilder from(String table) => supabaseClient.from(table);

  @override
  PostgrestFilterBuilder rpc(String fn, {Map<String, dynamic>? params}) =>
      supabaseClient.rpc(fn, params: params);

  @override
  SupabaseStorageClient get storage => supabaseClient.storage;

  @override
  GoTrueClient get auth => supabaseClient.auth;
}
