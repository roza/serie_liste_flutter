import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/favoris_provider.dart';

class FavorisScreen extends StatelessWidget {
  const FavorisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      body: Consumer<FavorisProvider>(
        builder: (context, provider, _) {
          if (provider.favoris.isEmpty) {
            return const Center(child: Text('Aucun favori pour l\'instant.'));
          }
          return ListView.builder(
            itemCount: provider.favoris.length,
            itemBuilder: (context, index) {
              final serie = provider.favoris[index];
              return ListTile(
                leading: serie.imageUrl != null
                    ? Image.network(serie.imageUrl!, width: 50)
                    : const Icon(Icons.tv),
                title: Text(serie.nom),
                subtitle: Text(serie.genre),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () => context.read<FavorisProvider>().toggleFavori(serie),
                ),
                onTap: () => context.go('/serie/${serie.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
