import 'package:go_router/go_router.dart';

import '../data/providers/auth_provider.dart';
import '../ui/screens/admin_screen.dart';
import '../ui/screens/ai_library_screen.dart';
import '../ui/screens/chat_screen.dart';
import '../ui/screens/daily_quest_screen.dart';
import '../ui/screens/friends_screen.dart';
import '../ui/screens/gear_price_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/main_layout.dart';
import '../ui/screens/marketplace_screen.dart';
import '../ui/screens/pc_builder_screen.dart';
import '../ui/screens/register_screen.dart';
import '../ui/screens/search_screen.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/tech_modules_admin_screen.dart';

class AppRouter {
  AppRouter(this.authProvider);

  final AuthProvider authProvider;

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final onAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final onSplash = state.matchedLocation == '/splash';

      if (!authProvider.isInitialized) return onSplash ? null : '/splash';
      if (!authProvider.isAuthenticated) {
        return onAuthPage ? null : '/login';
      }
      if (onAuthPage || onSplash) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
      GoRoute(path: '/friends', builder: (_, __) => const FriendsScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
      GoRoute(
        path: '/admin/tech-modules',
        builder: (_, __) => const TechModulesAdminScreen(),
      ),
      GoRoute(
        path: '/daily-quest',
        builder: (_, __) => const DailyQuestScreen(),
      ),
      GoRoute(path: '/pc-builder', builder: (_, __) => const PcBuilderScreen()),
      GoRoute(path: '/ai-library', builder: (_, __) => const AiLibraryScreen()),
      GoRoute(path: '/gear-price', builder: (_, __) => const GearPriceScreen()),
      GoRoute(
        path: '/marketplace',
        builder: (_, __) => const MarketplaceScreen(),
      ),
      GoRoute(path: '/', builder: (_, __) => const MainLayout()),
    ],
  );
}
