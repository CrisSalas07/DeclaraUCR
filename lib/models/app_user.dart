/// Signed-in person, independent of Firebase (the UI never sees `User`).
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  final String uid;
  final String email;
  final String displayName;

  /// First name for greetings; falls back to the e-mail user part.
  String get firstName {
    final name = displayName.trim();
    if (name.isNotEmpty) return name.split(RegExp(r'\s+')).first;
    return email.split('@').first;
  }

  /// Up to two initials for the avatar.
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
