# AGENTS.md

This file defines the development rules for AI agents and contributors working on the FLINX Flutter app.

The app is a Flutter-first mobile application for FLINX door-control devices. Flutter owns UI, navigation, application state, and business orchestration. iOS and Android native code own BLE, Wi-Fi provisioning, device protocol handling, permissions, scanning, and hardware diagnostics.

Read `docs/flutter_architecture.md` before making architecture-level changes.

## Product Context

FLINX supports these major areas:

- Device onboarding: empty state, door/device type selection, QR scan, BLE scan, Wi-Fi selection, provisioning, binding, success/failure retry.
- Home and device overview: user info, device count, device cards, connection state, device entry points.
- Door control: open, stop, close, device name, cycle count, remaining life, connection state.
- Quick actions: door-open reminder toggle and reminder duration picker.
- Settings: user parameters and installer parameters.
- Transmitter management: list, details, pairing, rename, delete, share, permissions.
- Security Center: general evaluation, safety sensor evaluation, sensor status, position, battery, offline and blocking states.
- Accessory management: sensor list and deletion, with BLE connection preconditions.
- Records: operation history and event history for troubleshooting.
- Account: profile, third-party accounts, account security.

## Architecture Principles

Use this architecture unless the user explicitly asks for a different direction:

- Feature-first Flutter structure.
- Clean Architecture boundaries inside each feature.
- Riverpod for dependency injection and state management.
- go_router for navigation.
- Pigeon for long-term Flutter-native contracts.
- Event streams or Pigeon callbacks for native-to-Flutter device events.
- MethodChannel only for temporary or migration-only interfaces.
- Mock hardware gateway must remain available for UI development and tests.

Do not let Flutter UI directly implement hardware protocol details. Do not let native code know about Flutter pages or navigation.

## Layer Boundaries

### Presentation

Presentation contains pages, widgets, dialogs, empty/loading/error/offline states, and user interaction handlers.

Allowed:

- Render view state.
- Call application controllers/providers.
- Show user-facing messages and actions.

Forbidden:

- Direct BLE, Wi-Fi, provisioning, QR, or native channel calls.
- Direct API or database calls.
- Interpreting native error codes.
- Embedding device protocol constants in widgets.

### Application

Application contains page controllers, Riverpod providers, flow coordinators, and use-case orchestration.

Responsibilities:

- Execute use cases.
- Check permissions, BLE state, device online state, and user capability before device actions.
- Convert domain errors into UI-ready states.
- Own pending, retry, success, and failure state transitions.

### Domain

Domain contains business entities, repository interfaces, value objects, use cases, and domain errors.

Rules:

- Must not import Flutter widgets.
- Must not import Dio, databases, Pigeon-generated classes, MethodChannel, or platform code.
- Must not depend on concrete data sources.
- Should contain platform-independent business rules.

Core domain concepts include:

- `User`
- `Device`
- `DeviceStatus`
- `DoorState`
- `DoorCommand`
- `DoorType`
- `DeviceType`
- `WifiNetwork`
- `ProvisioningSession`
- `DeviceParameter`
- `Transmitter`
- `TransmitterPermission`
- `SafetyEvaluation`
- `SafetySensor`
- `Accessory`
- `OperationRecord`
- `AppPermissionState`
- `ConnectionState`

### Data

Data contains repository implementations, DTOs, mappers, remote data sources, local data sources, secure storage, and hardware data sources.

Responsibilities:

- Map DTOs to domain entities.
- Map native bridge models to domain entities.
- Normalize API, storage, and native errors into domain errors.
- Implement caching, retry, timeout, and diagnostics behavior.

### Platform Bridge

Platform Bridge is the only Flutter-side boundary to native hardware capabilities.

Use:

- `HardwareGateway` as the stable Flutter abstraction.
- Pigeon-generated APIs behind gateway/data-source implementations.
- Typed event models for BLE, provisioning, device snapshots, safety events, and native errors.

Do not expose Pigeon-generated classes directly to UI pages.

### Native iOS / Android

Native code should be organized by capability:

- Bridge adapters.
- Bluetooth/BLE manager.
- Provisioning manager.
- Device protocol encoder/decoder.
- Permission manager.
- QR/scanner adapter when native scanning is used.
- Diagnostics and native error logging.

