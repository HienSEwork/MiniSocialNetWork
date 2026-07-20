class SocialStory {
  const SocialStory({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdDate,
    required this.expiresAt,
    this.authorAvatarUrl,
    this.mediaUrl,
    this.mediaType = 0,
    this.updatedDate,
  });

  factory SocialStory.fromJson(Map<String, dynamic> json) => SocialStory(
    id: '${json['id'] ?? ''}',
    userId: '${json['userId'] ?? ''}',
    authorName: '${json['authorName'] ?? ''}',
    authorAvatarUrl: json['authorAvatarUrl']?.toString(),
    content: '${json['content'] ?? ''}',
    mediaUrl: json['mediaUrl']?.toString(),
    mediaType: _asInt(json['mediaType']),
    createdDate:
        DateTime.tryParse('${json['createdDate'] ?? ''}') ?? DateTime.now(),
    expiresAt:
        DateTime.tryParse('${json['expiresAt'] ?? ''}') ??
        DateTime.now().add(const Duration(hours: 24)),
    updatedDate: json['updatedDate'] == null
        ? null
        : DateTime.tryParse('${json['updatedDate']}'),
  );

  final String id;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final String? mediaUrl;
  final int mediaType;
  final DateTime createdDate;
  final DateTime expiresAt;
  final DateTime? updatedDate;

  bool get hasMedia => mediaUrl?.trim().isNotEmpty == true;
  bool get isVideo => mediaType == 2;

  String get authorLabel {
    if (authorName.trim().isNotEmpty) return authorName;
    return 'Thành viên TechNet';
  }

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;
}
