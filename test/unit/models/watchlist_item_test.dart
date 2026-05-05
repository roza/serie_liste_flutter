import 'package:flutter_test/flutter_test.dart';
import 'package:serie_liste/models/watchlist_item.dart';
import '../../helpers/test_data.dart';

void main() {
  group('WatchlistItem', () {
    test('statut par défaut est À voir', () {
      final item = WatchlistItem(serie: testSerie1);
      expect(item.statut, StatutVisionnage.aVoir);
    });

    test('toJson / fromJson sont symétriques', () {
      final original = WatchlistItem(serie: testSerie1, statut: StatutVisionnage.enCours);
      final reconstruit = WatchlistItem.fromJson(original.toJson());

      expect(reconstruit.serie.id, original.serie.id);
      expect(reconstruit.statut, StatutVisionnage.enCours);
    });

    test('label du statut est lisible', () {
      expect(StatutVisionnage.aVoir.label, 'À voir');
      expect(StatutVisionnage.enCours.label, 'En cours');
      expect(StatutVisionnage.vu.label, 'Vu');
    });
  });
}
