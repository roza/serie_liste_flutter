// User story Marie : ouvre l'app, consulte le détail d'une série,
// l'ajoute aux favoris et à la watchlist, change le statut.
//
// Couvre simultanément : 4 écrans, 3 providers, GoRouter et la chaîne
// d'injection de dépendance avec 3 fakes en mémoire (pas d'I/O réelle,
// le clock simulé de testWidgets ne supporte pas SQLite/FFI).
// Sinon il faut faire un test avec une vraie BD et un device pour lancer l'app

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:serie_liste/models/watchlist_item.dart';
import 'package:serie_liste/providers/favoris_provider.dart';
import 'package:serie_liste/providers/serie_provider.dart';
import 'package:serie_liste/providers/watchlist_provider.dart';
import 'package:serie_liste/router.dart';
import 'package:serie_liste/services/serie_api_service.dart';
import 'package:serie_liste/services/watchlist_database_service.dart';
import '../mocks/mock_preferences_service.dart';

final _seriesJson = [
  {
    'id': 1,
    'name': 'Breaking Bad',
    'genres': ['Drama'],
    'status': 'Ended',
    'summary': '<p>Un professeur de chimie.</p>',
    'rating': {'average': 9.5},
  },
  {
    'id': 2,
    'name': 'Stranger Things',
    'genres': ['Science-Fiction'],
    'status': 'Running',
    'summary': '<p>Monde parallèle.</p>',
    'rating': {'average': 8.7},
  },
];

class _TvmazeMockHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final detail = RegExp(r'^/shows/(\d+)$').firstMatch(request.url.path);
    final dynamic body = detail != null
        ? _seriesJson.firstWhere((s) => s['id'] == int.parse(detail.group(1)!))
        : _seriesJson;
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

// Substitut en mémoire — évite SQLite/FFI sous le clock simulé de testWidgets
class _InMemoryWatchlistDb extends WatchlistDatabaseService {
  final List<WatchlistItem> _items = [];

  @override
  Future<List<WatchlistItem>> getWatchlist() async => List.from(_items);

  @override
  Future<void> saveWatchlist(List<WatchlistItem> items) async {
    _items
      ..clear()
      ..addAll(items);
  }

  @override
  Future<void> clearWatchlist() async => _items.clear();

  @override
  Future<void> close() async {}
}

// Pump multiple frames pour drainer les microtâches (mock HTTP), terminer
// les transitions de page (~300ms) et laisser la route précédente se
// disposer complètement. Pas de pumpAndSettle car le CircularProgressIndicator
// ferait boucler indéfiniment.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'parcours utilisateur : liste → détail → favoris + watchlist → changement de statut',
    (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => SerieProvider(
                apiService: SerieApiService(client: _TvmazeMockHttpClient()),
              ),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  FavorisProvider(prefsService: MockPreferencesService()),
            ),
            ChangeNotifierProvider(
              create: (_) => WatchlistProvider(dbService: _InMemoryWatchlistDb()),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await _settle(tester);

      // 1. Liste affichée
      expect(find.text('SérieListe'), findsOneWidget);
      expect(find.text('Breaking Bad'), findsOneWidget);
      expect(find.text('Stranger Things'), findsOneWidget);

      // 2. Tap → détail
      await tester.tap(find.text('Breaking Bad'));
      await _settle(tester);
      expect(find.text('Détail'), findsOneWidget);
      expect(find.text('Ajouter aux favoris'), findsOneWidget);

      // 3. Ajout favoris
      await tester.tap(find.text('Ajouter aux favoris'));
      await _settle(tester);
      expect(find.text('Retirer des favoris'), findsOneWidget);

      // 4. Ajout watchlist
      await tester.tap(find.text('Ajouter à la watchlist'));
      await _settle(tester);
      expect(find.text('Retirer de la watchlist'), findsOneWidget);

      // 5. Retour liste : badge "1" sur l'icône watchlist
      await tester.pageBack();
      await _settle(tester);
      expect(find.text('SérieListe'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // 6. Favoris
      await tester.tap(find.byIcon(Icons.favorite));
      await _settle(tester);
      expect(find.text('Mes favoris'), findsOneWidget);
      expect(find.text('Breaking Bad'), findsOneWidget);

      // 7. Watchlist
      await tester.pageBack();
      await _settle(tester);
      await tester.tap(find.byIcon(Icons.bookmark));
      await _settle(tester);
      expect(find.text('Ma Watchlist'), findsOneWidget);
      expect(find.text('Breaking Bad'), findsOneWidget);

      // 8. Changement de statut : À voir → En cours
      await tester.tap(find.byType(DropdownButton<StatutVisionnage>));
      await _settle(tester);
      await tester.tap(find.text('En cours').last);
      await _settle(tester);
      expect(find.text('En cours'), findsWidgets);
    },
  );
}
