import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/local/local_database.dart';
import '../../data/models/ai_prompt_models.dart';
import '../../data/models/gear_price_models.dart';
import '../../data/models/hardware_models.dart';
import '../../data/models/trivia_models.dart';
import '../../data/providers/ai_library_provider.dart';
import '../../data/providers/gear_price_provider.dart';
import '../../data/providers/pc_builder_provider.dart';
import '../../data/providers/trivia_provider.dart';
import '../widgets/common.dart';
import '../widgets/module_states.dart';
import '../widgets/tech_lab_widgets.dart';

class TechModulesAdminScreen extends StatefulWidget {
  const TechModulesAdminScreen({super.key});

  @override
  State<TechModulesAdminScreen> createState() => _TechModulesAdminScreenState();
}

class _TechModulesAdminScreenState extends State<TechModulesAdminScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      await Future.wait([
        context.read<TriviaProvider>().loadAdminQuestions(),
        context.read<PcBuilderProvider>().loadAdminComponents(),
        context.read<AiLibraryProvider>().loadAdminTemplates(),
        context.read<GearPriceProvider>().loadAdminProducts(),
      ]);
    } catch (_) {
      if (mounted) {
        showResultMessage(
          context,
          'Không thể tải dữ liệu quản trị.',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Quản trị Tech Lab'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.quiz_outlined), text: 'Trivia'),
            Tab(icon: Icon(Icons.memory_rounded), text: 'Linh kiện'),
            Tab(icon: Icon(Icons.auto_awesome_rounded), text: 'AI Prompt'),
            Tab(icon: Icon(Icons.price_check_rounded), text: 'Bảng giá'),
          ],
        ),
      ),
      body: _loading
          ? const LoadingIndicator(label: 'Đang tải dữ liệu quản trị…')
          : const TabBarView(
              children: [
                _TriviaAdminTab(),
                _HardwareAdminTab(),
                _PromptAdminTab(),
                _GearAdminTab(),
              ],
            ),
    ),
  );
}

class _TriviaAdminTab extends StatelessWidget {
  const _TriviaAdminTab();
  @override
  Widget build(BuildContext context) => Consumer<TriviaProvider>(
    builder: (context, provider, _) => _AdminListShell(
      title: 'Ngân hàng câu hỏi',
      count: provider.adminQuestions.length,
      onAdd: () => _editQuestion(context),
      empty: provider.adminQuestions.isEmpty,
      emptyMessage: 'Chưa có câu hỏi trivia.',
      children: [
        for (final item in provider.adminQuestions)
          _AdminRow(
            title: item.question,
            subtitle:
                '${item.category} · ${item.xpReward} XP · ${item.isActive ? 'Đang dùng' : 'Tạm ẩn'}',
            leading: Icons.quiz_rounded,
            onEdit: () => _editQuestion(context, item),
            onDelete: () => _delete(
              context,
              'Xóa câu hỏi?',
              () => provider.deleteQuestion(item.id),
            ),
          ),
      ],
    ),
  );

