class SocialPost {
  const SocialPost({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdDate,
    required this.commentCount,
    required this.reactionCount,
    this.groupId,
    this.groupName,
    this.mediaUrl,
    this.mediaType = 0,
    this.authorAvatarUrl,
    this.currentUserReaction,
    this.reactionCounts = const {},
  });

  factory SocialPost.fromJson(Map<String, dynamic> json, {String? groupName}) =>
      SocialPost(
        id: '${json['id'] ?? ''}',
        groupId: json['groupId']?.toString(),
        groupName: json['groupName']?.toString() ?? groupName,
        userId: '${json['userId'] ?? ''}',
        authorName: '${json['authorName'] ?? ''}',
        authorAvatarUrl: json['authorAvatarUrl']?.toString(),
        content: '${json['content'] ?? ''}',
        mediaUrl: json['mediaUrl']?.toString(),
        mediaType: _asInt(json['mediaType']),
        createdDate:
            DateTime.tryParse('${json['createdDate'] ?? ''}') ?? DateTime.now(),
        commentCount: _asInt(json['commentCount']),
        reactionCount: _asInt(json['reactionCount']),
        currentUserReaction: json['currentUserReaction'] == null
            ? null
            : _asInt(json['currentUserReaction']),
        reactionCounts: _asCounts(json['reactionCounts']),
      );

  final String id;
  final String? groupId;
  final String? groupName;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final String? mediaUrl;
  final int mediaType;
  final DateTime createdDate;
  final int commentCount;
  final int reactionCount;
  final int? currentUserReaction;
  final Map<int, int> reactionCounts;

  String get authorLabel {
    if (authorName.isNotEmpty) return authorName;
    if (userId.isEmpty) return 'Thành viên TechNet';
    return 'Thành viên ${userId.length > 6 ? userId.substring(0, 6) : userId}';
  }

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;

  static Map<int, int> _asCounts(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, count) => MapEntry(_asInt(key), _asInt(count)));
  }
}
