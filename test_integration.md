# Tests d'intégration en Flutter avec persistance SQLite

Ici, on explique :

1. Comment fonctionne `tester.pump()` et la file de microtâches Dart.
2. Les deux façons concrètes de tester un parcours utilisateur qui touche à SQLite dans `testWidgets()`.
3. Quand passer au troisième niveau (`integration_test` sur device réel).

---

## 1. Préliminaires : Anatomie d'un `tester.pump()`

### 1.1 Les deux files d'attente Dart

Dart distingue deux types de tâches asynchrones :

| File | Quand est-elle drainée ? | Exemples |
|---|---|---|
| **microtask queue** | Drainée **complètement** avant chaque frame, avant les tâches normales | `Future.value(x)`, `Future.microtask`, le code après un `await` qui se résout |
| **event queue** | Drainée frame par frame, après les microtâches | `Future.delayed`, callbacks de `Timer`, événements I/O réels |

Quand un `await` reprend après s'être résolu, le code qui suit est planifié comme **microtâche**. Une chaîne d'`await` enchaînés produit une chaîne de microtâches successives.

### 1.2 Ce que fait `tester.pump([duration])`

Un `pump` n'est pas seulement un « rendu d'image ». La séquence interne est :

1. Avance le clock simulé de `duration` (ou 0 si non précisé).
2. **Draine la file de microtâches jusqu'à épuisement.**
3. Reconstruit les widgets marqués dirty (`build()`).
4. Layout, paint.

C'est l'étape 2 qui rend possible la progression du code asynchrone d'un test.

### 1.3 Pourquoi un seul `pump()` ne suffit pas pour un mock HTTP

Quand un Provider charge des données :

```dart
Future<void> fetchSeries() async {
  final response = await _client.get(uri);          // étape 1 → microtâche
  final body     = await response.bytesToString();  // étape 2 → microtâche
  _series        = parse(body);                     // étape 3 → microtâche
  notifyListeners();                                // étape 4 → schedule rebuild
}
```

Un seul `pump()` draine toutes les microtâches **actuellement en file**. Mais si à cet instant seule l'étape 1 est en file, l'étape 2 n'y arrive qu'après son traitement. Le drain s'arrête, on reconstruit l'UI, mais l'état n'est pas encore final. Il faut un nouveau `pump()` pour traiter la vague suivante.

D'où le besoin de pomper plusieurs frames pour laisser la chaîne `Future → Future → ... → notifyListeners → rebuild` se dérouler étape par étape.

### 1.4 Pourquoi `pumpAndSettle()` boucle parfois indéfiniment

`pumpAndSettle()` pompe jusqu'à ce que plus aucune frame ne soit programmée. Or un `CircularProgressIndicator` reprogramme une frame à chaque tick d'animation. Tant qu'il est à l'écran, `pumpAndSettle()` ne se termine jamais.

**Solution pratique :** un settle manuel borné, par exemple :

```dart
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
```

15 frames de 100 ms = 1,5 s de clock simulé : largement assez pour drainer les chaînes de microtâches **et** finir les transitions Material (~300 ms), sans boucler sur le loader.

---

## 2. Deux façons de tester un parcours utilisateur impliquant SQLite

Le problème : `testWidgets()` utilise un **clock simulé** (`FakeAsync`). Les vraies I/O — comme un appel à `sqflite_common_ffi` qui passe par le moteur SQLite via FFI — ne progressent pas tant qu'on n'est pas dans une zone de clock réel. Sans précaution, `pumpWidget` ne retourne jamais.

Deux approches possibles, complémentaires.

### 2.1 Approche A — Substitut en mémoire (recommandée par défaut)

On crée une sous-classe du service de BD qui surcharge les méthodes pour stocker en mémoire dans une `List`. La BD réelle n'est jamais ouverte.

```dart
class _InMemoryWatchlistDb extends WatchlistDatabaseService {
  final List<WatchlistItem> _items = [];

  @override
  Future<List<WatchlistItem>> getWatchlist() async => List.from(_items);

  @override
  Future<void> saveWatchlist(List<WatchlistItem> items) async {
    _items..clear()..addAll(items);
  }

  @override
  Future<void> clearWatchlist() async => _items.clear();

  @override
  Future<void> close() async {}
}
```

Puis on l'injecte via le constructeur du Provider :

```dart
ChangeNotifierProvider(
  create: (_) => WatchlistProvider(dbService: _InMemoryWatchlistDb()),
),
```

**Avantages**

- Très rapide (aucune I/O, même en mémoire). Le test complet tourne en 2 s.
- Pas de dépendance à `sqflite_common_ffi` dans les tests d'UI.
- Compatible avec `testWidgets()` standard, clock simulé inclus.
- Même pattern que les autres mocks du projet (`MockPreferencesService`).

