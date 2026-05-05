import 'package:serie_liste/models/serie.dart';

final testSerie1 = Serie(
  id: 1,
  nom: 'Breaking Bad',
  synopsis: 'Un professeur de chimie fabrique de la drogue.',
  genre: 'Drama',
  imageUrl: 'https://example.com/bb.jpg',
  note: 9.5,
  statut: 'Ended',
);

final testSerie2 = Serie(
  id: 2,
  nom: 'Stranger Things',
  synopsis: 'Des enfants explorent un monde parallèle.',
  genre: 'Science-Fiction',
  imageUrl: 'https://example.com/st.jpg',
  note: 8.7,
  statut: 'Running',
);

final mockSeriesJson = [
  {
    'id': 1,
    'name': 'Breaking Bad',
    'genres': ['Drama'],
    'status': 'Ended',
    'image': {'medium': 'https://example.com/bb.jpg'},
    'summary': '<p>Un professeur de chimie fabrique de la drogue.</p>',
    'rating': {'average': 9.5},
  },
  {
    'id': 2,
    'name': 'Stranger Things',
    'genres': ['Science-Fiction'],
    'status': 'Running',
    'image': {'medium': 'https://example.com/st.jpg'},
    'summary': '<p>Des enfants explorent un monde parallèle.</p>',
    'rating': {'average': 8.7},
  },
];
