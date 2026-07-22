import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/ai_library_provider.dart';
import 'data/providers/community_provider.dart';
import 'data/providers/chat_provider.dart';
import 'data/providers/gear_price_provider.dart';
import 'data/providers/pc_builder_provider.dart';
import 'data/providers/settings_provider.dart';
import 'data/providers/search_provider.dart';
import 'data/providers/trivia_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

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
        ChangeNotifierProxyProvider<AuthProvider, TriviaProvider>(
          create: (_) => TriviaProvider(),
          update: (_, auth, provider) =>
              (provider ?? TriviaProvider())..updateSession(auth.session),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PcBuilderProvider>(
          create: (_) => PcBuilderProvider(),
          update: (_, auth, provider) =>
              (provider ?? PcBuilderProvider())..updateSession(auth.session),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AiLibraryProvider>(
          create: (_) => AiLibraryProvider(),
          update: (_, auth, provider) =>
              (provider ?? AiLibraryProvider())..updateSession(auth.session),
        ),
        ChangeNotifierProxyProvider<AuthProvider, GearPriceProvider>(
          create: (_) => GearPriceProvider(),
          update: (_, auth, provider) =>
              (provider ?? GearPriceProvider())..updateSession(auth.session),
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
