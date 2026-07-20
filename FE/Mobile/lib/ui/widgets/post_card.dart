import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_copy.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/post_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/community_provider.dart';
import 'common.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.highlightQuery,
    this.onChanged,
  });

  final SocialPost post;
  final String? highlightQuery;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final copy = AppCopy.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  label: post.authorLabel,
                  imageUrl: post.authorAvatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${post.groupName ?? copy.communityFallback}  •  ${_relativeTime(context, post.createdDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showPostOptions(context),
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
            if (post.content.isNotEmpty) ...[
              const SizedBox(height: 16),
              _PostContent(
                content: post.content,
                highlightQuery: highlightQuery,
              ),
            ],
            if (post.mediaUrl?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    post.mediaUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.indigo.withValues(alpha: .08),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.indigo,
                          ),
                          const SizedBox(height: 8),
                          Text(copy.mediaLoadFailed),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                _ReactionSummary(post: post),
                const SizedBox(width: 16),
                _Metric(
                  icon: Icons.chat_bubble_rounded,
                  color: AppColors.indigo,
                  value: post.commentCount,
                ),
                const Spacer(),
                Text(
                  post.reactionCount + post.commentCount == 0
                      ? copy.startConversation
                      : copy.gettingAttention,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: _Action(
                    icon: _reactionIcon(post.currentUserReaction),
                    label: copy.react,
                    onTap: () => _showReactions(context),
                  ),
                ),
                Expanded(
                  child: _Action(
                    icon: Icons.mode_comment_outlined,
                    label: copy.comment,
                    onTap: () => _showComments(context),
                  ),
                ),
                _Action(
                  icon: Icons.ios_share_rounded,
                  label: '',
                  onTap: () => showUnavailable(context, copy.share),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _reactionIcon(int? type) => switch (type) {
    2 => Icons.favorite_rounded,
    3 => Icons.sentiment_very_satisfied_rounded,
    _ => Icons.thumb_up_alt_outlined,
  };

  String _relativeTime(BuildContext context, DateTime time) {
    final copy = AppCopy.of(context);
    final difference = DateTime.now().difference(time.toLocal());
    if (difference.inMinutes < 1) return copy.justNow;
    if (difference.inHours < 1) return copy.minutesAgo(difference.inMinutes);
    if (difference.inDays < 1) return copy.hoursAgo(difference.inHours);
    if (difference.inDays < 7) return copy.daysAgo(difference.inDays);
    return '${time.day}/${time.month}/${time.year}';
  }

  Future<void> _showReactions(BuildContext context) async {
    final copy = AppCopy.of(context);
    final reactions = [
      (1, copy.like, '👍'),
      (2, copy.love, '❤️'),
      (3, 'Haha', '😄'),
    ];
    final type = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Row(
            children: reactions
                .map(
                  (reaction) => Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.pop(context, reaction.$1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reaction.$3,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              reaction.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (type == null || !context.mounted) return;
    final error = await context.read<CommunityProvider>().toggleReaction(
      post.id,
      type,
    );
    if (context.mounted && error != null) {
      showResultMessage(context, error, error: true);
    }
  }

  Future<void> _showPostOptions(BuildContext context) async {
    final copy = AppCopy.of(context);
    final userId = context.read<AuthProvider>().session?.userId;
    final canEdit = userId != null && userId == post.userId;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              enabled: canEdit,
              leading: const Icon(Icons.edit_outlined),
              title: Text(copy.editPost),
              onTap: canEdit ? () => Navigator.pop(context, 'edit') : null,
            ),
            ListTile(
              enabled: canEdit,
              leading: const Icon(Icons.delete_outline_rounded),
              title: Text(copy.isEnglish ? 'Delete post' : 'Xóa bài viết'),
              textColor: Theme.of(context).colorScheme.error,
              iconColor: Theme.of(context).colorScheme.error,
              onTap: canEdit ? () => Navigator.pop(context, 'delete') : null,
            ),
          ],
        ),
      ),
    );
    if (action == 'edit' && context.mounted) {
      await _showEditPostSheet(context);
    }
    if (action == 'delete' && context.mounted) {
      await _deletePost(context);
    }
  }

  Future<void> _deletePost(BuildContext context) async {
    final copy = AppCopy.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(copy.isEnglish ? 'Delete this post?' : 'Xóa bài viết này?'),
        content: Text(
          copy.isEnglish
              ? 'This action cannot be undone.'
              : 'Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(copy.isEnglish ? 'Cancel' : 'Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(copy.isEnglish ? 'Delete' : 'Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await context.read<CommunityProvider>().deletePost(post);
    if (!context.mounted) return;
    if (error == null) {
      onChanged?.call();
      showResultMessage(
        context,
        copy.isEnglish ? 'Post deleted.' : 'Đã xóa bài viết.',
      );
    } else {
      showResultMessage(context, error, error: true);
    }
  }

  Future<void> _showEditPostSheet(BuildContext context) async {
    final provider = context.read<CommunityProvider>();
    final copy = AppCopy.of(context);
    final content = TextEditingController(text: post.content);
    final media = TextEditingController(text: post.mediaUrl ?? '');
    String? mediaUrl = post.mediaUrl;
    var mediaType = post.mediaType;
    String? mediaName;
    var submitting = false;
    var uploading = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            12,
            18,
            MediaQuery.viewInsetsOf(context).bottom + 18,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  copy.editPost,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: content,
                  enabled: !submitting,
                  minLines: 4,
                  maxLines: 8,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: copy.postContent,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: submitting || uploading
                      ? null
                      : () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 88,
                          );
                          if (picked == null) return;
                          setSheetState(() => uploading = true);
                          try {
                            final uploaded = await provider.uploadMedia(
                              fileName: picked.name,
                              filePath: picked.path,
                              bytes: await picked.readAsBytes(),
                            );
                            if (!sheetContext.mounted) return;
                            setSheetState(() {
                              mediaUrl = uploaded.url;
                              mediaType = uploaded.mediaType;
                              mediaName = picked.name;
                              media.text = uploaded.url;
                              uploading = false;
                            });
                          } catch (error) {
                            if (!sheetContext.mounted) return;
                            setSheetState(() => uploading = false);
                            showResultMessage(
                              sheetContext,
                              '$error',
                              error: true,
                            );
                          }
                        },
                  icon: uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(mediaName ?? copy.chooseImage),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: media,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: copy.uploadedMedia,
                    prefixIcon: const Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: submitting
                      ? null
                      : () async {
                          setSheetState(() => submitting = true);
                          final error = await provider.updatePost(
                            post,
                            content.text,
                            mediaUrl: mediaUrl ?? media.text,
                            mediaType: mediaType,
                          );
                          if (!sheetContext.mounted) return;
                          if (error == null) {
                            Navigator.pop(sheetContext);
                            onChanged?.call();
                            showResultMessage(context, copy.postUpdated);
                          } else {
                            setSheetState(() => submitting = false);
                            showResultMessage(sheetContext, error, error: true);
                          }
                        },
                  icon: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Text(copy.saveChanges),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showComments(BuildContext context) async {
    final provider = context.read<CommunityProvider>();
    final copy = AppCopy.of(context);
    var inputText = '';
    var inputRevision = 0;
    var submitting = false;
    var commentsFuture = provider.getComments(post.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .72,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Text(
                        copy.comments,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Text(
                        '${post.commentCount}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<SocialComment>>(
                    future: commentsFuture,
                    builder: (_, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return FriendlyState(
                          icon: Icons.cloud_off_rounded,
                          title: copy.commentsLoadFailed,
                          message: '${snapshot.error}',
                        );
                      }
                      final items = snapshot.data ?? const [];
                      if (items.isEmpty) {
                        return FriendlyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: copy.noComments,
                          message: copy.firstComment,
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: items.length,
                        itemBuilder: (_, index) {
                          final item = items[index];
                          return ListTile(
                            leading: UserAvatar(
                              label: item.authorName,
                              radius: 18,
                            ),
                            title: Text(
                              item.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(item.content),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: ValueKey(inputRevision),
                            enabled: !submitting,
                            onChanged: (value) {
                              setSheetState(() {
                                inputText = value;
                              });
                            },
                            minLines: 1,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: copy.writeComment,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: submitting || inputText.trim().isEmpty
                              ? null
                              : () async {
                                  setSheetState(() {
                                    submitting = true;
                                  });
                                  final error = await provider.addComment(
                                    post.id,
                                    inputText,
                                  );
                                  if (!sheetContext.mounted) return;
                                  if (error != null) {
                                    setSheetState(() {
                                      submitting = false;
                                    });
                                    showResultMessage(
                                      sheetContext,
                                      error,
                                      error: true,
                                    );
                                  } else {
                                    final nextComments = provider.getComments(
                                      post.id,
                                    );
                                    setSheetState(() {
                                      inputText = '';
                                      inputRevision++;
                                      submitting = false;
                                      commentsFuture = nextComments;
                                    });
                                  }
                                },
                          icon: submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.arrow_upward_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostContent extends StatelessWidget {
  const _PostContent({required this.content, this.highlightQuery});

  final String content;
  final String? highlightQuery;

  @override
  Widget build(BuildContext context) {
    final query = highlightQuery?.trim().toLowerCase() ?? '';
    final normalizedContent = content.toLowerCase();
    if (query.isEmpty || !normalizedContent.contains(query)) {
      return Text(content, style: Theme.of(context).textTheme.bodyLarge);
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    while (cursor < content.length) {
      final match = normalizedContent.indexOf(query, cursor);
      if (match < 0) {
        spans.add(TextSpan(text: content.substring(cursor)));
        break;
      }
      if (match > cursor) {
        spans.add(TextSpan(text: content.substring(cursor, match)));
      }
      final end = match + query.length;
      spans.add(
        TextSpan(
          text: content.substring(match, end),
          style: TextStyle(
            color: AppColors.indigo,
            fontWeight: FontWeight.w900,
            backgroundColor: AppColors.indigo.withValues(alpha: .1),
          ),
        ),
      );
      cursor = end;
    }

    return Text.rich(
      TextSpan(style: Theme.of(context).textTheme.bodyLarge, children: spans),
    );
  }
}

class _ReactionSummary extends StatelessWidget {
  const _ReactionSummary({required this.post});

  final SocialPost post;

  static const _icons = <int, String>{1: '👍', 2: '❤️', 3: '😄'};

  @override
  Widget build(BuildContext context) {
    final activeTypes =
        post.reactionCounts.entries
            .where((entry) => entry.value > 0 && _icons.containsKey(entry.key))
            .map((entry) => entry.key)
            .toList()
          ..sort();

    if (activeTypes.isEmpty) {
      return _Metric(
        icon: Icons.thumb_up_alt_outlined,
        color: AppColors.indigo,
        value: post.reactionCount,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final type in activeTypes.take(3))
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Text(_icons[type]!, style: const TextStyle(fontSize: 16)),
          ),
        const SizedBox(width: 5),
        Text(
          '${post.reactionCount}',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.color, required this.value});

  final IconData icon;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 5),
      Text('$value', style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 7),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ],
      ),
    ),
  );
}
