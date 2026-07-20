import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_copy.dart';
import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/group_model.dart';
import '../../data/models/post_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/community_provider.dart';
import '../widgets/common.dart';
import '../widgets/post_card.dart';
import 'groups_screen.dart' show GroupDetailScreen;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityProvider>();
    final auth = context.watch<AuthProvider>();
    final copy = AppCopy.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 102;
    final feedPosts = [...community.posts]
      ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
    final featuredPost = feedPosts.isEmpty ? null : feedPosts.first;
    final topGroups = _rankGroups(community.groups, community.posts);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => community.loadDashboard(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHeroPanel(
                name: auth.displayName,
                connected: community.isConnected,
                post: featuredPost,
                topGroups: topGroups,
              ),
            ),
            SliverToBoxAdapter(
              child: ResponsivePage(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: _Composer(
                    displayName: auth.displayName,
                    enabled: community.joinedGroups.isNotEmpty,
                    onTap: () => showCreatePostSheet(context),
                  ),
                ),
              ),
            ),
            if (community.isLoading && !community.hasLoaded)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (community.error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FriendlyState(
                  icon: Icons.cloud_off_rounded,
                  title: copy.feedLoadFailed,
                  message: community.error!,
                  actionLabel: copy.retry,
                  onAction: () => community.loadDashboard(force: true),
                ),
              )
            else if (community.posts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FriendlyState(
                  icon: Icons.auto_awesome_rounded,
                  title: copy.feedEmptyTitle,
                  message: community.groups.isEmpty
                      ? copy.feedEmptyNoGroups
                      : copy.feedEmptyHasGroups,
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: ResponsivePage(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                    child: Row(
                      children: [
                        Text(
                          copy.topPosts,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        Text(
                          copy.postCount(community.posts.length),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverList.separated(
                itemCount: feedPosts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) => ResponsivePage(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PostCard(post: feedPosts[index]),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
          ],
        ),
      ),
    );
  }
}

class _HomeHeroPanel extends StatelessWidget {
  const _HomeHeroPanel({
    required this.name,
    required this.connected,
    required this.post,
    required this.topGroups,
  });

  final String name;
  final bool connected;
  final SocialPost? post;
  final List<_RankedGroup> topGroups;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.violet, AppColors.grape, AppColors.electric],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            top: 180,
            child: CustomPaint(painter: _WavePainter()),
          ),
          SafeArea(
            bottom: false,
            child: ResponsivePage(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .16),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.hub_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            AppConstants.appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: copy.search,
                          onPressed: () => context.push('/search'),
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _SegmentedPills(copy: copy),
                    const SizedBox(height: 18),
                    if (topGroups.isNotEmpty)
                      SizedBox(
                        height: 96,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          itemCount: topGroups.take(8).length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 22),
                          itemBuilder: (_, index) => _HeroGroupAvatar(
                            group: topGroups[index].group,
                            score: topGroups[index].score,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _TechNetBanner(connected: connected, post: post),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedPills extends StatelessWidget {
  const _SegmentedPills({required this.copy});

  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _Segment(text: copy.feed, selected: true),
          _Segment(text: copy.trendingNow),
          _Segment(text: copy.groups),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.text, this.selected = false});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? AppColors.grape : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _HeroGroupAvatar extends StatelessWidget {
  const _HeroGroupAvatar({required this.group, required this.score});

  final SocialGroup group;
  final int score;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
      ),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  label: group.name,
                  imageUrl: group.avatarUrl,
                  radius: 27,
                  accent: AppColors.violet,
                ),
                if (score > 0)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 19,
                      height: 19,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB000),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        score.clamp(1, 9).toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              group.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              copy.memberCount(group.memberCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .58),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechNetBanner extends StatelessWidget {
  const _TechNetBanner({required this.connected, required this.post});

  final bool connected;
  final SocialPost? post;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    final mediaUrl = post?.mediaUrl;
    final content = post?.content ?? copy.feedEmptyHasGroups;
    final score = post == null ? 0 : post!.reactionCount + post!.commentCount;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 188,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          border: Border.all(color: Colors.white.withValues(alpha: .18)),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: .24),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              bottom: -1,
              child: CustomPaint(painter: _CardWavePainter()),
            ),
            Positioned(
              right: -28,
              top: -36,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: connected
                                    ? const Color(0xFF7CF3D3)
                                    : Colors.white54,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                connected
                                    ? copy.trendingNow
                                    : copy.homeRefreshing,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          copy.featuredPost,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.white, height: 1.02),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFFFFD166),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              copy.engagementCount(score),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: SizedBox(
                      width: 112,
                      height: 112,
                      child: mediaUrl?.isNotEmpty == true
                          ? Image.network(
                              mediaUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white.withValues(alpha: .14),
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white,
                                  size: 42,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.white.withValues(alpha: .14),
                              child: const Icon(
                                Icons.memory_rounded,
                                color: Colors.white,
                                size: 54,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .96);
    final path = Path()
      ..moveTo(0, size.height * .76)
      ..cubicTo(
        size.width * .25,
        size.height * .69,
        size.width * .48,
        size.height * .89,
        size.width,
        size.height * .73,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .94);
    final path = Path()
      ..moveTo(0, size.height * .78)
      ..cubicTo(
        size.width * .26,
        size.height * .69,
        size.width * .46,
        size.height * .9,
        size.width,
        size.height * .73,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RankedGroup {
  const _RankedGroup(this.group, this.score);
  final SocialGroup group;
  final int score;
}

List<_RankedGroup> _rankGroups(
  List<SocialGroup> groups,
  List<SocialPost> posts,
) {
  final scores = <String, int>{};
  for (final post in posts) {
    final groupId = post.groupId;
    if (groupId == null) continue;
    scores[groupId] =
        (scores[groupId] ?? 0) + post.reactionCount + post.commentCount;
  }
  final ranked =
      groups.map((group) => _RankedGroup(group, scores[group.id] ?? 0)).toList()
        ..sort((a, b) {
          final byScore = b.score.compareTo(a.score);
          return byScore == 0
              ? b.group.memberCount.compareTo(a.group.memberCount)
              : byScore;
        });
  return ranked.take(12).toList();
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.displayName,
    required this.enabled,
    required this.onTap,
  });

  final String displayName;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Card(
      elevation: 12,
      shadowColor: AppColors.violet.withValues(alpha: .08),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              UserAvatar(label: displayName),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  enabled ? copy.composerEnabled : copy.composerDisabled,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.indigo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showCreatePostSheet(
  BuildContext context, {
  SocialGroup? initialGroup,
}) async {
  final pageContext = context;
  final provider = context.read<CommunityProvider>();
  final copy = AppCopy.of(context);
  final joinedGroups = await provider.fetchJoinedGroups();
  if (!context.mounted) return;
  if (joinedGroups.isEmpty) {
    showResultMessage(
      context,
      copy.isEnglish
          ? 'Join a group before posting.'
          : 'Hãy tham gia một nhóm trước khi đăng bài.',
      error: true,
    );
    return;
  }
  SocialGroup? selectedGroup;
  for (final item in joinedGroups) {
    if (item.id == initialGroup?.id) {
      selectedGroup = item;
      break;
    }
  }
  var group = selectedGroup ?? joinedGroups.first;
  final content = TextEditingController();
  final media = TextEditingController();
  String? mediaUrl;
  var mediaType = 0;
  String? mediaName;
  var submitting = false;
  var uploading = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (sheetContext) => DisposeScope(
      controllers: [content, media],
      child: StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            12,
            22,
            MediaQuery.viewInsetsOf(context).bottom + 22,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  copy.shareWithCommunity,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  copy.shareWithCommunityHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                DropdownButtonFormField<SocialGroup>(
                  initialValue: group,
                  decoration: InputDecoration(labelText: copy.postInGroup),
                  items: joinedGroups
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: submitting
                      ? null
                      : (value) => value == null
                            ? null
                            : setSheetState(() => group = value),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: content,
                  enabled: !submitting,
                  minLines: 4,
                  maxLines: 8,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: copy.writeThought,
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
                if (mediaName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    mediaName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: media,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: copy.imagePathOptional,
                    prefixIcon: const Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: submitting
                      ? null
                      : () async {
                          setSheetState(() => submitting = true);
                          final error = await provider.createPost(
                            group,
                            content.text,
                            mediaUrl: mediaUrl ?? media.text,
                            mediaType: mediaType,
                          );
                          if (!sheetContext.mounted) return;
                          if (error == null) {
                            Navigator.pop(sheetContext);
                            if (pageContext.mounted) {
                              showResultMessage(
                                pageContext,
                                copy.postedTo(group.name),
                              );
                            }
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
                      : const Icon(Icons.arrow_upward_rounded),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Text(copy.publishPost),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
