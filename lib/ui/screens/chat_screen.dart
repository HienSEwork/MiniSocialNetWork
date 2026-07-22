import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_copy.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/chat_models.dart';
import '../../data/models/group_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/chat_provider.dart';
import '../widgets/common.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().session?.isGuest != true) {
        context.read<ChatProvider>().loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final copy = AppCopy.of(context);
    final canPop = Navigator.of(context).canPop();
    if (auth.session?.isGuest == true) {
      return Scaffold(
        appBar: canPop ? AppBar(leading: const BackButton()) : null,
        body: FriendlyState(
          icon: Icons.lock_outline_rounded,
          title: copy.loginRequiredForChat,
          message: copy.loginRequiredForChatHint,
        ),
      );
    }
    return Scaffold(
      body: ResponsivePage(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (canPop) ...[
                          IconButton.filledTonal(
                            tooltip: copy.back,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            copy.chat,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (chat.isRealtimeConnected
                                        ? AppColors.mint
                                        : AppColors.coral)
                                    .withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            chat.isRealtimeConnected ? 'Realtime' : 'HTTP',
                            style: TextStyle(
                              color: chat.isRealtimeConnected
                                  ? AppColors.mint
                                  : AppColors.coral,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) => chat.loadUsers(keyword: value),
                      decoration: InputDecoration(
                        hintText: copy.chatSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (chat.isLoading && chat.users.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (chat.error != null && chat.users.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FriendlyState(
                  icon: Icons.forum_outlined,
                  title: copy.contactsLoadFailed,
                  message: chat.error!,
                  actionLabel: copy.retry,
                  onAction: chat.loadUsers,
                ),
              )
            else if (chat.users.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FriendlyState(
                  icon: Icons.person_search_rounded,
                  title: copy.noContacts,
                  message: copy.noContactsHint,
                ),
              )
            else
              SliverList.builder(
                itemCount: chat.users.length,
                itemBuilder: (context, index) {
                  final user = chat.users[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 5,
                    ),
                    leading: UserAvatar(
                      label: user.displayName,
                      accent: index.isEven ? AppColors.indigo : AppColors.mint,
                    ),
                    title: Text(
                      user.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      user.bio?.isNotEmpty == true
                          ? user.bio!
                          : copy.startPrivateChat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ConversationScreen(user: user),
                      ),
                    ),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, this.user, this.group})
    : assert(user != null || group != null);
  final ChatUser? user;
  final SocialGroup? group;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _message = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chat = context.read<ChatProvider>();
      if (widget.group != null) {
        await chat.openGroupChat(widget.group!.id);
      } else {
        await chat.openPrivateChat(widget.user!.id);
      }
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    _message.clear();
    final chat = context.read<ChatProvider>();
    final error = widget.group != null
        ? await chat.sendGroup(widget.group!.id, text)
        : await chat.sendPrivate(widget.user!.id, text);
    if (!mounted) return;
    if (error != null) showResultMessage(context, error, error: true);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final currentUserId = context.read<AuthProvider>().session?.userId;
    final copy = AppCopy.of(context);
    final title =
        widget.group?.name ?? widget.user?.displayName ?? copy.conversation;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(
              label: title,
              imageUrl: widget.user?.avatarUrl,
              radius: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chat.error != null && chat.messages.isEmpty
                ? FriendlyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: copy.conversationOpenFailed,
                    message: chat.error!,
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                    itemCount: chat.messages.length,
                    itemBuilder: (_, index) {
                      final item = chat.messages[index];
                      final mine = item.senderId == currentUserId;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 340),
                          margin: const EdgeInsets.only(bottom: 9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: mine
                                ? AppColors.indigo
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(mine ? 18 : 5),
                              bottomRight: Radius.circular(mine ? 5 : 18),
                            ),
                            border: mine
                                ? null
                                : Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.group != null && !mine) ...[
                                Text(
                                  item.senderName,
                                  style: const TextStyle(
                                    color: AppColors.mint,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                              ],
                              Text(
                                item.content,
                                style: TextStyle(
                                  color: mine ? Colors.white : null,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(hintText: copy.messageHint),
                    ),
                  ),
                  const SizedBox(width: 9),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
