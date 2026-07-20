class UserPortfolio {
  const UserPortfolio({
    required this.userId,
    this.title = '',
    this.bio = '',
    this.skills = '',
    this.githubUrl,
    this.websiteUrl,
    this.location,
    this.featuredProjectName,
    this.featuredProjectUrl,
  });

  factory UserPortfolio.fromJson(Map<String, dynamic> json) => UserPortfolio(
    userId: '${json['userId'] ?? ''}',
    title: '${json['title'] ?? ''}',
    bio: '${json['bio'] ?? ''}',
    skills: '${json['skills'] ?? ''}',
    githubUrl: json['githubUrl']?.toString(),
    websiteUrl: json['websiteUrl']?.toString(),
    location: json['location']?.toString(),
    featuredProjectName: json['featuredProjectName']?.toString(),
    featuredProjectUrl: json['featuredProjectUrl']?.toString(),
  );

  final String userId;
  final String title;
  final String bio;
  final String skills;
  final String? githubUrl;
  final String? websiteUrl;
  final String? location;
  final String? featuredProjectName;
  final String? featuredProjectUrl;

  bool get isEmpty =>
      title.trim().isEmpty &&
      bio.trim().isEmpty &&
      skills.trim().isEmpty &&
      featuredProjectName?.trim().isNotEmpty != true;

  List<String> get skillList => skills
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}
