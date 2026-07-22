import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/hardware_models.dart';
import '../../data/providers/module_state.dart';
import '../../data/providers/pc_builder_provider.dart';
import '../widgets/common.dart';
import '../widgets/module_states.dart';
import '../widgets/tech_lab_widgets.dart';

class PcBuilderScreen extends StatefulWidget {
  const PcBuilderScreen({super.key});

  @override
  State<PcBuilderScreen> createState() => _PcBuilderScreenState();
}

class _PcBuilderScreenState extends State<PcBuilderScreen> {
  final GlobalKey _summaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) => TechModuleScaffold(
    title: 'PC Builder',
    actions: [
      IconButton(
        tooltip: 'Làm mới cấu hình',
        onPressed: context.read<PcBuilderProvider>().clearSelection,
        icon: const Icon(Icons.restart_alt_rounded),
      ),
    ],
    body: Consumer<PcBuilderProvider>(
      builder: (context, provider, _) {
        if (provider.status == ModuleStatus.loading &&
            provider.components.isEmpty) {
          return const LoadingIndicator(label: 'Đang nạp danh mục linh kiện…');
        }
        if (provider.status == ModuleStatus.error &&
            provider.components.isEmpty) {
          return ErrorStateWidget(
            message: provider.error ?? 'Không thể tải PC Builder.',
            onRetry: provider.load,
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
          children: [
            ModuleHero(
              eyebrow: '6 khe linh kiện',
              title: 'Lắp cấu hình, kiểm tra ngay',
              description:
                  'Socket và công suất dự phòng 25% được tính lại sau mỗi lựa chọn.',
              icon: Icons.memory_rounded,
              colors: const [
                Color(0xFF25104A),
                Color(0xFF5D38F5),
                Color(0xFFFF6B6B),
              ],
              trailing: _CompatibilityBadge(result: provider.compatibility),
            ),
            const SizedBox(height: 22),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final slots = _SlotsPanel(provider: provider);
                final summary = RepaintBoundary(
                  key: _summaryKey,
                  child: BuildSummaryCard(
                    selected: provider.selected,
                    result: provider.compatibility,
                  ),
                );
                if (!wide) {
                  return Column(
                    children: [slots, const SizedBox(height: 16), summary],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: slots),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: summary),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: provider.isSaving
                      ? null
                      : () => _saveBuild(context, provider),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Lưu cấu hình'),
                ),
                OutlinedButton.icon(
                  onPressed: provider.selected.isEmpty
                      ? null
                      : () => _exportCard(context),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Xuất thẻ PNG'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SectionTitle(
              title: 'Cấu hình đã lưu',
              subtitle: '${provider.savedBuilds.length} cấu hình trong máy',
            ),
            const SizedBox(height: 12),
            if (provider.savedBuilds.isEmpty)
              const EmptyStateWidget(
                icon: Icons.inventory_2_outlined,
                title: 'Chưa lưu cấu hình nào',
                message: 'Chọn đủ linh kiện rồi đặt tên cho bộ máy đầu tiên.',
              )
            else
              ...provider.savedBuilds.map(
                (build) => _SavedBuildTile(
                  savedBuild: build,
                  onEdit: () => provider.editBuild(build),
                  onDelete: () => _deleteBuild(context, provider, build),
                ),
              ),
          ],
        );
      },
    ),
  );

  Future<void> _saveBuild(
    BuildContext context,
    PcBuilderProvider provider,
  ) async {
    final controller = TextEditingController(
      text: 'TechNet Build ${provider.savedBuilds.length + 1}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lưu cấu hình'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(labelText: 'Tên cấu hình'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    final error = await provider.saveBuild(name);
    if (!context.mounted) return;
    showResultMessage(
      context,
      error ?? 'Đã lưu cấu hình vào máy.',
      error: error != null,
    );
  }

  Future<void> _deleteBuild(
    BuildContext context,
    PcBuilderProvider provider,
    PcBuild build,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa cấu hình?'),
        content: Text('“${build.name}” sẽ bị xóa khỏi thiết bị.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await provider.deleteBuild(build.id);
    if (!context.mounted) return;
    showResultMessage(
      context,
      error ?? 'Đã xóa cấu hình.',
      error: error != null,
    );
  }

  Future<void> _exportCard(BuildContext context) async {
    try {
      final boundary =
          _summaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('summary-not-ready');
      final image = await boundary.toImage(pixelRatio: 2.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('png-encoding-failed');
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}${Platform.pathSeparator}technet-build-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (!context.mounted) return;
      showResultMessage(context, 'Đã xuất thẻ cấu hình: ${file.path}');
    } catch (_) {
      if (!context.mounted) return;
      showResultMessage(
        context,
        'Không thể xuất ảnh cấu hình. Hãy thử lại.',
        error: true,
      );
    }
  }
}

class _SlotsPanel extends StatelessWidget {
  const _SlotsPanel({required this.provider});
  final PcBuilderProvider provider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final slot in HardwareComponent.slots)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SlotTile(
            slot: slot,
            component: provider.selected[slot],
            onTap: () => _showPicker(context, provider, slot),
            onRemove: provider.selected.containsKey(slot)
                ? () => provider.remove(slot)
                : null,
          ),
        ),
    ],
  );

  Future<void> _showPicker(
    BuildContext context,
    PcBuilderProvider provider,
    String slot,
  ) async {
    final items = provider.componentsFor(slot);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Chọn $slot',
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.memory_outlined,
                        title: 'Chưa có linh kiện',
                        message:
                            'Danh mục này chưa có sản phẩm đang hoạt động.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                        itemCount: items.length,
                        itemBuilder: (_, index) {
                          final item = items[index];
                          return Card(
                            child: ListTile(
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                '${item.brand} · ${formatVnd(item.price)}${item.socket == null ? '' : ' · ${item.socket}'}',
                              ),
                              trailing: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              onTap: () {
                                provider.select(slot, item);
                                Navigator.pop(sheetContext);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.component,
    required this.onTap,
    this.onRemove,
  });
  final String slot;
  final HardwareComponent? component;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: moduleSurface(context, AppColors.indigo),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_slotIcon(slot), color: AppColors.indigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.coral,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    component?.name ?? 'Chạm để chọn linh kiện',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (component != null)
                    Text(
                      formatVnd(component!.price),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (onRemove != null)
              IconButton(
                tooltip: 'Bỏ chọn',
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
              )
            else
              const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class BuildSummaryCard extends StatelessWidget {
  const BuildSummaryCard({
    super.key,
    required this.selected,
    required this.result,
  });
  final Map<String, HardwareComponent> selected;
  final PcCompatibilityResult result;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.developer_board_rounded, color: AppColors.indigo),
            const SizedBox(width: 9),
            Text(
              'TECHNET BUILD CARD',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (final slot in HardwareComponent.slots)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    slot,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    selected[slot]?.name ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 24),
        _SummaryRow(label: 'Chi phí', value: formatVnd(result.totalCost)),
        _SummaryRow(label: 'Công suất tải', value: '${result.totalWatt}W'),
        _SummaryRow(
          label: 'PSU tối thiểu',
          value: '${result.requiredPsuWatt}W',
        ),
        const SizedBox(height: 12),
        if (!result.isComplete)
          const _StatusLine(
            icon: Icons.pending_actions_rounded,
            text: 'Chưa chọn đủ 6 linh kiện',
            color: Color(0xFFF09A3E),
          )
        else if (result.errors.isEmpty)
          const _StatusLine(
            icon: Icons.verified_rounded,
            text: 'Socket và nguồn tương thích',
            color: Color(0xFF16A085),
          )
        else
          for (final error in result.errors)
            _StatusLine(
              icon: Icons.warning_amber_rounded,
              text: error,
              color: AppColors.coral,
            ),
      ],
    ),
  );
}

