# serie_liste — correction de référence du TD6

Application de suivi de séries TV : catalogue TVMaze, favoris (SharedPreferences), watchlist avec statuts (SQLite).

![Schéma architecture de l'application](architecture_globale.png "Architecture globale de l'application")

## App principale

- Étapes 1 à 9 du TD complètes (modèles, services, providers, écrans, tests).
- **les trois providers** (`SerieProvider`, `FavorisProvider`, `WatchlistProvider`) acceptent leur service via le constructeur — l'injection de dépendance est généralisée, pas seulement `WatchlistProvider`.
- Bonus : badge `itemCount` sur l'icône watchlist dans l'AppBar (`lib/screens/serie_list_screen.dart`).

## Lancer l'app et les tests

```bash
flutter pub get
flutter run                  # app
flutter test test/unit/      # 36 tests unitaires
flutter analyze              # 0 issue
```

## Différence notable avec le TD

Le TD montre `SerieProvider` et `FavorisProvider` d'abord avec leur service instancié en dur (étapes 3 et 5), puis introduit l'injection de dépendance à l'étape 8 sur `WatchlistProvider`, et propose en exercice (8.4) d'appliquer le même pattern aux deux autres providers.

Cette correction présente directement l'**état final** : injection de dépendance partout. Pour comparer avec son code étape par étape, l'étudiant doit garder à l'esprit que `serie_provider.dart` et `favoris_provider.dart` correspondent à la version de l'étape 8.4, pas à celle des étapes 3 et 5.

Tests correspondants présents :

- `test/unit/providers/serie_provider_test.dart` — utilise l'injection de dépendance (`MockHttpClient`)
- `test/unit/providers/favoris_provider_test.dart` — utilise l'injection de dépendance (`MockPreferencesService`)
- `test/unit/providers/watchlist_provider_test.dart` — version complétée des `// TODO` du starter

## Couverture des tests

Flutter génère un rapport au format `lcov` avec l'option `--coverage`. Les paquets `lcov` et `genhtml` (sur macOS : `brew install lcov` ou `port install lcov`) permettent ensuite d'obtenir un résumé textuel ou HTML.

```bash
# 1. Générer lcov.info pour tous les tests unitaires
flutter test --coverage test/unit/

# 2. Résumé global
lcov --summary coverage/lcov.info

# 3. Détail par fichier
lcov --list coverage/lcov.info

# 4. Rapport HTML navigable (lignes vertes/rouges)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html       # Linux : xdg-open

# 5. Couverture d'un seul fichier de test (utile pour cibler une étape)
flutter test --coverage test/unit/services/watchlist_database_service_test.dart
lcov --list coverage/lcov.info
```

### Résultat attendu

Avec les tests fournis, la couche métier est couverte à environ **86 %** :

| Fichier | Couverture |
|---|---|
| `services/watchlist_database_service.dart` | 100 % |
| `providers/watchlist_provider.dart` | ~94 % |
| `services/serie_api_service.dart` | ~93 % |
| `models/watchlist_item.dart` | ~93 % |
| `providers/favoris_provider.dart` | ~93 % |
| `models/serie.dart` | ~87 % |
| `providers/serie_provider.dart` | ~87 % |
| `services/preferences_service.dart` | 0 % (voir note) |

> **Note** : le 0 % sur `preferences_service.dart` n'est pas un trou de qualité — les tests passent par `MockPreferencesService`, qui hérite et surcharge `getFavoris`/`saveFavoris`. Le code de production n'est donc jamais exécuté pendant les tests.

Les fichiers UI (`main.dart`, `router.dart`, `lib/screens/*.dart`) n'apparaissent pas dans le rapport : ils ne sont chargés par aucun test unitaire. Les couvrir nécessiterait des *widget tests* ou des tests d'intégration, hors périmètre du TD6 mais que vous pouvez ajouter à votre projet.

Par exemple, un test de parcours utilisateur ([`test/integration/user_journey_test.dart`](test/integration/user_journey_test.dart)) qui exécute la *user story* suivante :

> **Marie** ouvre SérieListe : elle voit la liste des séries, tape sur *Breaking Bad* pour consulter le détail, l'ajoute aux favoris puis à la watchlist. Elle revient à l'accueil — un badge `1` apparaît sur l'icône watchlist. Elle ouvre l'écran des favoris pour vérifier que *Breaking Bad* y figure, puis l'écran de la watchlist où elle change le statut de visionnage de « À voir » à « En cours ».

Ce seul test exerce simultanément les 4 écrans, les 3 providers, le routeur GoRouter et la chaîne complète d'injection de dépendance — `MockHttpClient` (custom, qui route `/shows` vs `/shows/<id>`) + `MockPreferencesService` + SQLite in-memory.

```bash
flutter test --coverage test/                # unitaires + intégration
lcov --list coverage/lcov.info
```

Avec ce test ajouté, `lib/screens/*.dart` et `lib/router.dart` apparaissent dans le rapport et la couverture globale dépasse 90 %.

### Pistes pour pousser la couverture > 95 %

Sans toucher au périmètre du TD, trois ajouts permettraient d'atteindre une couverture quasi totale de la couche métier — à proposer en exercice complémentaire :

1. **`PreferencesService` testé directement** (et non via le mock). Utiliser `SharedPreferences.setMockInitialValues({})` dans `setUp` pour fournir une implémentation en mémoire au vrai service. Cible : faire passer `preferences_service.dart` de 0 % à ~100 %.
2. **Branches de fallback de `Serie.fromJson`** : tests dédiés pour les cas `nom` absent (→ 'Sans titre'), `genres` vide (→ 'Inconnu'), `status` absent (→ 'Unknown'), et le format interne (`toJson()` puis `fromJson()` avec les clés `nom`/`synopsis`/`statut`).
3. **`SerieProvider.fetchSerieById`** isolé avec `MockHttpClient` — actuellement la méthode est définie mais n'est testée qu'indirectement.
