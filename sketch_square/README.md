# SketchSquare app (Flutter)

Flutter client for SketchSquare, a marketplace where verified architects upload, sell, buy and discover architectural drawings.
Flutter 3.29 / Dart 3.7. Conventions: [`docs/CONVENTIONS.md`](../docs/CONVENTIONS.md). API: [`docs/API_CONTRACT.md`](../docs/API_CONTRACT.md).

## Run

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   # Android emulator (this is also the default)
flutter run --dart-define=API_BASE_URL=http://localhost:3000  # iOS simulator / web / desktop
flutter run --dart-define=API_BASE_URL=http://<LAN-IP>:3000   # physical device
```

`10.0.2.2` is how the Android emulator reaches the host machine's `localhost`. Start the backend first (see the root README).

## Checks

```sh
flutter analyze
flutter test
flutter build web   # quick compile check without an emulator
```

## Code generation

Riverpod / freezed / json_serializable output is committed. After changing annotated files:

```sh
dart run build_runner build --delete-conflicting-outputs
```
