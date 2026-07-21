# AGENTS.md

This file defines the development rules for AI agents and contributors working on the FLINX Flutter app.

The app is a Flutter-first mobile application for FLINX door-control devices. Flutter owns UI, navigation, application state, and business orchestration. iOS and Android native code own BLE, Wi-Fi provisioning, device protocol handling, permissions, scanning, and hardware diagnostics.

Read `docs/flutter_architecture.md` before making architecture-level changes.
Read `docs/network_requests.md` before adding or changing REST APIs, network
configuration, JSON DTOs, remote data sources, repository mappings, or network
error handling.

## Git Flow

This repository follows Git Flow.

Branch roles:

- `main`: production-ready code only. Do not develop directly on `main`.
- `develop`: integration branch for ongoing development. New feature branches must start from `develop`.
- `feature/<short-name>`: normal feature work. Merge back into `develop`.
- `release/<version>`: release stabilization. Start from `develop`, then merge into `main` and back into `develop`.
- `hotfix/<short-name>`: urgent production fixes. Start from `main`, then merge into `main` and back into `develop`.

Agent workflow:

- Before editing, check the current branch and working tree.
- If the task is normal development, work from `develop` or create a `feature/<short-name>` branch from `develop`.
- Do not commit directly to `main` unless the user explicitly requests a release or hotfix action.
- Keep commits focused and use clear messages such as `feat: ...`, `fix: ...`, `chore: ...`, `docs: ...`, or `test: ...`.
- Do not rewrite shared branch history unless the user explicitly asks for it.

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

## UI Asset Rule

This is a hard requirement for all UI implementation work:

- Do not hand-draw, approximate, or recreate final UI cut assets in Flutter code when the user intends to provide them.
- Use user-provided UI cut images/assets whenever available.
- If the final asset has not been provided yet, use a clear placeholder asset name and wire the UI to that placeholder instead of drawing the asset manually.
- Placeholder asset names should be descriptive and implementation-ready, for example `login_header_bg`, `welcome_hero_image`, or `auth_google_button_art`.
- When replacing placeholders with final assets later, preserve layout structure and naming consistency as much as possible.

## Theme Token Rule

This is a hard requirement for all UI styling work:

- Fonts, font sizes, font weights, text colors, button colors, background colors, border colors, radii, and other reusable visual styling values must be extracted into shared theme tokens instead of being left as inline magic values.
- Always implement new UI with the assumption that multiple themes or visual variants will be needed later.
- Even if the token system is incomplete today, new UI work must still go through the current shared theme or token layer first, then extend that layer as needed.
- When touching existing UI, proactively extract hard-coded typography and color values that are directly related to the work you are doing.
- Prefer semantic names such as `authPrimaryButtonColor`, `loginTitleStyle`, `inputBorderColor`, or `surfaceBackground` over raw design-only names that are hard to reuse.
- Do not introduce new repeated visual constants directly inside page widgets when they can live in the shared theme or token layer.

## UI Localization Rule

This is a hard requirement for all UI implementation work:

- Put every user-facing string, including page titles, buttons, labels, empty/error states, dialogs, tooltips, and accessibility labels, in `lib/shared/l10n/app_en.arb` and `lib/shared/l10n/app_zh.arb`.
- Read UI copy through `AppLocalizations.of(context)`; do not introduce or retain user-facing string literals in pages or widgets.
- Add descriptive, feature-prefixed localization keys and regenerate localization outputs after changing ARB files. Do not manually edit generated localization Dart files.
- Keep both English and Chinese translations current in the same change. Use literals only for non-user-visible implementation details such as asset paths, route names, storage keys, and test fixtures.

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

Avoid Android-style Material tap effects such as ripple, splash, and highlight on custom-designed app UI unless the design explicitly calls for them. Prefer explicit visual states from the design system or silent tap targets with adequate hit area.

## Network Request Rules

The canonical network usage guide is `docs/network_requests.md`. Follow it for
all REST API work.

Required request flow:

```text
Page / Widget
→ Controller / Provider
→ UseCase
→ Domain Repository
→ RepositoryImpl
→ RemoteDataSource
→ Retrofit API
→ shared Dio
```

Rules:

- Obtain Dio through `dioProvider`; do not create feature-specific Dio clients
  that bypass shared timeouts, request correlation, logging, or debug proxy
  configuration.
- Define Retrofit APIs and wire-format DTOs inside the owning feature's data
  layer. Put only reusable transport infrastructure in `core/network`.
- Use `ApiEnvelopeDto<T>` for the shared server response envelope. Prefer a
  strongly typed DTO for structured `data`; use `dynamic` only when the wire
  response is intentionally unstructured or a primitive.
- DTOs represent the server contract. Domain entities represent business
  meaning. Convert DTOs to domain entities in a data-layer mapper or
  `RepositoryImpl`, never in presentation, application, or domain code.
- Remote data sources validate HTTP-independent protocol success, including
  `code`, `success`, required `data`, and feature-specific wire fields.
- Convert `DioException` to `NetworkException`, then to a feature data-source
  exception, then to `AppError` or a typed domain error. Do not expose Dio,
  HTTP status codes, server messages, or raw response codes to UI code.
- Every network-backed business operation must create a `requestId` and reuse
  it across use case, repository, data source, Dio `extra`, the
  `X-Request-Id` header, and structured logs.
- Do not log full request or response bodies, Authorization headers, tokens,
  passwords, Wi-Fi credentials, nonces, device keys, or other secrets.
- Environment values must come from `--dart-define-from-file`. Commit example
  files only; never commit populated `config/env/*.json` files.
- Personal debug proxy addresses and invalid-certificate settings must not be
  committed to shared branches.
- Widget tests and controller tests must override providers or repositories and
  must never call real servers.
- During API integration, if the response contract has not been provided, only
  wire and verify that the request can be issued. Do not guess response DTOs,
  success conditions, field mappings, persistence, or UI behavior. Wait for a
  captured real response from the debugging proxy, then implement the response
  handling in a follow-up change.

Code generation rules:

- Run `dart run build_runner build` after changing Retrofit APIs, Freezed DTOs,
  or JSON serialization models.
- Commit the resulting `.g.dart` and `.freezed.dart` files.
- Never edit generated files manually.
- Run `bash tool/verify_generated.sh` before completing network or DTO work.

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
- Network calls use the shared Dio/Retrofit path and do not originate in UI.
- Structured API responses use typed DTOs and are mapped to domain entities in
  the data layer.
- Network errors are normalized before reaching application or presentation.
- Network operations preserve one `requestId` through requests and logs.
- Retrofit, JSON, and Freezed generated files are current.

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
- Do not manually draw or recreate UI cut assets in code when they should come from provided design assets; use provided assets or descriptive placeholder asset names instead.
- Do not leave reusable font, color, border, or button styling values hard-coded inside page widgets; extract them into shared theme tokens.
- Do not bypass precondition guards for hardware actions.
- Do not use raw strings for device commands when typed enums are available.
- Do not show raw native error codes to users.
- Do not remove the mock hardware path.
- Do not store Wi-Fi passwords after provisioning.
- Do not log tokens, Wi-Fi passwords, device keys, or secrets.