Native code exposes capabilities and events. It must not own Flutter navigation or UI state.

## Project Structure

Preferred root structure:

```text
lib/
├─ app/
│  ├─ bootstrap.dart
│  ├─ flinx_app.dart
│  ├─ router/app_router.dart
│  └─ theme/
├─ core/
│  ├─ errors/
│  ├─ logging/
│  ├─ permissions/
│  ├─ platform/
│  ├─ storage/
│  ├─ network/
│  └─ utils/
├─ platform_bridge/
│  ├─ pigeon/
│  ├─ hardware_gateway.dart
│  ├─ hardware_events.dart
│  └─ hardware_models.dart
├─ features/
│  ├─ add_device/
│  ├─ home/
│  ├─ device_control/
│  ├─ settings/
│  ├─ transmitter/
│  ├─ security_center/
│  ├─ accessories/
│  ├─ records/
│  └─ account/
└─ shared/
   ├─ widgets/
   ├─ design_system/
   └─ l10n/
```

Preferred feature structure:

```text
features/<feature_name>/
├─ domain/
│  ├─ entities/
│  ├─ repositories/
│  └─ use_cases/
├─ data/
│  ├─ dto/
│  ├─ mappers/
│  └─ repositories/
├─ application/
│  ├─ providers.dart
│  └─ <feature>_controller.dart
└─ presentation/
   ├─ pages/
   ├─ widgets/
   └─ states/
```

Small features may be leaner, but do not invert dependencies.

## Native Bridge Rules

Long-term hardware APIs should be defined with Pigeon.

Flutter may call native for:

- Permission snapshot and permission requests.
- BLE scanning and scan stop.
- Device connect and disconnect.
- Door commands: open, stop, close.
- Device snapshot read.
- Wi-Fi provisioning start/cancel.
- Parameter read/write.
- Transmitter pairing, rename, delete, share-related native operations if required.
- Safety snapshot read.
- Accessory deletion.
- Native diagnostics collection.

Native may emit events for:

- BLE scan results.
- Connection state changes.
- Provisioning progress.
- Device snapshot changes.
- Safety events.
- Native errors.

Every control or hardware command must include or create a `requestId` so Flutter, native logs, and support diagnostics can correlate the operation.

## Hardware Guard Rules

Before any hardware-dependent action, check the required preconditions in application/domain use cases, not inside widgets.

Examples:

- Door commands require an operable device and a valid connection path.
- Accessory deletion requires user permission, device existence, BLE connection, and a device state that allows deletion.
- Safety Center realtime actions require the expected connection state.
- QR scan requires camera permission.
- BLE scan/connect requires the relevant platform permissions.
- Provisioning requires Wi-Fi inputs and required system permissions.

Blocking reasons must be represented as typed state, not ad-hoc strings in the UI.

## Error Model

Use a unified app/domain error model. UI should not branch on native error codes.

Recommended error categories:

- `PermissionDenied`
- `BluetoothUnavailable`
- `BluetoothDisconnected`
- `DeviceOffline`
- `DeviceBusy`
- `CommandTimeout`
- `ProvisioningFailed`
- `PairingFailed`
- `AccessDenied`
- `NetworkUnavailable`
- `ServerError`
- `Unknown`

Each error should carry, where applicable:

- Stable domain code.
- User-facing message key or presentation mapping.
- Recommended user action, such as `openSettings`, `connectBluetooth`, `retry`, `contactSupport`, or `none`.
- Native code for diagnostics only.
- `requestId`.
- `deviceId`.
- Retryability.

## State and UI Rules

Every meaningful page must support these states when relevant:

- Loading.
- Empty.
- Ready/content.
- Error.
- Offline.
- Permission blocked.
- Pending command/action.

Control buttons must support pending and disabled states. Prevent duplicate command submission unless a use case explicitly permits it.

Do not assume cached device state is realtime. Security Center offline views must show the last update time when displaying cached data.

## Data and Storage Rules

Use separate data sources for:

- Remote API.
- Local cache.
- Secure storage.
- Hardware/native bridge.

Sensitive data rules:

