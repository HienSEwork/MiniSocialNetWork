import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/gear_price_models.dart';
import '../../data/providers/gear_price_provider.dart';
import '../../data/providers/module_state.dart';
import '../widgets/common.dart';
import '../widgets/module_states.dart';
import '../widgets/tech_lab_widgets.dart';

class GearPriceScreen extends StatelessWidget {
  const GearPriceScreen({super.key});

  @override
  Widget build(BuildContext context) => TechModuleScaffold(
    title: 'Gear Price Checker',
    body: Consumer<GearPriceProvider>(
      builder: (context, provider, _) {
        if (provider.status == ModuleStatus.loading &&
            provider.products.isEmpty) {
          return const LoadingIndicator(label: 'Đang nạp chỉ số giá thiết bị…');
        }
        if (provider.status == ModuleStatus.error &&
            provider.products.isEmpty) {
          return ErrorStateWidget(
            message: provider.error ?? 'Không thể tải bảng giá.',
            onRetry: provider.load,
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
          children: [
            const ModuleHero(
              eyebrow: 'Giá cũ có căn cứ',
              title: 'Ước tính trước khi mua hoặc bán',
              description:
                  'Kết hợp MSRP, tuổi thiết bị, tỷ lệ khấu hao và tình trạng thực tế.',
              icon: Icons.price_check_rounded,
              colors: [Color(0xFF3D1D0B), Color(0xFFB45A1B), Color(0xFFFF8A5B)],
            ),
            const SizedBox(height: 18),
            TextField(
              onChanged: provider.setQuery,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Tìm MacBook, iPhone, bàn phím, GPU…',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: provider.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final category = provider.categories[index];
                  return ChoiceChip(
                    selected: provider.category == category,
                    onSelected: (_) => provider.setCategory(category),
                    label: Text(category),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle(
              title: 'Chọn thiết bị',
              subtitle: 'Chỉ số MSRP được quản trị ngay trên máy.',
            ),
            const SizedBox(height: 10),
            if (provider.visibleProducts.isEmpty)
              const EmptyStateWidget(
                icon: Icons.search_off_rounded,
                title: 'Không tìm thấy thiết bị',
                message: 'Thử tên model ngắn hơn hoặc đổi danh mục.',
              )
            else
              SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.visibleProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, index) {
                    final product = provider.visibleProducts[index];
                    return _ProductChoice(
                      product: product,
                      selected: provider.selectedProduct?.id == product.id,
                      onTap: () => provider.selectProduct(product),
                    );
                  },
                ),
              ),
            if (provider.selectedProduct != null) ...[
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final calculator = _CalculatorPanel(provider: provider);
                  final estimate = _EstimatePanel(provider: provider);
                  if (constraints.maxWidth < 700) {
                    return Column(
                      children: [
                        calculator,
                        const SizedBox(height: 12),
                        estimate,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: calculator),
                      const SizedBox(width: 14),
                      Expanded(child: estimate),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 28),
            SectionTitle(
              title: 'My Gear Closet',
              subtitle: '${provider.closet.length} thiết bị đang theo dõi',
            ),
            const SizedBox(height: 12),
            if (provider.closet.isEmpty)
              const EmptyStateWidget(
                icon: Icons.inventory_2_outlined,
                title: 'Tủ đồ đang trống',
                message: 'Chọn một thiết bị và lưu lại giá mua để theo dõi.',
              )
            else
              ...provider.closet.map(
                (item) => _ClosetTile(
                  item: item,
                  onDelete: () => _deleteCloset(context, provider, item),
                ),
              ),
          ],
        );
      },
    ),
  );

  Future<void> _deleteCloset(
    BuildContext context,
    GearPriceProvider provider,
    GearClosetItem item,
  ) async {
    final error = await provider.deleteClosetItem(item.id);
    if (!context.mounted) return;
    showResultMessage(
      context,
      error ?? 'Đã xóa thiết bị khỏi tủ đồ.',
      error: error != null,
    );
  }
}

class _ProductChoice extends StatelessWidget {
  const _ProductChoice({
    required this.product,
    required this.selected,
    required this.onTap,
  });
  final GearProduct product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Material(
      color: selected
          ? AppColors.indigo
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.category.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: selected ? Colors.white70 : AppColors.coral,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : null,
                ),
              ),
              const Spacer(),
              Text(
                formatVnd(product.msrp),
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? Colors.white70
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CalculatorPanel extends StatelessWidget {
  const _CalculatorPanel({required this.provider});
  final GearPriceProvider provider;

  @override
  Widget build(BuildContext context) {
    final product = provider.selectedProduct!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Xem thông số',
                  onPressed: () => _showSpecs(context, product),
                  icon: const Icon(Icons.info_outline_rounded),
                ),
              ],
            ),
            Text(
              'MSRP ${formatVnd(product.msrp)} · khấu hao ${(product.annualDepreciation * 100).round()}%/năm',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tình trạng: ${_conditionLabel(provider.conditionPercent)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text('${provider.conditionPercent.round()}%'),
              ],
            ),
            Slider(
              value: provider.conditionPercent,
              min: 20,
              max: 99,
              divisions: 79,
              label: '${provider.conditionPercent.round()}%',
              onChanged: provider.setCondition,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('Ngày bắt đầu sử dụng'),
              subtitle: Text(_dateLabel(provider.purchaseDate)),
              trailing: const Icon(Icons.edit_calendar_rounded),
              onTap: () => _pickDate(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    GearPriceProvider provider,
  ) async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: provider.purchaseDate,
        firstDate: DateTime(2005),
        lastDate: DateTime.now(),
      );
      if (picked != null) provider.setPurchaseDate(picked);
    } catch (_) {
      if (!context.mounted) return;
      showResultMessage(context, 'Không thể mở lịch chọn ngày.', error: true);
    }
  }

  Future<void> _showSpecs(BuildContext context, GearProduct product) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.displayName,
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
              const SizedBox(height: 10),
              for (final entry in product.specs.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  trailing: Flexible(
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstimatePanel extends StatelessWidget {
  const _EstimatePanel({required this.provider});
  final GearPriceProvider provider;

  @override
  Widget build(BuildContext context) {
    final estimate = provider.estimate!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E160B), Color(0xFF8A3A16)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GIÁ THAM CHIẾU HIỆN TẠI',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatVnd(estimate.currentValue),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Sau ${estimate.ageYears.toStringAsFixed(1)} năm · tình trạng ${estimate.conditionPercent.round()}%',
            style: const TextStyle(color: Colors.white70),
          ),
          const Divider(height: 28, color: Colors.white24),
          _PriceRange(
            label: 'Khoảng mua hợp lý',
            low: estimate.buyLow,
            high: estimate.buyHigh,
            icon: Icons.shopping_bag_outlined,
          ),
          const SizedBox(height: 12),
          _PriceRange(
            label: 'Khoảng bán đề xuất',
            low: estimate.sellLow,
            high: estimate.sellHigh,
            icon: Icons.sell_outlined,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6C2B10),
            ),
            onPressed: () => _saveToCloset(context, provider),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Thêm vào tủ đồ'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToCloset(
    BuildContext context,
    GearPriceProvider provider,
  ) async {
    final price = TextEditingController(
      text: provider.selectedProduct!.msrp.round().toString(),
    );
    final notes = TextEditingController();
    final values = await showDialog<(double, String)?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thêm vào My Gear Closet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá đã mua (₫)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notes,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(
                price.text.replaceAll(RegExp(r'[^0-9.]'), ''),
              );
              if (parsed == null || parsed < 0) return;
              Navigator.pop(dialogContext, (parsed, notes.text));
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    price.dispose();
    notes.dispose();
    if (values == null || !context.mounted) return;
    final error = await provider.addToCloset(
      purchasePrice: values.$1,
      notes: values.$2,
    );
    if (!context.mounted) return;
    showResultMessage(
      context,
      error ?? 'Đã thêm thiết bị vào tủ đồ.',
      error: error != null,
    );
  }
}

