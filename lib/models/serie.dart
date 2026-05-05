class Serie {
  final int id;
  final String nom;
  final String synopsis;
  final String genre;
  final String? imageUrl;
  final double? note;
  final String statut;

  const Serie({
    required this.id,
    required this.nom,
    required this.synopsis,
    required this.genre,
    this.imageUrl,
    this.note,
    required this.statut,
  });

  /// Supprime les balises HTML du résumé TVMaze.
  static String _stripHtml(String? html) {
    if (html == null) return '';
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  factory Serie.fromJson(Map<String, dynamic> json) {
    // Supporte le format TVMaze (clés 'name', 'summary', 'genres', 'status', 'image', 'rating')
    // ET le format de stockage interne produit par toJson() (clés 'nom', 'synopsis', 'genre', etc.)
    final genres = json['genres'] as List<dynamic>?;
    return Serie(
      id: json['id'] as int,
      nom: json['name'] as String? ?? json['nom'] as String? ?? 'Sans titre',
      synopsis: json['summary'] != null
          ? _stripHtml(json['summary'] as String?)
          : json['synopsis'] as String? ?? '',
      genre: genres != null && genres.isNotEmpty
          ? genres[0] as String
          : json['genre'] as String? ?? 'Inconnu',
      imageUrl: json['image']?['medium'] as String? ?? json['imageUrl'] as String?,
      note: (json['rating']?['average'] as num?)?.toDouble()
          ?? (json['note'] as num?)?.toDouble(),
      statut: json['status'] as String? ?? json['statut'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'synopsis': synopsis,
    'genre': genre,
    'imageUrl': imageUrl,
    'note': note,
    'statut': statut,
  };

  @override
  bool operator ==(Object other) => other is Serie && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
