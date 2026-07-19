# ForgeFit

Application de musculation et de suivi d'entraînement, en Flutter. Bibliothèque d'exercices réelle, création de programmes (générés par règles ou manuels), séances en direct avec suggestions de charge et détection de records, historique, dashboard avec silhouette musculaire par rang, et système de succès — le tout local-first (Drift/SQLite), sans backend.

## Stack

- Flutter (mobile-first, compatible web/macOS)
- Riverpod pour l'état
- go_router pour la navigation
- Drift (SQLite) pour la persistance locale, web compris (sqlite3 WASM)

## Architecture

```
lib/
  domain/         entités, interfaces de repository, services métier (purs, sans dépendance Flutter)
  data/           datasources (dataset, Drift), implémentations de repository
  application/    providers Riverpod (composition root dans repository_providers.dart)
  presentation/   routes, écrans par fonctionnalité, widgets
  core/           thème, localisation FR, conversion d'unités
```

Logique métier (génération de programme, détection de records, suggestion de charge, rangs, succès) entièrement basée sur des règles — jamais de LLM pour décider d'une valeur numérique.

## Démarrage

```bash
flutter pub get
dart run build_runner build   # génère le code Drift (*.g.dart, ignoré par git)
flutter run -d chrome         # ou macos / ios / android
```

### Persistance sur le web

`lib/data/datasources/local/app_database.dart` utilise `drift_flutter` pour éviter que `dart:ffi` ne casse la compilation web. Deux fichiers sous `web/` doivent rester alignés avec les versions résolues dans `pubspec.lock` :

- `web/sqlite3.wasm` — à télécharger depuis les releases de [`sqlite3.dart`](https://github.com/simolus3/sqlite3.dart/releases) correspondant à la version résolue du paquet `sqlite3`.
- `web/drift_worker.js` — à compiler depuis les sources du paquet `drift` résolu (pas de binaire précompilé) :
  ```bash
  dart compile js --packages=.dart_tool/package_config.json \
    -o web/drift_worker.js \
    "$HOME/.pub-cache/hosted/pub.dev/drift-<version>/web/drift_worker.dart"
  ```

Un décalage de version entre ces deux fichiers ne produit pas d'erreur de compilation mais une erreur runtime cryptique (`WebAssembly.instantiate(): Import ... module is not an object or function`).

## Données et licences

- Données d'exercices (texte) : [`hasaneyldrm/exercises-dataset`](https://github.com/hasaneyldrm/exercises-dataset), licence MIT.
- Médias (images/GIFs) : © Gym visual — usage personnel uniquement, attribution obligatoire (affichée dans Paramètres → Mentions légales). Voir `assets/data/DATASET_LICENSE_NOTE.md`.

## Tests

```bash
flutter analyze
flutter test
```
