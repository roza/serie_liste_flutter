import 'serie.dart';

enum StatutVisionnage {
  aVoir,
  enCours,
  vu;

  String get label => switch (this) {
    StatutVisionnage.aVoir   => 'À voir',
    StatutVisionnage.enCours => 'En cours',
    StatutVisionnage.vu      => 'Vu',
  };

  static StatutVisionnage fromString(String s) =>
      StatutVisionnage.values.firstWhere(
        (e) => e.name == s,
        orElse: () => StatutVisionnage.aVoir,
      );
}

class WatchlistItem {
  final Serie serie;
  StatutVisionnage statut;

  WatchlistItem({
    required this.serie,
    this.statut = StatutVisionnage.aVoir,
  });

  Map<String, dynamic> toJson() => {
    'serie': serie.toJson(),
    'statut': statut.name,
  };

  factory WatchlistItem.fromJson(Map<String, dynamic> json) => WatchlistItem(
    serie: Serie.fromJson(json['serie']),
    statut: StatutVisionnage.fromString(json['statut'] ?? 'aVoir'),
  );
}
