class ChatUser {
  const ChatUser({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.bio,
  });
  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
    id: '${json['id'] ?? ''}',
    displayName: '${json['displayName'] ?? 'Thành viên'}',
    avatarUrl: json['avatarUrl']?.toString(),
    bio: json['bio']?.toString(),
  );
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdDate,
    required this.isGroupMessage,
    this.receiverId,
    this.groupId,
  });
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: '${json['id'] ?? ''}',
    senderId: '${json['senderId'] ?? ''}',
    senderName: '${json['senderName'] ?? 'Thành viên'}',
    receiverId: json['receiverId']?.toString(),
    groupId: json['groupId']?.toString(),
    content: '${json['content'] ?? ''}',
    createdDate:
        DateTime.tryParse('${json['createdDate'] ?? ''}') ?? DateTime.now(),
    isGroupMessage: json['isGroupMessage'] == true,
  );
  final String id;
  final String senderId;
  final String senderName;
  final String? receiverId;
  final String? groupId;
  final String content;
  final DateTime createdDate;
  final bool isGroupMessage;
}
