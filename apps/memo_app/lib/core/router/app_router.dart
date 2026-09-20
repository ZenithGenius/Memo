import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memo/features/board/presentation/board_screen.dart';
import 'package:memo/features/catalog/presentation/category_screen.dart';
import 'package:memo/features/catalog/presentation/home_screen.dart';
import 'package:memo/features/favorites/presentation/favorites_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
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
  );
});
