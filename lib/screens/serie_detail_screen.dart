import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/serie.dart';
import '../providers/serie_provider.dart';
import '../providers/favoris_provider.dart';
import '../providers/watchlist_provider.dart';

class SerieDetailScreen extends StatelessWidget {
  final int serieId;

  const SerieDetailScreen({super.key, required this.serieId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail')),
      body: FutureBuilder<Serie>(
        future: context.read<SerieProvider>().fetchSerieById(serieId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          final serie = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (serie.imageUrl != null)
                  Center(child: Image.network(serie.imageUrl!, height: 200)),
                const SizedBox(height: 16),
                Text(serie.nom, style: Theme.of(context).textTheme.headlineSmall),
                Text('${serie.genre} · ${serie.statut}'),
                if (serie.note != null) Text('★ ${serie.note!.toStringAsFixed(1)}'),
                const SizedBox(height: 8),
                Text(serie.synopsis),
                const SizedBox(height: 16),
                // Bouton favoris
                Consumer<FavorisProvider>(
                  builder: (context, favorisProvider, _) {
                    final estFavori = favorisProvider.estFavori(serie.id);
                    return ElevatedButton.icon(
                      onPressed: () => favorisProvider.toggleFavori(serie),
                      icon: Icon(estFavori ? Icons.favorite : Icons.favorite_border),
                      label: Text(estFavori ? 'Retirer des favoris' : 'Ajouter aux favoris'),
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Bouton watchlist
                Consumer<WatchlistProvider>(
                  builder: (context, watchlistProvider, _) {
                    final estPresente = watchlistProvider.estDansWatchlist(serie.id);
                    return ElevatedButton.icon(
                      onPressed: () {
                        if (estPresente) {
                          watchlistProvider.retirerSerie(serie.id);
                        } else {
                          watchlistProvider.ajouterASerie(serie);
                        }
                      },
                      icon: Icon(estPresente ? Icons.bookmark : Icons.bookmark_border),
                      label: Text(estPresente
                          ? 'Retirer de la watchlist'
                          : 'Ajouter à la watchlist'),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