  Future<void> _editQuestion(
    BuildContext context, [
    TriviaQuestion? item,
  ]) async {
    final question = TextEditingController(text: item?.question);
    final options = List.generate(
      4,
      (index) => TextEditingController(
        text: item?.options.elementAtOrNull(index) ?? '',
      ),
    );
    final explanation = TextEditingController(text: item?.explanation);
    final category = TextEditingController(text: item?.category ?? 'Công nghệ');
    final xp = TextEditingController(text: '${item?.xpReward ?? 15}');
    var correct = item?.correctIndex ?? 0;
    var active = item?.isActive ?? true;
    final saved = await showDialog<TriviaQuestion>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(item == null ? 'Thêm câu hỏi' : 'Sửa câu hỏi'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: question,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Câu hỏi'),
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0; index < options.length; index++) ...[
                    TextField(
                      controller: options[index],
                      decoration: InputDecoration(
                        labelText: 'Đáp án ${String.fromCharCode(65 + index)}',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  DropdownButtonFormField<int>(
                    initialValue: correct,
                    decoration: const InputDecoration(labelText: 'Đáp án đúng'),
                    items: List.generate(
                      4,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text(
                          'Đáp án ${String.fromCharCode(65 + index)}',
                        ),
                      ),
                    ),
                    onChanged: (value) => setLocal(() => correct = value ?? 0),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: explanation,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Giải thích'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: category,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: xp,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'XP thưởng'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Đang hoạt động'),
                    value: active,
                    onChanged: (value) => setLocal(() => active = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final values = options
                    .map((controller) => controller.text.trim())
                    .toList();
                final reward = int.tryParse(xp.text);
                if (question.text.trim().isEmpty ||
                    values.any((value) => value.isEmpty) ||
                    explanation.text.trim().isEmpty ||
                    reward == null ||
                    reward < 0) {
                  showResultMessage(
                    context,
                    'Điền đủ câu hỏi, 4 đáp án, giải thích và XP hợp lệ.',
                    error: true,
                  );
                  return;
                }
                final now = DateTime.now();
                Navigator.pop(
                  dialogContext,
                  TriviaQuestion(
                    id: item?.id ?? LocalDatabase.newId('trivia'),
                    question: question.text.trim(),
                    options: values,
                    correctIndex: correct,
                    explanation: explanation.text.trim(),
                    category: category.text.trim().isEmpty
                        ? 'Công nghệ'
                        : category.text.trim(),
                    xpReward: reward,
                    isActive: active,
                    createdAt: item?.createdAt ?? now,
                    updatedAt: now,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    for (final controller in [
      question,
      ...options,
      explanation,
      category,
      xp,
    ]) {
      controller.dispose();
    }
    if (saved == null || !context.mounted) return;
    final error = await context.read<TriviaProvider>().saveQuestion(
      saved,
      create: item == null,
    );
    if (!context.mounted) return;
    showResultMessage(
      context,
      error ?? 'Đã lưu câu hỏi.',
      error: error != null,
    );
  }
}

class _HardwareAdminTab extends StatelessWidget {
  const _HardwareAdminTab();
  @override
  Widget build(BuildContext context) => Consumer<PcBuilderProvider>(
    builder: (context, provider, _) => _AdminListShell(
      title: 'Danh mục linh kiện',
      count: provider.adminComponents.length,
      onAdd: () => _editComponent(context),
      empty: provider.adminComponents.isEmpty,
      emptyMessage: 'Chưa có linh kiện.',
      children: [
        for (final item in provider.adminComponents)
          _AdminRow(
            title: item.name,
            subtitle:
                '${item.type} · ${item.brand} · ${formatVnd(item.price)} · ${item.isActive ? 'Đang dùng' : 'Tạm ẩn'}',
            leading: Icons.memory_rounded,
            onEdit: () => _editComponent(context, item),
            onDelete: () => _delete(
              context,
              'Xóa linh kiện?',
              () => provider.deleteComponent(item.id),
            ),
          ),
      ],
    ),
  );

  Future<void> _editComponent(
    BuildContext context, [
    HardwareComponent? item,
  ]) async {
    final name = TextEditingController(text: item?.name);
    final brand = TextEditingController(text: item?.brand);
    final socket = TextEditingController(text: item?.socket);
    final power = TextEditingController(text: '${item?.powerWatt ?? 0}');
    final psu = TextEditingController(text: '${item?.psuWatt ?? 0}');
    final price = TextEditingController(text: '${item?.price.round() ?? 0}');
    final specs = TextEditingController(
      text: item?.specs.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('\n'),
    );
    var type = item?.type ?? 'CPU';
    var active = item?.isActive ?? true;
    final saved = await showDialog<HardwareComponent>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(item == null ? 'Thêm linh kiện' : 'Sửa linh kiện'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Loại'),
                    items: HardwareComponent.slots
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setLocal(() => type = value ?? 'CPU'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Tên linh kiện',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: brand,
                    decoration: const InputDecoration(labelText: 'Hãng'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: socket,
                    decoration: const InputDecoration(
                      labelText: 'Socket (CPU/Mainboard)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: power,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Điện tiêu thụ W',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: psu,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Công suất PSU W',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Giá (₫)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: specs,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Thông số (mỗi dòng key=value)',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Đang hoạt động'),
                    value: active,
                    onChanged: (value) => setLocal(() => active = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final parsedPower = int.tryParse(power.text);
                final parsedPsu = int.tryParse(psu.text);
                final parsedPrice = double.tryParse(price.text);
                if (name.text.trim().isEmpty ||
                    brand.text.trim().isEmpty ||
                    parsedPower == null ||
                    parsedPower < 0 ||
                    parsedPsu == null ||
                    parsedPsu < 0 ||
                    parsedPrice == null ||
                    parsedPrice < 0) {
                  showResultMessage(
                    context,
                    'Tên, hãng, công suất và giá phải hợp lệ.',
                    error: true,
                  );
                  return;
                }
                final now = DateTime.now();
                Navigator.pop(
                  dialogContext,
                  HardwareComponent(
                    id: item?.id ?? LocalDatabase.newId('component'),
                    type: type,
                    name: name.text.trim(),
                    brand: brand.text.trim(),
                    socket: socket.text.trim().isEmpty
                        ? null
                        : socket.text.trim(),
                    powerWatt: parsedPower,
                    psuWatt: parsedPsu,
                    price: parsedPrice,
                    specs: _parseSpecs(specs.text),
                    isActive: active,
                    createdAt: item?.createdAt ?? now,
                    updatedAt: now,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    for (final controller in [name, brand, socket, power, psu, price, specs]) {
      controller.dispose();
    }
    if (saved == null || !context.mounted) return;
    final error = await context.read<PcBuilderProvider>().saveComponent(
      saved,
      create: item == null,
    );
    if (!context.mounted) return;
    showResultMessage(
      context,
      error ?? 'Đã lưu linh kiện.',
      error: error != null,
    );
  }
}

class _PromptAdminTab extends StatelessWidget {
  const _PromptAdminTab();
  @override
  Widget build(BuildContext context) => Consumer<AiLibraryProvider>(
    builder: (context, provider, _) => _AdminListShell(
      title: 'Danh mục AI prompt',
      count: provider.adminTemplates.length,
      onAdd: () => _editPrompt(context),
      empty: provider.adminTemplates.isEmpty,
      emptyMessage: 'Chưa có prompt.',
      children: [
        for (final item in provider.adminTemplates)
          _AdminRow(
            title: item.title,
            subtitle:
                '${item.platform} · ${item.category} · ${item.isActive ? 'Đang dùng' : 'Tạm ẩn'}',
            leading: Icons.auto_awesome_rounded,
            onEdit: () => _editPrompt(context, item),
            onDelete: () => _delete(
              context,
              'Xóa prompt?',
              () => provider.deleteTemplate(item.id),
            ),
          ),
      ],
    ),
  );

  Future<void> _editPrompt(
    BuildContext context, [
    AiPromptTemplate? item,
  ]) async {
    final title = TextEditingController(text: item?.title);
    final platform = TextEditingController(text: item?.platform ?? 'ChatGPT');
    final category = TextEditingController(text: item?.category ?? 'Sáng tạo');
    final description = TextEditingController(text: item?.description);
    final template = TextEditingController(text: item?.template);
    final before = TextEditingController(text: item?.beforeImage);
    final after = TextEditingController(text: item?.afterImage);
    var active = item?.isActive ?? true;
    final saved = await showDialog<AiPromptTemplate>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(item == null ? 'Thêm prompt' : 'Sửa prompt'),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Tiêu đề'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: platform,
                          decoration: const InputDecoration(
                            labelText: 'Nền tảng',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: category,
                          decoration: const InputDecoration(
                            labelText: 'Danh mục',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: description,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: template,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Prompt template',
                      helperText: 'Biến dùng dạng {keyword}, {style}, {tone}…',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: before,
                    decoration: const InputDecoration(
                      labelText: 'Ảnh trước (asset path, tùy chọn)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: after,
                    decoration: const InputDecoration(
                      labelText: 'Ảnh sau (asset path, tùy chọn)',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Đang hoạt động'),
                    value: active,
                    onChanged: (value) => setLocal(() => active = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (title.text.trim().isEmpty ||
                    platform.text.trim().isEmpty ||
                    category.text.trim().isEmpty ||
                    description.text.trim().isEmpty ||
                    template.text.trim().isEmpty) {
                  showResultMessage(
                    context,
                    'Điền đủ tiêu đề, nền tảng, danh mục, mô tả và template.',
                    error: true,
                  );
                  return;
                }
                final now = DateTime.now();
                Navigator.pop(
                  dialogContext,
                  AiPromptTemplate(
                    id: item?.id ?? LocalDatabase.newId('prompt'),
                    title: title.text.trim(),
                    platform: platform.text.trim(),
                    category: category.text.trim(),
                    description: description.text.trim(),
                    template: template.text.trim(),
                    beforeImage: before.text.trim().isEmpty
                        ? null
                        : before.text.trim(),
                    afterImage: after.text.trim().isEmpty
                        ? null
                        : after.text.trim(),
                    isActive: active,
                    createdAt: item?.createdAt ?? now,
                    updatedAt: now,
                    isBookmarked: item?.isBookmarked ?? false,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    for (final controller in [
      title,
      platform,
      category,
      description,
      template,
      before,
      after,
    ]) {
      controller.dispose();
    }
    if (saved == null || !context.mounted) return;
    final error = await context.read<AiLibraryProvider>().saveTemplate(
      saved,
      create: item == null,
    );
    if (!context.mounted) return;
    showResultMessage(context, error ?? 'Đã lưu prompt.', error: error != null);
  }
}

class _GearAdminTab extends StatelessWidget {
  const _GearAdminTab();
  @override
  Widget build(BuildContext context) => Consumer<GearPriceProvider>(
    builder: (context, provider, _) => _AdminListShell(
      title: 'Chỉ mục MSRP',
      count: provider.adminProducts.length,
      onAdd: () => _editGear(context),
      empty: provider.adminProducts.isEmpty,
      emptyMessage: 'Chưa có thiết bị trong bảng giá.',
      children: [
        for (final item in provider.adminProducts)
          _AdminRow(
            title: item.displayName,
            subtitle:
                '${item.category} · ${formatVnd(item.msrp)} · ${(item.annualDepreciation * 100).round()}%/năm · ${item.isActive ? 'Đang dùng' : 'Tạm ẩn'}',
            leading: Icons.price_check_rounded,
            onEdit: () => _editGear(context, item),
            onDelete: () => _delete(
              context,
              'Xóa thiết bị khỏi bảng giá?',
              () => provider.deleteProduct(item.id),
            ),
          ),
      ],
    ),
  );

  Future<void> _editGear(BuildContext context, [GearProduct? item]) async {
    final category = TextEditingController(text: item?.category ?? 'Laptop');
    final brand = TextEditingController(text: item?.brand);
    final model = TextEditingController(text: item?.model);
    final msrp = TextEditingController(text: '${item?.msrp.round() ?? 0}');
    final depreciation = TextEditingController(
      text: '${((item?.annualDepreciation ?? .2) * 100).round()}',
    );
    final specs = TextEditingController(
      text: item?.specs.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('\n'),
    );
    var active = item?.isActive ?? true;
    final saved = await showDialog<GearProduct>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(item == null ? 'Thêm thiết bị' : 'Sửa chỉ mục giá'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: category,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: brand,
                    decoration: const InputDecoration(labelText: 'Hãng'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: model,
                    decoration: const InputDecoration(labelText: 'Model'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: msrp,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'MSRP (₫)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: depreciation,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Khấu hao %/năm',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: specs,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Thông số (mỗi dòng key=value)',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Đang hoạt động'),
                    value: active,
                    onChanged: (value) => setLocal(() => active = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final parsedMsrp = double.tryParse(msrp.text);
                final parsedDepreciation = double.tryParse(depreciation.text);
                if (category.text.trim().isEmpty ||
                    brand.text.trim().isEmpty ||
                    model.text.trim().isEmpty ||
                    parsedMsrp == null ||
                    parsedMsrp < 0 ||
                    parsedDepreciation == null ||
                    parsedDepreciation < 0 ||
                    parsedDepreciation > 100) {
                  showResultMessage(
                    context,
                    'Danh mục, hãng, model, MSRP và khấu hao phải hợp lệ.',
                    error: true,
                  );
                  return;
                }
                final now = DateTime.now();
                Navigator.pop(
                  dialogContext,
                  GearProduct(
                    id: item?.id ?? LocalDatabase.newId('gear-product'),
                    category: category.text.trim(),
                    brand: brand.text.trim(),
                    model: model.text.trim(),
                    msrp: parsedMsrp,
                    annualDepreciation: parsedDepreciation / 100,
                    specs: _parseSpecs(specs.text),
                    isActive: active,
                    createdAt: item?.createdAt ?? now,
                    updatedAt: now,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    for (final controller in [
      category,
      brand,
      model,
      msrp,
      depreciation,
      specs,
    ]) {
      controller.dispose();
    }
    if (saved == null || !context.mounted) return;
    final error = await context.read<GearPriceProvider>().saveProduct(
      saved,
      create: item == null,
    );
    if (!context.mounted) return;
    showResultMessage(
      context,
      error ?? 'Đã lưu chỉ mục giá.',
      error: error != null,
    );
  }
}

class _AdminListShell extends StatelessWidget {
  const _AdminListShell({
    required this.title,
    required this.count,
    required this.onAdd,
    required this.empty,
    required this.emptyMessage,
    required this.children,
  });
  final String title;
  final int count;
  final VoidCallback onAdd;
  final bool empty;
  final String emptyMessage;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ResponsivePage(
    maxWidth: 900,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: SectionTitle(
            title: title,
            subtitle: '$count bản ghi',
            trailing: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm'),
            ),
          ),
        ),
        Expanded(
          child: empty
              ? EmptyStateWidget(
                  icon: Icons.inbox_outlined,
                  title: 'Danh sách trống',
                  message: emptyMessage,
                  actionLabel: 'Thêm mới',
                  onAction: onAdd,
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
                  children: children,
                ),
        ),
      ],
    ),
  );
}

class _AdminRow extends StatelessWidget {
  const _AdminRow({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onEdit,
    required this.onDelete,
  });
  final String title;
  final String subtitle;
  final IconData leading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: moduleSurface(context, AppColors.indigo),
        child: Icon(leading, color: AppColors.indigo),
      ),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: onEdit,
      trailing: PopupMenuButton<String>(
        onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Sửa')),
          PopupMenuItem(value: 'delete', child: Text('Xóa')),
        ],
      ),
    ),
  );
}

Future<void> _delete(
  BuildContext context,
  String title,
  Future<String?> Function() action,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: const Text(
        'Thao tác này có thể chuyển bản ghi sang trạng thái tạm ẩn nếu đang được sử dụng.',
      ),
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
  final error = await action();
  if (!context.mounted) return;
  showResultMessage(
    context,
    error ?? 'Đã cập nhật dữ liệu.',
    error: error != null,
  );
}

Map<String, String> _parseSpecs(String raw) {
  final result = <String, String>{};
  for (final line in raw.split('\n')) {
    final separator = line.indexOf('=');
    if (separator <= 0) continue;
    final key = line.substring(0, separator).trim();
    final value = line.substring(separator + 1).trim();
    if (key.isNotEmpty && value.isNotEmpty) result[key] = value;
  }
  return result;
}
