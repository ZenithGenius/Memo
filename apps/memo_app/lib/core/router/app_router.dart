import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memo/core/shell/app_shell.dart';
import 'package:memo/features/board/presentation/board_screen.dart';
import 'package:memo/features/catalog/presentation/catalog_providers.dart';
import 'package:memo/features/catalog/presentation/category_screen.dart';
import 'package:memo/features/catalog/presentation/home_screen.dart';
import 'package:memo/features/favorites/presentation/favorites_screen.dart';
import 'package:memo/features/onboarding/presentation/onboarding_screen.dart';
import 'package:memo/features/phrases/presentation/phrases_screen.dart';
import 'package:memo/features/settings/presentation/settings_screen.dart';
import 'package:memo/features/stats/presentation/words_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(activeProfileProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final profile = ref.read(activeProfileProvider);
      if (profile.isLoading) return null;
      final hasProfile = profile.value != null;
      final onboarding = state.matchedLocation == '/onboarding';
      if (!hasProfile && !onboarding) return '/onboarding';
      if (hasProfile && onboarding) return '/';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          // Parler : catégories, puis pictogrammes, favoris et tableau.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => HomeScreen(
                  onOpenCategory: (code) => context.push('/category/$code'),
                  onOpenFavorites: () => context.push('/favorites'),
                  onOpenBoard: () => context.push('/board'),
                ),
                routes: [
                  GoRoute(
                    path: 'category/:code',
                    builder: (context, state) =>
                        CategoryScreen(code: state.pathParameters['code']!),
                  ),
                  GoRoute(
                    path: 'favorites',
                    builder: (context, state) => const FavoritesScreen(),
                  ),
                  GoRoute(
                    path: 'board',
                    builder: (context, state) => const BoardScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/phrases',
                builder: (context, state) => const PhrasesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/words',
                builder: (context, state) => const WordsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});
