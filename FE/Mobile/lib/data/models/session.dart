class UserSession {
  const UserSession({
    required this.userId,
    required this.displayName,
    this.email,
    this.token,
    this.isGuest = false,
    this.avatarUrl,
    this.bio,
  });

  final String userId;
  final String displayName;
  final String? email;
  final String? token;
  final bool isGuest;
  final String? avatarUrl;
  final String? bio;
}