class _CompatibilityBadge extends StatelessWidget {
  const _CompatibilityBadge({required this.result});
  final PcCompatibilityResult result;
  @override
  Widget build(BuildContext context) {
    final ok = result.isCompatible;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.verified_rounded : Icons.rule_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 7),
          Text(
            ok ? 'Tương thích' : '${result.errors.length} cảnh báo',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _SavedBuildTile extends StatelessWidget {
  const _SavedBuildTile({
    required this.savedBuild,
    required this.onEdit,
    required this.onDelete,
  });
  final PcBuild savedBuild;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: Icon(
        savedBuild.isCompatible
            ? Icons.verified_rounded
            : Icons.warning_amber_rounded,
        color: savedBuild.isCompatible ? AppColors.mint : AppColors.coral,
      ),
      title: Text(
        savedBuild.name,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        '${formatVnd(savedBuild.totalCost)} · ${savedBuild.totalWatt}W · ${savedBuild.components.length}/6 khe',
      ),
      onTap: onEdit,
      trailing: IconButton(
        tooltip: 'Xóa cấu hình',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
    ),
  );
}

IconData _slotIcon(String slot) => switch (slot) {
  'CPU' => Icons.memory_rounded,
  'MAINBOARD' => Icons.developer_board_rounded,
  'RAM' => Icons.view_module_rounded,
  'GPU' => Icons.videogame_asset_rounded,
  'PSU' => Icons.electrical_services_rounded,
  _ => Icons.inventory_2_rounded,
};
