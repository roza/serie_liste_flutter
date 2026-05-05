import 'package:flutter_test/flutter_test.dart';
import 'package:serie_liste/models/watchlist_item.dart';
import 'package:serie_liste/providers/watchlist_provider.dart';
import 'package:serie_liste/services/watchlist_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../helpers/test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WatchlistProvider', () {
    late WatchlistDatabaseService dbService;

    setUp(() async {
      dbService = WatchlistDatabaseService(databasePath: inMemoryDatabasePath);
      await dbService.clearWatchlist();
    });

    tearDown(() async => dbService.close());

    WatchlistProvider makeProvider() => WatchlistProvider(dbService: dbService);

    test('démarre avec une watchlist vide', () async {
      final provider = makeProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.items, isEmpty);
      expect(provider.itemCount, 0);
      expect(provider.isLoading, isFalse);
    });

    test('ajouterASerie ajoute une série', () async {
      final provider = makeProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.ajouterASerie(testSerie1);

      expect(provider.items.length, 1);
      expect(provider.items.first.serie.nom, 'Breaking Bad');
      expect(provider.items.first.statut, StatutVisionnage.aVoir);
    });

    test('ajouterASerie ne duplique pas une série déjà présente', () async {
      final provider = makeProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.ajouterASerie(testSerie1);
      await provider.ajouterASerie(testSerie1);

      expect(provider.items.length, 1);
    });

    test('retirerSerie supprime la série', () async {
      final provider = makeProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      await provider.ajouterASerie(testSerie1);
      await provider.ajouterASerie(testSerie2);

      await provider.retirerSerie(testSerie1.id);

      expect(provider.items.length, 1);
      expect(provider.items.first.serie.nom, 'Stranger Things');
    });

    test('changerStatut met à jour le statut', () async {
      final provider = makeProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      await provider.ajouterASerie(testSerie1);

      await provider.changerStatut(testSerie1.id, StatutVisionnage.enCours);

      expect(provider.getStatut(testSerie1.id), StatutVisionnage.enCours);
    });

    test('estDansWatchlist retourne vrai si présente', () async {
      final provider = makeProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      await provider.ajouterASerie(testSerie1);

      expect(provider.estDansWatchlist(testSerie1.id), isTrue);
      expect(provider.estDansWatchlist(testSerie2.id), isFalse);
    });

    test('persistance : les données survivent à une nouvelle instance', () async {
      final provider1 = makeProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      await provider1.ajouterASerie(testSerie1);

      final provider2 = WatchlistProvider(dbService: dbService);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider2.items.length, 1);
      expect(provider2.items.first.serie.nom, 'Breaking Bad');
    });

    test('notifie les listeners à chaque modification', () async {
      final provider = makeProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      var count = 0;
      provider.addListener(() => count++);

      await provider.ajouterASerie(testSerie1);
      await provider.changerStatut(testSerie1.id, StatutVisionnage.enCours);
      await provider.retirerSerie(testSerie1.id);

      expect(count, 3);
    });
  });
}
