import 'package:supabase_flutter/supabase_flutter.dart';

/// Immutable, typed representation of the signed-in Supabase user.
/// Never expose the raw Supabase [User] object beyond the data layer.
class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.emailConfirmedAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? emailConfirmedAt;

  /// True when Supabase has verified this user's email address.
  bool get isEmailConfirmed => emailConfirmedAt != null;

  factory AuthUserModel.fromSupabaseUser(User user) {
    return AuthUserModel(
      id: user.id,
      email: user.email ?? '',
      displayName: user.userMetadata?['display_name'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      emailConfirmedAt: user.emailConfirmedAt != null
          ? DateTime.tryParse(user.emailConfirmedAt!)
          : null,
    );
  }
}
