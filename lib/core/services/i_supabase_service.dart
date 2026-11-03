import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract contract for Supabase operations in CraftAI Studio Mobile.
///
/// Adheres to Clean Architecture & Dependency Inversion Principle (DIP):
/// Repositories and DataSources depend on this interface rather than
/// accessing global static singletons directly.
abstract class ISupabaseService {
  /// Whether Supabase has been initialized successfully
  bool get isInitialized;

  /// The underlying [SupabaseClient] instance
  SupabaseClient get supabaseClient;

  /// The active authenticated user, or null if unauthenticated or uninitialized
  User? get currentUser;

  /// The active authentication session, or null if unauthenticated or uninitialized
  Session? get currentSession;

  /// Queries a specific database table
  SupabaseQueryBuilder from(String table);

  /// Executes a Supabase Remote Procedure Call (RPC)
  PostgrestFilterBuilder rpc(String fn, {Map<String, dynamic>? params});

  /// Accesses Supabase cloud storage buckets
  SupabaseStorageClient get storage;

  /// Accesses Supabase GoTrue authentication
  GoTrueClient get auth;
}
