import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/app_copy.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final session = auth.session;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final copy = AppCopy.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: TechNetGradientHeader(
              title: copy.profile,
              subtitle: session?.email ?? copy.member,
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsivePage(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        UserAvatar(
                          label: auth.displayName,
                          imageUrl: session?.avatarUrl,
                          radius: 34,
                          accent: AppColors.coral,
                        ),
                        const SizedBox(width: 17),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.displayName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                session?.isGuest == true
                                    ? copy.exploreMode
                                    : session?.bio?.isNotEmpty == true
                                    ? session!.bio!
                                    : session?.email ?? copy.member,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: copy.editProfile,
                          onPressed: () => _editProfile(context),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsivePage(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                child: Text(
                  copy.app,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsivePage(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: Card(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: dark,
                        onChanged: settings.toggleTheme,
                        secondary: Icon(
                          dark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                        ),
                        title: Text(copy.darkMode),
                        subtitle: Text(copy.darkModeHint),
                      ),
                      const Divider(height: 1, indent: 64),
                      ListTile(
                        leading: const Icon(Icons.translate_rounded),
                        title: Text(copy.language),
                        subtitle: Text(
                          settings.isEnglish ? 'English' : 'Tiếng Việt',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _chooseLanguage(context, settings),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsivePage(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  22,
                  22,
                  MediaQuery.paddingOf(context).bottom + 110,
                ),
                child: OutlinedButton.icon(
                  onPressed: auth.logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Text(copy.signOut),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final copy = AppCopy.of(context);
    if (auth.session?.isGuest == true) {
      showResultMessage(context, copy.loginToEdit, error: true);
      return;
    }

    final name = TextEditingController(text: auth.displayName);
    final bio = TextEditingController(text: auth.session?.bio);
    var avatarUrl = auth.session?.avatarUrl ?? '';
    var avatarName = '';
    var uploading = false;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            22,
            22,
            MediaQuery.viewInsetsOf(context).bottom + 22,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  copy.editProfile,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                Center(
                  child: UserAvatar(
                    label: name.text,
                    imageUrl: avatarUrl,
                    radius: 46,
                    accent: AppColors.coral,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: uploading || saving
                      ? null
                      : () async {
                          final image = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 88,
                            maxWidth: 1200,
                          );
                          if (image == null) return;
                          setSheetState(() => uploading = true);
                          final result = await auth.uploadAvatar(
                            fileName: image.name,
                            filePath: image.path,
                            bytes: await image.readAsBytes(),
                          );
                          if (!sheetContext.mounted) return;
                          setSheetState(() => uploading = false);
                          if (result == null || result.isEmpty) {
                            showResultMessage(
                              sheetContext,
                              copy.uploadFailed,
                              error: true,
                            );
                          } else {
                            setSheetState(() {
                              avatarUrl = result;
                              avatarName = image.name;
                            });
                          }
                        },
                  icon: uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    avatarName.isEmpty ? copy.chooseImage : avatarName,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  enabled: !saving,
                  decoration: InputDecoration(labelText: copy.displayName),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bio,
                  enabled: !saving,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: copy.bio),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: saving || uploading
                      ? null
                      : () async {
                          setSheetState(() => saving = true);
                          final error = await auth.updateProfile(
                            displayName: name.text,
                            bio: bio.text,
                            avatarUrl: avatarUrl,
                          );
                          if (!sheetContext.mounted) return;
                          if (error == null) {
                            Navigator.pop(sheetContext);
                            showResultMessage(context, copy.profileUpdated);
                          } else {
                            setSheetState(() => saving = false);
                            showResultMessage(sheetContext, error, error: true);
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
                    padding: EdgeInsets.symmetric(vertical: 13),
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
    bio.dispose();
  }

  Future<void> _chooseLanguage(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final code = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: RadioGroup<String>(
          groupValue: settings.locale.languageCode,
          onChanged: (value) => Navigator.pop(sheetContext, value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              RadioListTile<String>(value: 'vi', title: Text('Tiếng Việt')),
              RadioListTile<String>(value: 'en', title: Text('English')),
            ],
          ),
        ),
      ),
    );
    if (code != null) await settings.setLanguage(code);
  }
}
