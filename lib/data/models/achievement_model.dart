class UserAchievement {
  const UserAchievement({
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.unlocked,
    this.unlockedAt,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) =>
      UserAchievement(
        code: '${json['code'] ?? ''}',
        name: '${json['name'] ?? ''}',
        description: '${json['description'] ?? ''}',
        icon: '${json['icon'] ?? ''}',
        unlocked: json['unlocked'] == true,
        unlockedAt: json['unlockedAt'] == null
            ? null
            : DateTime.tryParse('${json['unlockedAt']}'),
      );

  final String code;
  final String name;
  final String description;
  final String icon;
  final bool unlocked;
  final DateTime? unlockedAt;
}
