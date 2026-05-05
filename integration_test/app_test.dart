// Test d'intégration end-to-end : lance la vraie app sur un device,
// avec vraie API TVMaze, vraie SharedPreferences, vraie SQLite.
//
// À lancer sur desktop (macOS, Windows, Linux), pas sur Chrome :
//   flutter test integration_test/ -d macos
//
// La persistance étant réelle, on nettoie SharedPreferences et la BD
// avant chaque test pour qu'il soit rejouable.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:serie_liste/main.dart' as app;
import 'package:serie_liste/models/watchlist_item.dart';
import 'package:serie_liste/services/watchlist_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final db = WatchlistDatabaseService();
    await db.clearWatchlist();
    await db.close();
  });

  testWidgets(
    'parcours utilisateur end-to-end : favoris + watchlist + statut',
    (tester) async {
      app.main();

      // Attendre que TVMaze réponde (vraie requête HTTP)
      await tester.pump();
      await Future<void>.delayed(const Duration(seconds: 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 1. Liste affichée
      expect(find.text('SérieListe'), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);

      // 2. Tap sur la première série (le nom dépend de l'API, on le capture)
      final firstTile = find.byType(ListTile).first;
      final firstTitle =
          (tester.widget<ListTile>(firstTile).title! as Text).data!;
      await tester.tap(firstTile);

      // Attendre le détail (FutureBuilder + image réseau)
      await tester.pump();
      await Future<void>.delayed(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Détail'), findsOneWidget);
      expect(find.text('Ajouter aux favoris'), findsOneWidget);

      // 3. Ajout favoris
      await tester.tap(find.text('Ajouter aux favoris'));
      await tester.pumpAndSettle();
      expect(find.text('Retirer des favoris'), findsOneWidget);

      // 4. Ajout watchlist
      await tester.tap(find.text('Ajouter à la watchlist'));
      await tester.pumpAndSettle();
      expect(find.text('Retirer de la watchlist'), findsOneWidget);

      // 5. Retour liste : badge "1"
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('SérieListe'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // 6. Favoris
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();
      expect(find.text('Mes favoris'), findsOneWidget);
      expect(find.text(firstTitle), findsOneWidget);

      // 7. Watchlist
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pumpAndSettle();
      expect(find.text('Ma Watchlist'), findsOneWidget);
      expect(find.text(firstTitle), findsOneWidget);

      // 8. Changement de statut : À voir → En cours
      await tester.tap(find.byType(DropdownButton<StatutVisionnage>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('En cours').last);
      await tester.pumpAndSettle();
      expect(find.text('En cours'), findsWidgets);
    },
  );
}