- Store auth tokens in secure storage only.
- Store device credentials or device keys in secure storage only.
- Do not persist Wi-Fi passwords after provisioning.
- Redact tokens, Wi-Fi passwords, and device secrets from logs.

Cache recommendations:

- Device list and last known device state.
- Last Security Center snapshot.
- Recent operation records.
- User profile summary.
- Device parameter cache.

Control actions must not be queued offline. They require realtime execution and confirmation.

## Logging and Diagnostics

Hardware products need support-friendly logs from day one.

Log these categories:

- App lifecycle.
- Auth/session summary.
- Device discovery.
- BLE connection lifecycle.
- Command request/response.
- Provisioning progress and failure reason.
- Security Center reads and events.
- Transmitter pairing flow.
- Accessory management actions.
- API request summaries.

Rules:

- Use the same `requestId` across Flutter and native for a single operation.
- Keep native error codes in diagnostics, not UI branching logic.
- Redact sensitive data.
- Prefer structured logs over free-form text.
- Keep enough context for support troubleshooting without exposing secrets.

## Testing Expectations

When adding or changing behavior, add tests at the right layer.

Flutter tests:

- Domain use-case unit tests.
- Repository tests with mocked data sources.
- Riverpod controller/provider state tests.
- Widget tests for loading, empty, error, offline, permission-blocked, and pending states.
- Routing tests for auth redirects and feature entry points where applicable.

Native tests:

- Protocol encoder/decoder tests.
- BLE state machine tests.
- Provisioning timeout and retry tests.
- Bridge contract tests.
- Permission state tests.

Integration strategy:

- Keep `MockHardwareGateway` for UI and automated tests.
- Support a simulated native mode with deterministic scan results, device states, and errors.
- Keep real-device code behind the same `HardwareGateway` contract.

## Dependency Rules

Prefer stable, well-supported packages. Do not add dependencies casually.

Default choices:

- State management: Riverpod.
- Navigation: go_router.
- Native bridge contract: Pigeon.
- Flutter version management: FVM.

Before adding a new package, verify:

- It does not duplicate an existing project dependency.
- It works on both iOS and Android.
- It is compatible with the pinned Flutter SDK.
- It does not bypass the architecture boundaries above.

## Code Style

Use clear, boring, maintainable names.

Naming conventions:

- Pages end with `Page`.
- Controllers end with `Controller`.
- Use cases end with `UseCase`.
- Repository interfaces end with `Repository`.
- Repository implementations end with `RepositoryImpl`.
- DTOs end with `Dto`.
- Mappers end with `Mapper`.
- Riverpod provider files may be named `providers.dart` inside each feature.

Keep comments rare and useful. Comment why something is non-obvious, especially around device protocol behavior, platform differences, retries, timeouts, and permissions.

## Implementation Checklist

Before finishing a feature or fix, confirm:

- UI does not call native bridge APIs directly.
- Domain layer has no Flutter, network, storage, or channel imports.
- Hardware actions use guard/use-case precondition checks.
- Errors are mapped to typed app/domain errors.
- Control operations have pending/disabled handling.
- Hardware operations have `requestId` logging.
- Mock gateway still works.
- Tests cover success and important failure paths.
- Sensitive data is not logged or persisted insecurely.

## Development Phases

Recommended implementation order:

1. Engineering foundation: Flutter project, FVM, linting, routing, theme, localization, logging, error model, Pigeon bridge draft, mock hardware gateway.
2. Core loop: onboarding, home, device control, BLE connection events, basic parameter reads.
3. Settings and transmitter management: settings, pairing, rename, delete, reminder toggle/duration.
4. Security Center and accessories: evaluation cards, sensor details, offline states, BLE blocking prompts, accessory deletion.
5. Records, account, and diagnostics: history, profile, third-party accounts, account security, support diagnostics export.

## Non-Negotiables

- Do not put hardware protocol code in Flutter widgets.
- Do not expose native channel models directly to UI.
- Do not let native code depend on Flutter page concepts.
- Do not bypass precondition guards for hardware actions.
- Do not use raw strings for device commands when typed enums are available.
- Do not show raw native error codes to users.
- Do not remove the mock hardware path.
- Do not store Wi-Fi passwords after provisioning.
- Do not log tokens, Wi-Fi passwords, device keys, or secrets.
