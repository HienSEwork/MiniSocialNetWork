class SocialGroup {
  const SocialGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.memberCount,
    required this.createdDate,
    this.avatarUrl,
  });

  factory SocialGroup.fromJson(Map<String, dynamic> json) => SocialGroup(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? 'Nhóm chưa đặt tên'}',
    description: '${json['description'] ?? ''}',
    avatarUrl: json['avatarUrl']?.toString(),
    ownerId: '${json['ownerId'] ?? ''}',
    memberCount: _asInt(json['memberCount']),
    createdDate:
        DateTime.tryParse('${json['createdDate'] ?? ''}') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  final String id;
  final String name;
  final String description;
  final String? avatarUrl;
  final String ownerId;
  final int memberCount;
  final DateTime createdDate;

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return 'P';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;
}
