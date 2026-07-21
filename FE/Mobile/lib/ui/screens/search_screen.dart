import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_copy.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/group_model.dart';
import '../../data/models/search_models.dart';
import '../../data/providers/search_provider.dart';
import '../widgets/common.dart';
import '../widgets/post_card.dart';

enum _SearchFilter { all, people, groups, posts }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  _SearchFilter _filter = _SearchFilter.all;
  String _typedQuery = '';

  @override
  void initState() {
    super.initState();
    _typedQuery = context.read<SearchProvider>().query;
    _searchController = TextEditingController(text: _typedQuery);
    if (_typedQuery.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _typedQuery = value);
    _debounce?.cancel();
    if (value.trim().length < 2) {
      context.read<SearchProvider>().search(value);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => context.read<SearchProvider>().search(value),
    );
  }

  void _submit(String value) {
    _debounce?.cancel();
    context.read<SearchProvider>().search(value);
    _searchFocus.unfocus();
  }

  void _clear() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _typedQuery = '';
      _filter = _SearchFilter.all;
    });
    context.read<SearchProvider>().clear();
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final result = search.result;
    final copy = AppCopy.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 700 ? 36.0 : 18.0;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        14,
                        horizontal,
                        8,
                      ),
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            tooltip: copy.back,
                            onPressed: context.pop,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocus,
                              textInputAction: TextInputAction.search,
                              onChanged: _onQueryChanged,
                              onSubmitted: _submit,
                              decoration: InputDecoration(
                                hintText: copy.searchHint,
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: _typedQuery.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: copy.clearSearch,
                                        onPressed: _clear,
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: search.isLoading
                          ? const LinearProgressIndicator(
                              key: ValueKey('search-progress'),
                              minHeight: 2,
                            )
                          : const SizedBox(
                              key: ValueKey('search-idle'),
                              height: 2,
                            ),
                    ),
                    if (search.hasQuery)
                      _FilterBar(
                        selected: _filter,
                        result: result,
                        onSelected: (value) => setState(() => _filter = value),
                      ),
                    Expanded(
                      child: _SearchBody(
                        typedQuery: _typedQuery,
                        provider: search,
                        filter: _filter,
                        onRetry: () => _submit(_typedQuery),
                        onPersonTap: _showPerson,
                        onGroupTap: _showGroup,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showPerson(SearchPerson person) {
    final copy = AppCopy.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              label: person.displayName,
              radius: 38,
              accent: AppColors.coral,
            ),
            const SizedBox(height: 14),
            Text(
              person.displayName,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              person.bio?.trim().isNotEmpty == true
                  ? person.bio!
                  : copy.personDefaultBio,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showGroup(SocialGroup group) {
    final copy = AppCopy.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  label: group.name,
                  imageUrl: group.avatarUrl,
                  radius: 30,
                  accent: AppColors.mint,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(copy.memberCount(group.memberCount)),
                    ],
                  ),
                ),
              ],
            ),
            if (group.description.trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                group.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.result,
    required this.onSelected,
  });

  final _SearchFilter selected;
  final GlobalSearchResult? result;
  final ValueChanged<_SearchFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        children: _SearchFilter.values.map((filter) {
          final count = switch (filter) {
            _SearchFilter.all => result?.total,
            _SearchFilter.people => result?.userTotal,
            _SearchFilter.groups => result?.groupTotal,
            _SearchFilter.posts => result?.postTotal,
          };
          final label = switch (filter) {
            _SearchFilter.all => copy.all,
            _SearchFilter.people => copy.people,
            _SearchFilter.groups => copy.groups,
            _SearchFilter.posts => copy.posts,
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected == filter,
              onSelected: (_) => onSelected(filter),
              label: Text(count == null ? label : '$label  $count'),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.typedQuery,
    required this.provider,
    required this.filter,
    required this.onRetry,
    required this.onPersonTap,
    required this.onGroupTap,
  });

  final String typedQuery;
  final SearchProvider provider;
  final _SearchFilter filter;
  final VoidCallback onRetry;
  final ValueChanged<SearchPerson> onPersonTap;
  final ValueChanged<SocialGroup> onGroupTap;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    if (typedQuery.trim().length < 2) {
      return _SearchPrompt(
        icon: Icons.travel_explore_rounded,
        title: copy.exploreCommunity,
        message: copy.searchPrompt,
      );
    }
    if (provider.isLoading && provider.result == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return FriendlyState(
        icon: Icons.cloud_off_rounded,
        title: copy.searchFailed,
        message: provider.error!,
        actionLabel: copy.retry,
        onAction: onRetry,
      );
    }
    final result = provider.result;
    if (result == null) return const SizedBox.shrink();

    final items = <Widget>[];
    if ((filter == _SearchFilter.all || filter == _SearchFilter.people) &&
        result.users.isNotEmpty) {
      items.add(_SectionTitle(label: copy.people, count: result.userTotal));
      items.addAll(
        result.users.map(
          (person) => _PersonResult(
            person: person,
            query: result.query,
            onTap: () => onPersonTap(person),
          ),
        ),
      );
    }
    if ((filter == _SearchFilter.all || filter == _SearchFilter.groups) &&
        result.groups.isNotEmpty) {
      items.add(_SectionTitle(label: copy.groups, count: result.groupTotal));
      items.addAll(
        result.groups.map(
          (group) => _GroupResult(
            group: group,
            query: result.query,
            onTap: () => onGroupTap(group),
          ),
        ),
      );
    }
    if ((filter == _SearchFilter.all || filter == _SearchFilter.posts) &&
        result.posts.isNotEmpty) {
      items.add(_SectionTitle(label: copy.posts, count: result.postTotal));
      items.addAll(
        result.posts.map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PostCard(post: post, highlightQuery: result.query),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return _SearchPrompt(
        icon: Icons.search_off_rounded,
        title: copy.noSearchResults,
        message: copy.noSearchResultsHint,
      );
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
      itemCount: items.length,
      itemBuilder: (_, index) => items[index],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          Text(
            copy.resultCount(count),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonResult extends StatelessWidget {
  const _PersonResult({
    required this.person,
    required this.query,
    required this.onTap,
  });

  final SearchPerson person;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: UserAvatar(label: person.displayName, accent: AppColors.coral),
        title: _HighlightedText(
          text: person.displayName,
          query: query,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          person.bio?.trim().isNotEmpty == true
              ? person.bio!
              : copy.personDefaultBio,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _GroupResult extends StatelessWidget {
  const _GroupResult({
    required this.group,
    required this.query,
    required this.onTap,
  });

  final SocialGroup group;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: UserAvatar(
          label: group.name,
          imageUrl: group.avatarUrl,
          accent: AppColors.mint,
        ),
        title: _HighlightedText(
          text: group.name,
          query: query,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          group.description.trim().isEmpty
              ? copy.memberCount(group.memberCount)
              : '${copy.memberCount(group.memberCount)}  •  ${group.description}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.text, required this.query, this.style});

  final String text;
  final String query;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedText = text.toLowerCase();
    if (normalizedQuery.isEmpty || !normalizedText.contains(normalizedQuery)) {
      return Text(
        text,
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    while (cursor < text.length) {
      final match = normalizedText.indexOf(normalizedQuery, cursor);
      if (match < 0) {
        spans.add(TextSpan(text: text.substring(cursor)));
        break;
      }
      if (match > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match)));
      }
      final end = match + normalizedQuery.length;
      spans.add(
        TextSpan(
          text: text.substring(match, end),
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
      TextSpan(style: style, children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.indigo.withValues(alpha: .16),
                    AppColors.mint.withValues(alpha: .12),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 38, color: AppColors.indigo),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
