import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_data.dart';
import '../../mocks/mock_preferences_service.dart';

void main() {
  group('PreferencesService', () {
    test('getFavoris retourne une liste vide initialement', () async {
      final service = MockPreferencesService();
      final favoris = await service.getFavoris();
      expect(favoris, isEmpty);
    });

    test('saveFavoris puis getFavoris retourne les séries sauvegardées', () async {
      final service = MockPreferencesService();
      await service.saveFavoris([testSerie1, testSerie2]);

      final favoris = await service.getFavoris();
      expect(favoris.length, 2);
      expect(favoris[0].nom, 'Breaking Bad');
    });

    test('saveFavoris remplace les données précédentes', () async {
      final service = MockPreferencesService();
      await service.saveFavoris([testSerie1, testSerie2]);
      await service.saveFavoris([testSerie1]);

      final favoris = await service.getFavoris();
      expect(favoris.length, 1);
    });
  });
}
