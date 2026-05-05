import 'package:flutter_test/flutter_test.dart';
import 'package:serie_liste/models/serie.dart';

void main() {
  group('Serie', () {
    final jsonComplet = {
      'id': 1,
      'name': 'Breaking Bad',
      'genres': ['Drama', 'Crime'],
      'status': 'Ended',
      'image': {'medium': 'https://example.com/bb.jpg'},
      'summary': '<p>Un professeur de chimie…</p>',
      'rating': {'average': 9.5},
    };

    test('fromJson crée une Serie correctement', () {
      final serie = Serie.fromJson(jsonComplet);

      expect(serie.id, 1);
      expect(serie.nom, 'Breaking Bad');
      expect(serie.genre, 'Drama');
      expect(serie.statut, 'Ended');
      expect(serie.note, 9.5);
      expect(serie.imageUrl, 'https://example.com/bb.jpg');
    });

    test('fromJson supprime les balises HTML du synopsis', () {
      final serie = Serie.fromJson(jsonComplet);

      expect(serie.synopsis, 'Un professeur de chimie…');
      expect(serie.synopsis, isNot(contains('<p>')));
    });

    test('fromJson gère les champs optionnels absents', () {
      final jsonMinimal = {'id': 2, 'name': 'Test'};
      final serie = Serie.fromJson(jsonMinimal);

      expect(serie.imageUrl, isNull);
      expect(serie.note, isNull);
      expect(serie.genre, 'Inconnu');
      expect(serie.synopsis, '');
    });

    test('toJson / fromJson sont symétriques', () {
      final original = Serie.fromJson(jsonComplet);
      final reconstruit = Serie.fromJson(original.toJson());

      expect(reconstruit.id, original.id);
      expect(reconstruit.nom, original.nom);
      expect(reconstruit.note, original.note);
    });
  });
}
