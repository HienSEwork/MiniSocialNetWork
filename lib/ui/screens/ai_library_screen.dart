import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/ai_prompt_models.dart';
import '../../data/providers/ai_library_provider.dart';
import '../../data/providers/module_state.dart';
import '../widgets/common.dart';
import '../widgets/module_states.dart';
import '../widgets/tech_lab_widgets.dart';

class AiLibraryScreen extends StatelessWidget {
  const AiLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) => TechModuleScaffold(
    title: 'AI Prompt Library',
    body: Consumer<AiLibraryProvider>(
      builder: (context, provider, _) {
        if (provider.status == ModuleStatus.loading &&
            provider.templates.isEmpty) {
          return const LoadingIndicator(label: 'Đang mở thư viện prompt…');
        }
        if (provider.status == ModuleStatus.error &&
            provider.templates.isEmpty) {
          return ErrorStateWidget(
            message: provider.error ?? 'Không thể tải thư viện prompt.',
            onRetry: provider.load,
          );
        }
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    const ModuleHero(
                      eyebrow: 'Prompt workbench',
                      title: 'Từ biến số đến prompt dùng ngay',
                      description:
                          'Điền đúng phần thay đổi, xem bản hoàn chỉnh và sao chép trong một chạm.',
                      icon: Icons.auto_awesome_rounded,
                      colors: [
                        Color(0xFF172033),
                        Color(0xFF5D38F5),
                        Color(0xFFB14AED),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      onChanged: provider.setQuery,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'Tìm prompt theo tên, mục đích…',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          FilterChip(
                            selected: provider.bookmarksOnly,
                            onSelected: provider.setBookmarksOnly,
                            avatar: const Icon(
                              Icons.bookmark_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('Đã lưu'),
                          ),
                          const SizedBox(width: 8),
                          for (final platform in provider.platforms) ...[
                            ChoiceChip(
                              selected: provider.platform == platform,
                              onSelected: (_) => provider.setPlatform(platform),
                              label: Text(platform),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SectionTitle(
                      title: 'Prompt tuyển chọn',
                      subtitle:
                          '${provider.visibleTemplates.length} mẫu phù hợp',
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (provider.visibleTemplates.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  icon: Icons.manage_search_rounded,
                  title: 'Không tìm thấy prompt',
                  message: 'Đổi từ khóa hoặc bỏ bớt bộ lọc để xem thêm mẫu.',
                  actionLabel: 'Xóa bộ lọc',
                  onAction: () {
                    provider.setQuery('');
                    provider.setPlatform('Tất cả');
                    provider.setBookmarksOnly(false);
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 36),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) => SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: constraints.crossAxisExtent >= 700
                          ? 360
                          : 500,
                      mainAxisExtent: 212,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _PromptCard(
                        template: provider.visibleTemplates[index],
                        onOpen: () => _openBuilder(
                          context,
                          provider.visibleTemplates[index],
                        ),
                        onBookmark: () => _bookmark(
                          context,
                          provider,
                          provider.visibleTemplates[index],
                        ),
                      ),
                      childCount: provider.visibleTemplates.length,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  Future<void> _openBuilder(
    BuildContext context,
    AiPromptTemplate template,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PromptBuilderSheet(template: template),
    );
  }

  Future<void> _bookmark(
    BuildContext context,
    AiLibraryProvider provider,
    AiPromptTemplate template,
  ) async {
    final error = await provider.toggleBookmark(template);
    if (!context.mounted) return;
    showResultMessage(
      context,
      error ?? (template.isBookmarked ? 'Đã bỏ lưu prompt.' : 'Đã lưu prompt.'),
      error: error != null,
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.template,
    required this.onOpen,
    required this.onBookmark,
  });
  final AiPromptTemplate template;
  final VoidCallback onOpen;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final accent = _platformColor(template.platform);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: moduleSurface(context, accent),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      template.platform,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: template.isBookmarked ? 'Bỏ lưu' : 'Lưu prompt',
                    onPressed: onBookmark,
                    icon: Icon(
                      template.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: template.isBookmarked ? accent : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                template.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                template.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.data_object_rounded, size: 18, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${template.variables.length} biến · ${template.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PromptBuilderSheet extends StatefulWidget {
  const PromptBuilderSheet({super.key, required this.template});
  final AiPromptTemplate template;

  @override
  State<PromptBuilderSheet> createState() => _PromptBuilderSheetState();
}

class _PromptBuilderSheetState extends State<PromptBuilderSheet> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final variable in widget.template.variables)
        variable: TextEditingController(),
    };
    for (final controller in _controllers.values) {
      controller.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller
        ..removeListener(_refresh)
        ..dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AiLibraryProvider>();
    final values = _controllers.map((key, value) => MapEntry(key, value.text));
    final output = provider.buildPrompt(widget.template, values);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .9,
      minChildSize: .62,
      maxChildSize: .96,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.template.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (widget.template.beforeImage != null ||
                    widget.template.afterImage != null)
                  _PreviewPair(template: widget.template),
                if (widget.template.beforeImage != null ||
                    widget.template.afterImage != null)
                  const SizedBox(height: 18),
                const SectionTitle(
                  title: 'Điền biến',
                  subtitle: 'Mỗi ô thay trực tiếp vào dấu ngoặc nhọn.',
                ),
                const SizedBox(height: 12),
                for (final entry in _controllers.entries) ...[
                  TextField(
                    controller: entry.value,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: _variableLabel(entry.key),
                      hintText: 'Nhập ${entry.key}',
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                const SectionTitle(title: 'Prompt hoàn chỉnh'),
                const SizedBox(height: 10),
                SelectableText(
                  output,
                  style: const TextStyle(
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _copy(context, output),
                  icon: const Icon(Icons.copy_all_rounded),
                  label: const Text('Sao chép prompt'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String output) async {
    try {
      await Clipboard.setData(ClipboardData(text: output));
      if (!context.mounted) return;
      showResultMessage(context, 'Đã sao chép prompt vào clipboard.');
    } catch (_) {
      if (!context.mounted) return;
      showResultMessage(
        context,
        'Không thể sao chép prompt. Hãy thử lại.',
        error: true,
      );
    }
  }
}

class _PreviewPair extends StatelessWidget {
  const _PreviewPair({required this.template});
  final AiPromptTemplate template;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final children = [
        if (template.beforeImage != null)
          _PreviewImage(label: 'Trước', path: template.beforeImage!),
        if (template.afterImage != null)
          _PreviewImage(label: 'Sau', path: template.afterImage!),
      ];
      if (constraints.maxWidth < 520) {
        return Column(
          children: [
            for (final child in children)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: child),
          ],
        );
      }
      return Row(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            Expanded(child: children[index]),
            if (index < children.length - 1) const SizedBox(width: 10),
          ],
        ],
      );
    },
  );
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.label, required this.path});
  final String label;
  final String path;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: AppMediaImage(url: path, width: 700, height: 394),
        ),
        Positioned(
          left: 10,
          top: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

String _variableLabel(String value) => switch (value) {
  'keyword' => 'Chủ đề / từ khóa',
  'style' => 'Phong cách',
  'tone' => 'Giọng điệu',
  'audience' => 'Đối tượng',
  'context' => 'Bối cảnh',
  'camera' => 'Máy ảnh / ống kính',
  'lighting' => 'Ánh sáng',
  'color' => 'Màu chủ đạo',
  _ => value,
};

Color _platformColor(String platform) => switch (platform) {
  'ChatGPT' => const Color(0xFF0B8F78),
  'Claude' => const Color(0xFFC7683A),
  'Midjourney' => const Color(0xFF4169E1),
  _ => const Color(0xFF8A3FFC),
};
