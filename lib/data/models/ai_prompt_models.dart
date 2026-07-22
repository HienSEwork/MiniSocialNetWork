class AiPromptTemplate {
  const AiPromptTemplate({
    required this.id,
    required this.title,
    required this.platform,
    required this.category,
    required this.description,
    required this.template,
    this.beforeImage,
    this.afterImage,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.isBookmarked = false,
  });

  final String id;
  final String title;
  final String platform;
  final String category;
  final String description;
  final String template;
  final String? beforeImage;
  final String? afterImage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isBookmarked;

  List<String> get variables => PromptTemplateEngine.variables(template);

  factory AiPromptTemplate.fromMap(Map<String, Object?> map) =>
      AiPromptTemplate(
        id: '${map['id'] ?? ''}',
        title: '${map['title'] ?? ''}',
        platform: '${map['platform'] ?? ''}',
        category: '${map['category'] ?? ''}',
        description: '${map['description'] ?? ''}',
        template: '${map['template'] ?? ''}',
        beforeImage: map['before_image']?.toString(),
        afterImage: map['after_image']?.toString(),
        isActive: (map['is_active'] as num?)?.toInt() == 1,
        createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime(1970),
        updatedAt: DateTime.tryParse('${map['updated_at']}') ?? DateTime(1970),
        isBookmarked: (map['is_bookmarked'] as num?)?.toInt() == 1,
      );

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'platform': platform,
    'category': category,
    'description': description,
    'template': template,
    'before_image': beforeImage,
    'after_image': afterImage,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'is_bookmarked': isBookmarked ? 1 : 0,
  };

  AiPromptTemplate copyWith({
    String? id,
    String? title,
    String? platform,
    String? category,
    String? description,
    String? template,
    String? beforeImage,
    String? afterImage,
    bool clearBeforeImage = false,
    bool clearAfterImage = false,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isBookmarked,
  }) => AiPromptTemplate(
    id: id ?? this.id,
    title: title ?? this.title,
    platform: platform ?? this.platform,
    category: category ?? this.category,
    description: description ?? this.description,
    template: template ?? this.template,
    beforeImage: clearBeforeImage ? null : beforeImage ?? this.beforeImage,
    afterImage: clearAfterImage ? null : afterImage ?? this.afterImage,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isBookmarked: isBookmarked ?? this.isBookmarked,
  );

  Map<String, Object?> databaseMap() =>
      Map<String, Object?>.from(toMap())..remove('is_bookmarked');
}

class PromptBookmark {
  const PromptBookmark({
    required this.userId,
    required this.promptId,
    required this.createdAt,
  });
  final String userId;
  final String promptId;
  final DateTime createdAt;

  factory PromptBookmark.fromMap(Map<String, Object?> map) => PromptBookmark(
    userId: '${map['user_id'] ?? ''}',
    promptId: '${map['prompt_id'] ?? ''}',
    createdAt: DateTime.tryParse('${map['created_at']}') ?? DateTime(1970),
  );
  Map<String, Object?> toMap() => {
    'user_id': userId,
    'prompt_id': promptId,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
  PromptBookmark copyWith({
    String? userId,
    String? promptId,
    DateTime? createdAt,
  }) => PromptBookmark(
    userId: userId ?? this.userId,
    promptId: promptId ?? this.promptId,
    createdAt: createdAt ?? this.createdAt,
  );
}

class PromptTemplateEngine {
  PromptTemplateEngine._();
  static final RegExp _variable = RegExp(r'\{([a-zA-Z0-9_]+)\}');

  static List<String> variables(String template) => _variable
      .allMatches(template)
      .map((match) => match.group(1)!)
      .toSet()
      .toList();

  static String build(String template, Map<String, String> values) {
    var output = template;
    for (final variable in variables(template)) {
      final value = values[variable]?.trim();
      output = output.replaceAll(
        '{$variable}',
        value?.isNotEmpty == true ? value! : '[$variable]',
      );
    }
    return output;
  }
}
