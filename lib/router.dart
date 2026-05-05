import 'package:go_router/go_router.dart';
import 'screens/serie_list_screen.dart';
import 'screens/serie_detail_screen.dart';
import 'screens/favoris_screen.dart';
import 'screens/watchlist_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SerieListScreen(),
      routes: [
        GoRoute(
          path: 'serie/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return SerieDetailScreen(serieId: id);
          },
        ),
        GoRoute(
          path: 'favoris',
          builder: (context, state) => const FavorisScreen(),
        ),
        GoRoute(
          path: 'watchlist',
          builder: (context, state) => const WatchlistScreen(),
        ),
      ],
    ),
  ],
);
