// lib/models/user_profile.dart
class UserProfile {
  final String email;
  final String? picture;
  final bool emailVerified;

  UserProfile({
    required this.email,
    this.picture,
    this.emailVerified = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      email: json['email'] ?? '',
      picture: json['picture'],
      emailVerified: json['email_verified'] ?? false,
    );
  }

  UserProfile copyWith({
    String? email,
    String? picture,
    bool? emailVerified,
  }) {
    return UserProfile(
        email: email ?? this.email,
        picture: picture ?? this.picture,
        emailVerified: emailVerified ?? this.emailVerified);
  }
}
