# FLINX

Flutter-first mobile app for FLINX door-control devices.

## Toolchain

- Flutter: `3.44.0` stable
- Dart: `3.12.0`
- Project version is pinned with `.fvmrc`

## Architecture

Flutter owns UI, navigation, application state, and orchestration. Native iOS
and Android code own BLE, Wi-Fi provisioning, device protocol handling,
permissions, scanning, and hardware diagnostics.

Read `docs/flutter_architecture.md` before architecture-level changes.

## Useful Commands

```sh
flutter pub get
flutter analyze
flutter test
```