class _PriceRange extends StatelessWidget {
  const _PriceRange({
    required this.label,
    required this.low,
    required this.high,
    required this.icon,
  });
  final String label;
  final double low;
  final double high;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFFFFC39E)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 3),
            Text(
              '${formatVnd(low)} – ${formatVnd(high)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ClosetTile extends StatelessWidget {
  const _ClosetTile({required this.item, required this.onDelete});
  final GearClosetItem item;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final estimate = product == null
        ? null
        : GearDepreciationEngine.estimate(
            msrp: product.msrp,
            annualDepreciation: product.annualDepreciation,
            releaseDate: item.purchaseDate,
            conditionPercent: item.conditionPercent,
          );
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.devices_other_rounded)),
        title: Text(
          product?.displayName ?? 'Thiết bị không còn trong chỉ mục',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${item.conditionPercent.round()}% · mua ${formatVnd(item.purchasePrice)}${estimate == null ? '' : ' · nay ~${formatVnd(estimate.currentValue)}'}',
        ),
        trailing: IconButton(
          tooltip: 'Xóa khỏi tủ đồ',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ),
    );
  }
}

String _conditionLabel(double value) {
  if (value >= 95) return '99% Like New';
  if (value >= 72) return 'Hết bảo hành';
  if (value >= 45) return 'Trầy xước / đã dùng';
  return 'Cần sửa chữa';
}

String _dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
