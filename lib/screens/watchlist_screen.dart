import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/watchlist_item.dart';
import '../providers/watchlist_provider.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ma Watchlist')),
      body: Consumer<WatchlistProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.items.isEmpty) {
            return const Center(child: Text('Votre watchlist est vide.'));
          }
          return ListView.builder(
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final item = provider.items[index];
              return ListTile(
                leading: item.serie.imageUrl != null
                    ? Image.network(item.serie.imageUrl!, width: 50)
                    : const Icon(Icons.tv),
                title: Text(item.serie.nom),
                subtitle: Text(item.statut.label),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<StatutVisionnage>(
                      value: item.statut,
                      underline: const SizedBox(),
                      items: StatutVisionnage.values
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                          .toList(),
                      onChanged: (statut) {
                        if (statut != null) provider.changerStatut(item.serie.id, statut);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => provider.retirerSerie(item.serie.id),
                    ),
                  ],
                ),
                onTap: () => context.go('/serie/${item.serie.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
