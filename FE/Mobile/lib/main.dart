import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/community_provider.dart';
import 'data/providers/chat_provider.dart';
import 'data/providers/settings_provider.dart';
import 'data/providers/search_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, AuthProvider>(
          create: (_) => AuthProvider(),
          update: (_, settings, auth) =>
              (auth ?? AuthProvider())
                ..setLanguage(settings.locale.languageCode),
        ),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          SettingsProvider,
          CommunityProvider
        >(
          create: (_) => CommunityProvider(),
          update: (_, auth, settings, community) =>
              (community ?? CommunityProvider())
                ..updateSession(auth.session)
                ..setLanguage(settings.locale.languageCode),
        ),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          SettingsProvider,
          ChatProvider
        >(
          create: (_) => ChatProvider(),
          update: (_, auth, settings, chat) => (chat ?? ChatProvider())
            ..updateSession(auth.session)
            ..setLanguage(settings.locale.languageCode),
        ),
      ],
      child: const TechNetApp(),
    );
  }
}

class TechNetApp extends StatefulWidget {
  const TechNetApp({super.key});

  @override
  State<TechNetApp> createState() => _TechNetAppState();
}

class _TechNetAppState extends State<TechNetApp> {
  AppRouter? _appRouter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appRouter ??= AppRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp.router(
      title: 'TechNet',
      locale: settings.locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: _appRouter!.router,
    );
  }
}
