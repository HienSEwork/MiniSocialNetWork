import 'package:go_router/go_router.dart';

import '../data/providers/auth_provider.dart';
import '../ui/screens/chat_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/main_layout.dart';
import '../ui/screens/marketplace_screen.dart';
import '../ui/screens/register_screen.dart';
import '../ui/screens/search_screen.dart';
import '../ui/screens/splash_screen.dart';

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
      GoRoute(
        path: '/marketplace',
        builder: (_, __) => const MarketplaceScreen(),
      ),
      GoRoute(path: '/', builder: (_, __) => const MainLayout()),
    ],
  );
}
