import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_copy.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/group_model.dart';
import '../../data/models/post_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/community_provider.dart';
import '../widgets/common.dart';
import '../widgets/post_card.dart';
import 'chat_screen.dart';
import 'home_screen.dart' show showCreatePostSheet;

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();
    final copy = AppCopy.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 104;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => provider.loadDashboard(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _GroupsHero(
                search: _search,
                onSearch: provider.searchGroups,
                onClear: () {
                  _search.clear();
                  provider.loadDashboard(force: true);
                  setState(() {});
                },
                onChanged: () => setState(() {}),
                onCreate: () => _showCreateGroup(context),
              ),
            ),
            if (provider.isLoading && provider.groups.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.error != null && provider.groups.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FriendlyState(
                  icon: Icons.cloud_off_rounded,
                  title: copy.groupsLoadFailed,
                  message: provider.error!,
                  actionLabel: copy.retry,
                  onAction: () => provider.loadDashboard(force: true),
                ),
              )
            else if (provider.groups.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FriendlyState(
                  icon: Icons.diversity_3_rounded,
                  title: copy.noGroupsTitle,
                  message: copy.noGroupsMessage,
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, bottomPadding),
                sliver: SliverList.separated(
                  itemCount: provider.groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => ResponsivePage(
                    child: _GroupCard(group: provider.groups[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateGroup(BuildContext context) async {
    final copy = AppCopy.of(context);
    final name = TextEditingController();
    final description = TextEditingController();
    var submitting = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            18,
            22,
            MediaQuery.viewInsetsOf(context).bottom + 22,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  copy.createGroupTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  copy.createGroupHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: name,
                  enabled: !submitting,
                  autofocus: true,
                  decoration: InputDecoration(labelText: copy.groupName),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: description,
                  enabled: !submitting,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: copy.shortDescription,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: submitting
                      ? null
                      : () async {
                          setSheetState(() => submitting = true);
                          final error = await sheetContext
                              .read<CommunityProvider>()
                              .createGroup(name.text, description.text);
                          if (!sheetContext.mounted) return;
                          if (error == null) {
                            Navigator.pop(sheetContext);
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
                      : const Icon(Icons.add_rounded),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Text(copy.createGroup),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    name.dispose();
    description.dispose();
  }
}

class _GroupsHero extends StatelessWidget {
  const _GroupsHero({
    required this.search,
    required this.onSearch,
    required this.onClear,
    required this.onChanged,
    required this.onCreate,
  });

  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;
  final VoidCallback onChanged;
  final VoidCallback onCreate;

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
      child: SafeArea(
        bottom: false,
        child: ResponsivePage(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            copy.groupsTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            copy.groupsSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.grape,
                      ),
                      onPressed: onCreate,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSearch,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: copy.searchGroupHint,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: search.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: onClear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final SocialGroup group;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: AppColors.violet.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.electric,
                      AppColors.grape.withValues(alpha: .9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  group.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.description.isEmpty
                          ? copy.newCommunityDescription
                          : group.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_outlined,
                          size: 18,
                          color: AppColors.mint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          copy.memberCount(group.memberCount),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.grape),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showEditGroupSheet(BuildContext context, SocialGroup group) async {
  final copy = AppCopy.of(context);
  final name = TextEditingController(text: group.name);
  final description = TextEditingController(text: group.description);
  var submitting = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          18,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                copy.editGroup,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 22),
              TextField(
                controller: name,
                enabled: !submitting,
                autofocus: true,
                decoration: InputDecoration(labelText: copy.groupName),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: description,
                enabled: !submitting,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: copy.shortDescription,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: submitting
                    ? null
                    : () async {
                        setSheetState(() => submitting = true);
                        final error = await sheetContext
                            .read<CommunityProvider>()
                            .updateGroup(group, name.text, description.text);
                        if (!sheetContext.mounted) return;
                        if (error == null) {
                          Navigator.pop(sheetContext);
                          showResultMessage(context, copy.groupUpdated);
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
  name.dispose();
  description.dispose();
}

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.group});
  final SocialGroup group;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Future<List<SocialPost>> _posts;

  @override
  void initState() {
    super.initState();
    _posts = context.read<CommunityProvider>().fetchGroupPosts(widget.group);
  }

  void _reload() => setState(() {
    _posts = context.read<CommunityProvider>().fetchGroupPosts(widget.group);
  });

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          if (context.watch<AuthProvider>().session?.userId ==
              widget.group.ownerId)
            IconButton(
              tooltip: copy.editGroup,
              onPressed: () async {
                await showEditGroupSheet(context, widget.group);
                if (mounted) _reload();
              },
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            tooltip: copy.chat,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ConversationScreen(group: widget.group),
              ),
            ),
            icon: const Icon(Icons.forum_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<SocialPost>>(
        future: _posts,
        builder: (context, snapshot) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _GroupHero(group: widget.group, reload: _reload),
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FriendlyState(
                  icon: Icons.cloud_off_rounded,
                  title: copy.groupPostsLoadFailed,
                  message: '${snapshot.error}',
                  actionLabel: copy.retry,
                  onAction: _reload,
                ),
              )
            else if (snapshot.data?.isEmpty ?? true)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FriendlyState(
                  icon: Icons.edit_note_rounded,
                  title: copy.noGroupPosts,
                  message: copy.firstGroupPost,
                ),
              )
            else
              SliverList.separated(
                itemCount: snapshot.data!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, index) => ResponsivePage(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: PostCard(post: snapshot.data![index]),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showCreatePostSheet(context, initialGroup: widget.group);
          if (mounted) _reload();
        },
        icon: const Icon(Icons.edit_rounded),
        label: Text(copy.writePost),
      ),
    );
  }
}

class _GroupHero extends StatelessWidget {
  const _GroupHero({required this.group, required this.reload});
  final SocialGroup group;
  final VoidCallback reload;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return ResponsivePage(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.indigo.withValues(alpha: .12),
                      child: Text(
                        group.initials,
                        style: const TextStyle(
                          color: AppColors.indigo,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        group.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  group.description.isEmpty
                      ? copy.newCommunityOnTechNet
                      : group.description,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      copy.memberCount(group.memberCount),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () async {
                        final error = await context
                            .read<CommunityProvider>()
                            .joinGroup(group);
                        if (!context.mounted) return;
                        showResultMessage(
                          context,
                          error ?? copy.joinedGroup(group.name),
                          error: error != null,
                        );
                        if (error == null) reload();
                      },
                      child: Text(copy.join),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
