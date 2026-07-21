class FriendSummary {
  const FriendSummary({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.relationshipStatus = 1,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final int relationshipStatus;

  factory FriendSummary.fromJson(Map<String, dynamic> json) {
    return FriendSummary(
      id: '${json['id'] ?? ''}',
      displayName: '${json['displayName'] ?? json['name'] ?? 'User'}',
      avatarUrl: json['avatarUrl']?.toString(),
      relationshipStatus: int.tryParse('${json['relationshipStatus'] ?? 1}') ?? 1,
    );
  }
}

class FriendRequestSummary {
  const FriendRequestSummary({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatarUrl,
    this.createdDate,
  });

  final String id;
  final String requesterId;
  final String requesterName;
  final String? requesterAvatarUrl;
  final DateTime? createdDate;

  factory FriendRequestSummary.fromJson(Map<String, dynamic> json) {
    return FriendRequestSummary(
      id: '${json['id'] ?? ''}',
      requesterId: '${json['requesterId'] ?? ''}',
      requesterName: '${json['requesterName'] ?? 'Friend request'}',
      requesterAvatarUrl: json['requesterAvatarUrl']?.toString(),
      createdDate: json['createdDate'] == null
          ? null
          : DateTime.tryParse('${json['createdDate']}'),
    );
  }
}

class FriendSearchResult {
  const FriendSearchResult({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.relationshipStatus = 0,
    this.mutualFriends = 0,
    this.sharedGroups = 0,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final int relationshipStatus;
  final int mutualFriends;
  final int sharedGroups;

  factory FriendSearchResult.fromJson(Map<String, dynamic> json) {
    return FriendSearchResult(
      id: '${json['id'] ?? ''}',
      displayName: '${json['displayName'] ?? json['name'] ?? 'User'}',
      avatarUrl: json['avatarUrl']?.toString(),
      relationshipStatus: int.tryParse('${json['relationshipStatus'] ?? 0}') ?? 0,
      mutualFriends: int.tryParse('${json['mutualFriends'] ?? 0}') ?? 0,
      sharedGroups: int.tryParse('${json['sharedGroups'] ?? 0}') ?? 0,
    );
  }
}

class FriendProfileArgs {
  const FriendProfileArgs({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.subtitle,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? subtitle;
}