**Limites**

- On ne teste pas le SQL lui-même (mais ce n'est pas le rôle d'un test d'UI — c'est normalement le rôle des tests unitaires du service de BD).
- Nécessite que le service expose une API surchargeable (méthodes publiques, pas de logique critique dans le constructeur). C'est en pratique toujours le cas dès qu'on applique l'injection de dépendance.

### 2.2 Approche B — Vraie SQLite avec `tester.runAsync`

On garde la vraie BD (`inMemoryDatabasePath`) et on enveloppe les opérations qui touchent FFI dans `tester.runAsync`, qui temporairement remplace le clock simulé par le clock réel :

```dart
late WatchlistDatabaseService dbService;

setUpAll(() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
});

testWidgets('parcours...', (tester) async {
  await tester.runAsync(() async {
    dbService = WatchlistDatabaseService(databasePath: inMemoryDatabasePath);
    await dbService.clearWatchlist();
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WatchlistProvider(dbService: dbService),
        ),
        // ...
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );

  // Chaque opération qui touche à la BD doit être enveloppée
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pump();

  // ... interactions ...

  // Nettoyage
  await tester.runAsync(() => dbService.close());
});
```

**Avantages**

- On exerce le **vrai** code SQL de bout en bout : utile si la persistance est au cœur du test (par ex. vérifier qu'un statut survit à la fermeture/réouverture de l'app).
- Pas besoin d'écrire de classe substitut.

**Limites**

- Plus lent (5-10× selon les opérations).
- `pumpAndSettle` ne fonctionne pas correctement à travers les frontières `runAsync`/clock simulé : il faut alterner manuellement `runAsync(...)` (pour laisser FFI avancer) et `pump()` (pour reconstruire l'UI). C'est fastidieux et l'erreur est facile.
- Le résultat est sensible aux durées choisies dans `Future.delayed(...)` — risque de tests *flaky*.

### 2.3 Quand choisir laquelle ?

| Tu cherches à valider… | Approche |
|---|---|
| Le parcours utilisateur, l'UI, les interactions Provider/écran | **A — substitut en mémoire** |
| Le SQL, les requêtes, les transactions, le schéma, les contraintes | **Tests unitaires du service** (séparés, avec vraie SQLite, sans UI) |
| Les deux à la fois (rare et coûteux) | B — `runAsync` + vraie SQLite |

**Règle pratique :** par défaut, choisir A. Le SQL doit être validé au niveau du test unitaire du service de BD (`watchlist_database_service_test.dart` du TD), pas via un test d'UI. C'est plus rapide à exécuter, plus rapide à écrire, et chaque couche reste responsable de ce qu'elle teste.

---

## 3. Le troisième niveau : `integration_test` sur device réel

Pour valider l'app de bout en bout sur un vrai device/émulateur (Android, iOS, desktop), il existe le package officiel `integration_test`, distinct de `flutter_test`. Il lance la **vraie app** avec **vraie SQLite native**, **vrai clock** et **vraies I/O**.

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

```dart
// integration_test/app_test.dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serie_liste/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('parcours réel sur device', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    // ... interactions ...
  });
}
```

```bash
flutter test integration_test/   # nécessite un device/émulateur connecté
```

**Quand l'utiliser ?**

- Pour valider une migration SQLite sur disque.
- Pour reproduire un bug spécifique à Android ou iOS.
- Pour les tests d'acceptation avant release.
- Jamais pour la boucle de développement quotidienne (trop lent, demande un device).

**Cas d'usage typique** : un seul test `integration_test` qui exécute le *happy path* complet, en complément d'une suite riche de tests unitaires + un ou deux tests d'intégration en `testWidgets` avec substituts.

---

## 4. Pyramide de tests recommandée pour le projet

```
              /\
             /  \    integration_test sur device
            /    \   (1 happy path, lent, optionnel)
           /------\
          /        \  testWidgets avec substituts en mémoire
         /          \ (parcours utilisateur, ~1 s, approche A)
        /------------\
       /              \ Tests unitaires du Provider
      /                \ (vraie SQLite in-memory FFI, rapide)
     /------------------\
    /                    \ Tests unitaires du service de BD
   /                      \ (vraie SQLite in-memory FFI, le plus rapide)
  /------------------------\
```

L'**injection de dépendance** est la clé qui rend cette pyramide possible : c'est la même classe `WatchlistDatabaseService` qui sert en production, mais selon le niveau de test on lui passe une vraie BD SQLite (niveaux bas) ou un substitut en mémoire (niveau haut).
