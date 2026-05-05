import 'package:flutter_test/flutter_test.dart';
import 'package:serie_liste/providers/favoris_provider.dart';
import '../../helpers/test_data.dart';
import '../../mocks/mock_preferences_service.dart';

void main() {
  group('FavorisProvider', () {
    FavorisProvider makeProvider() =>
        FavorisProvider(prefsService: MockPreferencesService());

    test('démarre avec une liste de favoris vide', () async {
      final provider = makeProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.favoris, isEmpty);
    });

    test('toggleFavori ajoute une série aux favoris', () async {
      final provider = makeProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.toggleFavori(testSerie1);

      expect(provider.favoris.length, 1);
      expect(provider.estFavori(testSerie1.id), isTrue);
    });

    test('toggleFavori retire une série déjà en favori', () async {
      final provider = makeProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      await provider.toggleFavori(testSerie1);

      await provider.toggleFavori(testSerie1);

      expect(provider.favoris, isEmpty);
      expect(provider.estFavori(testSerie1.id), isFalse);
    });

    test('estFavori retourne faux pour une série absente', () async {
      final provider = makeProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.estFavori(testSerie2.id), isFalse);
    });

    test('notifie les listeners lors d\'un toggle', () async {
      final provider = makeProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      var count = 0;
      provider.addListener(() => count++);

      await provider.toggleFavori(testSerie1);
      await provider.toggleFavori(testSerie1);

      expect(count, 2);
    });
  });
}
