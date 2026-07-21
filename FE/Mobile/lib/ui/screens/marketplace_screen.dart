import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/marketplace_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/community_provider.dart';
import '../../data/services/api_service.dart';
import '../widgets/common.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _search = TextEditingController();
  List<MarketplaceItem> _items = const [];
  MarketplaceStats? _stats;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.instance.get(
        '/marketplace',
        queryParameters: {
          if (_search.text.trim().isNotEmpty) 'keyword': _search.text.trim(),
        },
      );
      final statsRaw = await ApiService.instance.get('/marketplace/mine/stats');
      _items = _list(raw).map(MarketplaceItem.fromJson).toList();
      _stats = MarketplaceStats.fromJson(Map<String, dynamic>.from(statsRaw));
      _error = null;
    } on ApiFailure catch (error) {
      _error = error.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: TechNetGradientHeader(
                title: 'Marketplace',
                subtitle: stats == null
                    ? 'San mua ban do tech trong TechNet'
                    : 'Dang ban ${stats.activeCount}/${stats.limit} - Da ban ${stats.soldCount}',
                trailing: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.grape,
                  ),
                  tooltip: 'Dang san pham',
                  onPressed: () async {
                    await showMarketplaceItemSheet(context);
                    await _load();
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ResponsivePage(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.grape.withValues(alpha: .08),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _load(),
                      decoration: InputDecoration(
                        hintText: 'Tim laptop, gear, linh kien...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          tooltip: 'Xoa tim kiem',
                          onPressed: () {
                            _search.clear();
                            _load();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_loading && _items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: FriendlyState(
                  icon: Icons.storefront_outlined,
                  title: 'Chua tai duoc marketplace',
                  message: _error!,
                  actionLabel: 'Thu lai',
                  onAction: _load,
                ),
              )
            else if (_items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: FriendlyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Chua co san pham',
                  message: 'Dang mon do tech dau tien len san.',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, bottom),
                sliver: SliverList.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, index) => ResponsivePage(
                    child: MarketplaceItemCard(
                      item: _items[index],
                      onChanged: _load,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _list(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

class MarketplaceItemCard extends StatelessWidget {
  const MarketplaceItemCard({super.key, required this.item, this.onChanged});

  final MarketplaceItem item;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().session?.userId;
    final mine = item.sellerId == currentUserId;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 10,
      shadowColor: AppColors.grape.withValues(alpha: .10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 210,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.mediaUrl?.isNotEmpty == true)
                  OptimizedNetworkImage(
                    url: item.mediaUrl!,
                    width: 720,
                    height: 420,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ProductFallback(item: item),
                  )
                else
                  _ProductFallback(item: item),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .06),
                          Colors.black.withValues(alpha: .36),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: _StatusPill(sold: item.isSold),
                ),
                if (mine)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _MarketplaceMenu(item: item, onChanged: onChanged),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_money(item.price)} d',
                  style: const TextStyle(
                    color: AppColors.grape,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: Icons.category_outlined,
                      label: item.category,
                    ),
                    _MetaChip(
                      icon: Icons.verified_outlined,
                      label: item.condition,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    UserAvatar(
                      label: item.sellerName,
                      imageUrl: item.sellerAvatarUrl,
                      radius: 17,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.sellerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Icon(
                      Icons.storefront_outlined,
                      color: AppColors.ink.withValues(alpha: .45),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _money(double value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final index = text.length - i;
      buffer.write(text[i]);
      if (index > 1 && index % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }
}

class _MarketplaceMenu extends StatelessWidget {
  const _MarketplaceMenu({required this.item, this.onChanged});

  final MarketplaceItem item;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz_rounded),
        tooltip: 'Tuy chon',
        onSelected: (value) async {
          try {
            if (value == 'edit') {
              await showMarketplaceItemSheet(context, item: item);
            } else if (value == 'sold') {
              await ApiService.instance.post(
                '/marketplace/${item.id}/mark-sold',
              );
            } else if (value == 'relist') {
              await ApiService.instance.post('/marketplace/${item.id}/relist');
            } else if (value == 'delete') {
              await ApiService.instance.delete('/marketplace/${item.id}');
            }
            onChanged?.call();
          } on ApiFailure catch (error) {
            if (!context.mounted) return;
            showResultMessage(context, error.message, error: true);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Sua san pham')),
          PopupMenuItem(
            value: item.isSold ? 'relist' : 'sold',
            child: Text(item.isSold ? 'Ban lai' : 'Danh dau da ban'),
          ),
          const PopupMenuItem(value: 'delete', child: Text('Xoa san pham')),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.sold});

  final bool sold;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: sold ? Colors.black.withValues(alpha: .70) : Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sold ? Icons.check_circle_rounded : Icons.local_offer_rounded,
              size: 16,
              color: sold ? Colors.white : AppColors.grape,
            ),
            const SizedBox(width: 6),
            Text(
              sold ? 'Da ban' : 'Dang ban',
              style: TextStyle(
                color: sold ? Colors.white : AppColors.grape,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.indigo.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.grape),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                label.isEmpty ? 'Tech' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.grape,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFallback extends StatelessWidget {
  const _ProductFallback({required this.item});

  final MarketplaceItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.violet, AppColors.grape, AppColors.electric],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.devices_other_rounded,
              color: Colors.white,
              size: 52,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                item.category.isEmpty ? 'Tech item' : item.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showMarketplaceItemSheet(
  BuildContext context, {
  MarketplaceItem? item,
}) async {
  final community = context.read<CommunityProvider>();
  final editing = item != null;
  final title = TextEditingController(text: item?.title ?? '');
  final description = TextEditingController(text: item?.description ?? '');
  final price = TextEditingController(
    text: item == null ? '' : item.price.round().toString(),
  );
  final category = TextEditingController(text: item?.category ?? 'Laptop');
  final condition = TextEditingController(
    text: item?.condition ?? 'Da su dung',
  );
  var mediaUrl = item?.mediaUrl ?? '';
  var mediaName = '';
  var uploading = false;
  var saving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      editing ? 'Sua san pham' : 'Dang san pham',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dong',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: uploading || saving
                    ? null
                    : () async {
                        final image = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 88,
                          maxWidth: 1400,
                        );
                        if (image == null) return;
                        setSheetState(() => uploading = true);
                        try {
                          final uploaded = await community.uploadMedia(
                            fileName: image.name,
                            filePath: image.path,
                            bytes: await image.readAsBytes(),
                          );
                          if (!sheetContext.mounted) return;
                          setSheetState(() {
                            mediaUrl = uploaded.url;
                            mediaName = image.name;
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
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  mediaName.isEmpty ? 'Chon anh san pham' : mediaName,
                ),
              ),
              if (mediaUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: OptimizedNetworkImage(
                      url: mediaUrl,
                      width: 720,
                      height: 405,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ProductFallback(
                        item: item ?? _draftItem(category.text),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Ten san pham'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Gia'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: category,
                decoration: const InputDecoration(labelText: 'Danh muc'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: condition,
                decoration: const InputDecoration(labelText: 'Tinh trang'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: description,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Mo ta'),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        setSheetState(() => saving = true);
                        final data = {
                          'title': title.text.trim(),
                          'description': description.text.trim(),
                          'price': double.tryParse(price.text.trim()) ?? 0,
                          'category': category.text.trim(),
                          'condition': condition.text.trim(),
                          'mediaUrl': mediaUrl,
                        };
                        try {
                          if (editing) {
                            await ApiService.instance.put(
                              '/marketplace/${item.id}',
                              data: data,
                            );
                          } else {
                            await ApiService.instance.post(
                              '/marketplace',
                              data: data,
                            );
                          }
                          if (!sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          showResultMessage(
                            context,
                            editing
                                ? 'Da cap nhat san pham.'
                                : 'Da dang san pham.',
                          );
                        } on ApiFailure catch (error) {
                          if (!sheetContext.mounted) return;
                          setSheetState(() => saving = false);
                          showResultMessage(
                            sheetContext,
                            error.message,
                            error: true,
                          );
                        }
                      },
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Text(editing ? 'Luu san pham' : 'Dang len san'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

MarketplaceItem _draftItem(String category) => MarketplaceItem(
  id: '',
  sellerId: '',
  sellerName: '',
  title: '',
  description: '',
  price: 0,
  category: category,
  condition: '',
  status: 0,
  createdDate: DateTime.now(),
);
