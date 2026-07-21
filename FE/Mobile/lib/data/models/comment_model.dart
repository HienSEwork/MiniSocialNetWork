class SocialComment {
  const SocialComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdDate,
    this.authorAvatarUrl,
  });

  factory SocialComment.fromJson(Map<String, dynamic> json) => SocialComment(
    id: '${json['id'] ?? ''}',
    postId: '${json['postId'] ?? ''}',
    userId: '${json['userId'] ?? ''}',
    authorName: '${json['authorName'] ?? 'Thành viên'}',
    authorAvatarUrl: json['authorAvatarUrl']?.toString(),
    content: '${json['content'] ?? ''}',
    createdDate:
        DateTime.tryParse('${json['createdDate'] ?? ''}') ?? DateTime.now(),
  );

  final String id;
  final String postId;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdDate;
}
