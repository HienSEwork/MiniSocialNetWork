import 'group_model.dart';
import 'post_model.dart';

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.query,
    required this.userTotal,
    required this.groupTotal,
    required this.postTotal,
    required this.users,
    required this.groups,
    required this.posts,
  });

  factory GlobalSearchResult.fromJson(Map<String, dynamic> json) {
    return GlobalSearchResult(
      query: '${json['query'] ?? ''}',
      userTotal: _asInt(json['userTotal']),
      groupTotal: _asInt(json['groupTotal']),
      postTotal: _asInt(json['postTotal']),
      users: _mapList(json['users'], SearchPerson.fromJson),
      groups: _mapList(json['groups'], SocialGroup.fromJson),
      posts: _mapList(json['posts'], SocialPost.fromJson),
    );
  }

  final String query;
  final int userTotal;
  final int groupTotal;
  final int postTotal;
  final List<SearchPerson> users;
  final List<SocialGroup> groups;
  final List<SocialPost> posts;

  int get total => userTotal + groupTotal + postTotal;

  static int _asInt(dynamic value) =>
      value is int ? value : int.tryParse('$value') ?? 0;

  static List<T> _mapList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) map,
  ) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => map(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class SearchPerson {
  const SearchPerson({
    required this.id,
    required this.displayName,
    required this.createdDate,
    this.avatarUrl,
    this.bio,
  });

  factory SearchPerson.fromJson(Map<String, dynamic> json) => SearchPerson(
    id: '${json['id'] ?? ''}',
    displayName: '${json['displayName'] ?? 'Thành viên TechNet'}',
    avatarUrl: json['avatarUrl']?.toString(),
    bio: json['bio']?.toString(),
    createdDate:
        DateTime.tryParse('${json['createdDate'] ?? ''}') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdDate;
}
