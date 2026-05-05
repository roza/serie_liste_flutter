# serie_liste — correction TD6

Application de suivi de séries TV : catalogue TVMaze, favoris (SharedPreferences), watchlist avec statuts (SQLite).

 [![tests](https://github.com/roza/serie_liste_flutter/actions/workflows/coverage.yml/badge.svg?branch=main)](https://github.com/roza/serie_liste_flutter/actions/workflows/coverage.yml)

[![codecov](https://codecov.io/gh/roza/serie_liste_flutter/branch/main/graph/badge.svg)](https://codecov.io/gh/roza/serie_liste_flutter)

![Schéma architecture de l'application](architecture_globale.png "Architecture globale de l'application")

## App principale

- Étapes 1 à 9 du TD complètes (modèles, services, providers, écrans, tests).
- **les trois providers** (`SerieProvider`, `FavorisProvider`, `WatchlistProvider`) acceptent leur service via le constructeur   (injection de dépendance).
- Bonus : badge `itemCount` sur l'icône watchlist dans l'AppBar (`lib/screens/serie_list_screen.dart`).

## Lancer l'app et les tests

```bash
flutter pub get
flutter run                                          # app
flutter test test/unit/                              # 36 tests unitaires (VM, ~2 s)
flutter test test/user_story/                        # widget test avec fakes (VM, ~1 s)
flutter test integration_test/app_test.dart -d macos # end-to-end sur device (~14 s)
flutter analyze                                      # 0 issue
```

Les trois familles de tests sont complémentaires : unitaires pour la couche métier en isolation, *user story* en widget test pour le parcours d'écran à écran, et `integration_test` pour la validation end-to-end avec vraies persistance et API.

## Différence avec le TD

Le TD montre `SerieProvider` et `FavorisProvider` d'abord avec leur service instancié en dur (étapes 3 et 5), puis introduit l'injection de dépendance à l'étape 8 sur `WatchlistProvider`, et propose ensuite d'appliquer le même pattern aux deux autres providers.

Cette correction présente directement l'**état final** : injection de dépendance partout.

Tests correspondants présents :

- `test/unit/providers/serie_provider_test.dart` — utilise l'injection de dépendance (`MockHttpClient`)
- `test/unit/providers/favoris_provider_test.dart` — utilise l'injection de dépendance (`MockPreferencesService`)
- `test/unit/providers/watchlist_provider_test.dart` — version complétée des `// TODO` du starter

## Couverture des tests

Flutter génère un rapport au format `lcov` avec l'option `--coverage`. Les paquets `lcov` et `genhtml` (lcov à installer via apt sous Linux ou WSL, via choco sous Windows, brew ou macports sous mac) permettent ensuite d'obtenir un résumé textuel ou HTML.

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

> **Remarque** : le 0 % sur `preferences_service.dart` n'est pas un trou de qualité — les tests passent par `MockPreferencesService`, qui hérite et surcharge `getFavoris`/`saveFavoris`. Le code de production n'est donc jamais exécuté pendant les tests.

Les fichiers UI (`main.dart`, `router.dart`, `lib/screens/*.dart`) n'apparaissent pas dans le rapport : ils ne sont chargés par aucun test unitaire. Les couvrir nécessiterait des *widget tests* ou des tests d'intégration que vous devez ajouter à votre projet.

Par exemple, ajouter ici un test de parcours utilisateur ([`test/user_story/user_journey_test.dart`](test/user_story/user_journey_test.dart)) qui exécute la *user story* suivante :

> **Marie** ouvre SérieListe : elle voit la liste des séries, tape sur *Breaking Bad* pour consulter le détail, l'ajoute aux favoris puis à la watchlist. Elle revient à l'accueil — un badge `1` apparaît sur l'icône watchlist. Elle ouvre l'écran des favoris pour vérifier que *Breaking Bad* y figure, puis l'écran de la watchlist où elle change le statut de visionnage de « À voir » à « En cours ».

Ce seul test utilise simultanément les 4 écrans, les 3 providers, le routeur GoRouter et la chaîne d'injection de dépendance — `MockHttpClient` (custom, qui route `/shows` vs `/shows/<id>`) + `MockPreferencesService` + SQLite (en mémoire).

On peut ensuite retester la couverture par les tests :

```bash
flutter test --coverage test/                # unitaires + intégration
lcov --list coverage/lcov.info
```

Avec ce test ajouté, `lib/screens/*.dart` et `lib/router.dart` apparaissent dans le rapport et la couverture globale dépasse 90 %.

## Test d'intégration end-to-end (non demandé dans le TD et optionnel dans le projet mais bonus possible)

Une seconde version du parcours est fournie dans `integration_test/app_test.dart`. Celle-ci lance la **vraie app** sur un device, avec **vraie API TVMaze**, **vraie SharedPreferences** et **vraie SQLite**. À utiliser sur desktop (pas sur Chrome) :

```bash
flutter test integration_test/app_test.dart -d macos    # ou -d windows / -d linux
```

Le test prend une dizaine de secondes (build de l'app + lancement + scénario), nettoie la persistance avant exécution pour être rejouable.

Pour les détails sur les deux approches (widget test avec fakes vs `integration_test` sur device), la mécanique des microtâches/`pump`, et la pyramide de tests recommandée pour SQLite, voir [`test_integration.md`](test_integration.md).

