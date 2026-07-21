class GroupMember {
  const GroupMember({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedDate,
    this.avatarUrl,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: '${json['userId'] ?? ''}',
      displayName: '${json['displayName'] ?? 'Member'}',
      avatarUrl: json['avatarUrl']?.toString(),
      role: json['role'] is int
          ? json['role']
          : int.tryParse('${json['role']}') ?? 0,
      joinedDate: DateTime.tryParse(
        '${json['joinedDate'] ?? ''}',
      ) ??
          DateTime.now(),
    );
  }

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int role;
  final DateTime joinedDate;

  String get roleName {
    switch (role) {
      case 2:
        return "Owner";
      case 1:
        return "Admin";
      default:
        return "Member";
    }
  }
}