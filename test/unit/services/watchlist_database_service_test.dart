import 'package:flutter_test/flutter_test.dart';
import 'package:serie_liste/models/watchlist_item.dart';
import 'package:serie_liste/services/watchlist_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../helpers/test_data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WatchlistDatabaseService', () {
    late WatchlistDatabaseService service;

    setUp(() async {
      service = WatchlistDatabaseService(databasePath: inMemoryDatabasePath);
    });

    tearDown(() async => service.close());

    test('getWatchlist retourne une liste vide au départ', () async {
      final items = await service.getWatchlist();
      expect(items, isEmpty);
    });

    test('saveWatchlist puis getWatchlist retourne les items', () async {
      final items = [
        WatchlistItem(serie: testSerie1, statut: StatutVisionnage.aVoir),
        WatchlistItem(serie: testSerie2, statut: StatutVisionnage.enCours),
      ];

      await service.saveWatchlist(items);
      final loaded = await service.getWatchlist();

      expect(loaded.length, 2);
      expect(loaded[0].serie.nom, 'Breaking Bad');
      expect(loaded[1].statut, StatutVisionnage.enCours);
    });

    test('saveWatchlist remplace les données existantes', () async {
      await service.saveWatchlist([WatchlistItem(serie: testSerie1)]);
      await service.saveWatchlist([WatchlistItem(serie: testSerie2)]);

      final loaded = await service.getWatchlist();
      expect(loaded.length, 1);
      expect(loaded[0].serie.nom, 'Stranger Things');
    });

    test('clearWatchlist vide la base', () async {
      await service.saveWatchlist([WatchlistItem(serie: testSerie1)]);
      await service.clearWatchlist();

      final loaded = await service.getWatchlist();
      expect(loaded, isEmpty);
    });
  });
}
