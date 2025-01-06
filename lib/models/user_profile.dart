// lib/models/user_profile.dart
class UserProfile {
  final String email;
  final String? picture;
  final bool emailVerified;
  final String authProvider;

  UserProfile({
    required this.email,
    this.picture,
    this.emailVerified = false,
    required this.authProvider,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      email: json['email'] ?? '',
      picture: json['picture'],
      emailVerified: json['email_verified'] ?? false,
      authProvider: json['auth_provider'] ?? '',
    );
  }

  UserProfile copyWith({
    String? email,
    String? picture,
    bool? emailVerified,
    String? authProvider,
  }) {
    return UserProfile(
        email: email ?? this.email,
        picture: picture ?? this.picture,
        emailVerified: emailVerified ?? this.emailVerified,
        authProvider: authProvider ?? this.authProvider);
  }
}
