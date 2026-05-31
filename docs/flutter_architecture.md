# FLINX Flutter 架构设计方案

适用产品：FLINX v5.0 / v5.0.1

目标：使用 Flutter 实现跨平台 UI 与业务编排；蓝牙、Wi-Fi 配网、设备协议、扫码、权限等硬件/系统能力由 iOS/Android 原生实现，并通过类型安全接口暴露给 Flutter。

## 1. 产品范围理解

从产品手册看，FLINX 是一个面向门控设备的移动端应用，核心能力包括：

- 设备添加：空状态、选择门类型/设备类型、扫码、蓝牙扫描、选择 Wi-Fi、连接设备、成功/失败重试。
- 首页与控制：用户信息、设备数量、设备卡片、设备状态、进入控制页。
- 门体控制：关/停/开，展示设备名称、周期计数、剩余寿命、连接状态。
- 快捷功能：门未关提醒开关、提醒时长选择。
- 设置参数：普通用户参数与安装人员参数，包含遥控器管理、LED 延时、部分开启、自动关闭、开门速度、设备信息、行程限位、力矩余量、门未关提醒等。
- 遥控器管理：列表、详情、对码、重命名、删除、分享、权限设置。
- 安全中心：General Evaluation、Safety Sensors Evaluation、传感器状态/位置/电量、异常处理、离线态、蓝牙未连接阻断提示。
- 配件管理：Sensor manage，配件列表、删除，部分操作依赖蓝牙连接。
- 记录历史：门体操作和事件历史，用于售后排查。
- 账号资料：用户资料、第三方账号关联、账户安全。

## 2. 总体架构结论

建议采用“Flutter Feature-first + Clean Architecture + 原生硬件插件化”的结构：

```text
Flutter App
├─ Presentation/UI        页面、组件、路由、交互状态
├─ Application            用例编排、页面状态、权限/连接前置判断
├─ Domain                 业务实体、仓库接口、错误模型、领域规则
├─ Data                   API、本地缓存、Repository 实现、DTO 映射
└─ Platform Bridge        Pigeon/Platform Channel，对接原生硬件能力

Native iOS / Android
├─ BLE Manager            扫描、连接、断开、订阅通知、写特征
├─ Provisioning Manager   Wi-Fi 配网、设备绑定、配网进度
├─ Device Protocol        门控指令、参数读写、传感器/遥控器协议
├─ Permission Manager     蓝牙、定位、相机、局域网、通知权限
├─ QR Scanner Adapter     原生扫码或 Flutter 插件封装
└─ Native Event Stream    连接状态、设备状态、配网进度、告警事件
```

关键原则：

- Flutter 不直接写硬件协议，只调用稳定的 `HardwareGateway` 抽象。
- 原生不感知 Flutter 页面，只暴露能力和事件。
- 所有设备操作都必须经过统一的“连接/权限/设备状态前置检查”。
- UI 可以先接 mock gateway 开发，硬件联调不阻塞页面开发。
- v5.0.1 的安全中心作为独立 feature，不和首页控制、配件管理揉在一起。

## 3. 技术选型建议

### 3.1 Flutter 与 Dart

- Flutter：使用团队统一的 Flutter stable 版本，并通过 FVM 锁定项目版本。
- Dart：跟随 Flutter SDK 版本。
- 最低系统建议：iOS 13+，Android 8.0+。如果蓝牙能力、权限策略或商业要求更高，可再收紧。

说明：不要在架构文档里追逐“最新 Flutter 版本号”。建议在项目初始化时用 FVM 写入 `.fvmrc`，CI 和本地都读取同一版本，避免多人环境漂移。

### 3.2 状态管理

推荐：Riverpod。

原因：

- 适合 feature-first 架构，依赖注入和状态管理可以放在一起。
- 对异步状态、设备连接状态、配网进度、权限状态建模比较自然。
- 测试时可以覆盖 provider，方便硬件 mock。

备选：Bloc/Cubit。

适合团队已有 Bloc 经验、需要强事件审计、状态流转日志更严格的场景。若团队 Flutter 经验一般，Riverpod 的开发效率和可测试性会更均衡。

### 3.3 路由

推荐：go_router。

原因：

- 支持声明式路由、子路由、深链、登录态重定向。
- 设备详情、控制页、设置页、安全中心详情、扫码结果页都适合路径化。

### 3.4 原生通信桥

推荐组合：

- Pigeon：定义 Flutter 与原生之间的类型安全 API。
- EventChannel 或 Pigeon Host->Flutter callback：传递 BLE 连接状态、配网进度、设备状态、告警等持续事件。
- MethodChannel：仅用于少量临时能力或迁移期接口，不作为长期主方案。

Flutter 官方平台通道是异步消息机制，适合 UI 与 host 平台之间保持响应；Pigeon 能生成结构化、类型安全代码，减少手写字符串 channel 和动态 map 的运行时错误。

## 4. 分层设计

## 4.1 Presentation 层

职责：

- 页面、组件、弹窗、空状态、加载态、错误态。
- 只消费 ViewState，不直接调用 BLE/Wi-Fi/API。
- 触发用户动作，例如“点击开门”“删除配件”“开始扫描”。

典型对象：

- `DeviceHomePage`
- `DeviceControlPage`
- `AddDeviceFlowPage`
- `SecurityCenterPage`
- `TransmitterManagementPage`
- `AccessoryManagementPage`
- `RecordPage`
- `AccountPage`

## 4.2 Application 层

职责：

- 页面级状态管理。
- 调用 use case。
- 处理权限、蓝牙连接、设备在线等前置条件。
- 把领域错误转换成 UI 可展示文案和操作按钮。

典型对象：

- `AddDeviceController`
- `DeviceControlController`
- `SecurityCenterController`
- `TransmitterController`
- `AccessoryController`
- `RecordsController`

示例：删除传感器前置流程。

```text
用户点击删除传感器
→ AccessoryController.deleteSensor(sensorId)
→ CheckBleConnectedUseCase
→ 若未连接：返回 NeedBluetoothConnection
→ UI 展示“蓝牙未连接，先连接后重试”
→ 若已连接：DeleteSensorUseCase
→ Native DeviceProtocol 删除配件
→ 刷新配件列表与安全中心状态
```

## 4.3 Domain 层

职责：

- 定义业务实体和仓库接口。
- 放置与平台无关的业务规则。
- 不依赖 Flutter widget、不依赖 dio、不依赖原生 channel。

核心实体：

```text
User
Device
DeviceStatus
DoorState
DoorCommand
DoorType
DeviceType
WifiNetwork
ProvisioningSession
DeviceParameter
Transmitter
TransmitterPermission
SafetyEvaluation
SafetySensor
Accessory
OperationRecord
AppPermissionState
ConnectionState
```

核心仓库接口：

```text
AuthRepository
UserRepository
DeviceRepository
DeviceControlRepository
DeviceSettingsRepository
TransmitterRepository
SecurityRepository
AccessoryRepository
RecordRepository
HardwareRepository
PermissionRepository
```

## 4.4 Data 层

职责：

- Repository 实现。
- Remote API、Local DB、Secure Storage、Platform Bridge 的组合。
- DTO 和 domain entity 双向映射。
- 缓存策略、重试、超时、错误归一化。

建议数据源：

- `RemoteDataSource`：账号、设备云端列表、分享、历史记录、固件/配置下发。
- `LocalDataSource`：设备缓存、最近连接设备、历史记录缓存、安全中心最近状态。
- `SecureDataSource`：token、refresh token、设备密钥、敏感绑定信息。
- `HardwareDataSource`：BLE、配网、设备协议，由原生桥提供。

## 4.5 Native Platform 层

职责：

- BLE 扫描、连接、服务发现、读写特征、订阅 notify。
- Wi-Fi 配网与设备绑定。
- 设备协议编解码。
- 原生权限状态检查与申请。
- 扫码、局域网、通知等系统能力。

原生层内部也建议分层：

```text
ios/Runner/FLINXHardware
├─ Bridge              Pigeon 生成代码适配
├─ Bluetooth           CoreBluetooth 封装
├─ Provisioning        配网流程
├─ Protocol            指令编解码、CRC、超时、重试
├─ Permissions         权限检查
└─ Diagnostics         原生日志、错误码、链路诊断

android/app/src/main/.../flinxhardware
├─ bridge              Pigeon 生成代码适配
├─ bluetooth           BluetoothGatt 封装
├─ provisioning        配网流程
├─ protocol            指令编解码、CRC、超时、重试
├─ permissions         权限检查
└─ diagnostics         原生日志、错误码、链路诊断
```

## 5. Feature 模块划分

建议按业务 feature 组织，而不是按技术层横向堆文件。

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

每个 feature 内部结构：

```text
features/device_control/
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
│  └─ device_control_controller.dart
└─ presentation/
   ├─ pages/
   ├─ widgets/
   └─ states/
```

## 6. 原生接口设计

## 6.1 接口边界

Flutter 调原生：

- 权限检查与申请。
- 开始/停止 BLE 扫描。
- 连接/断开设备。
- 获取设备实时状态。
- 发送门控命令：开、停、关。
- 读取/写入设备参数。
- 开始配网。
- 遥控器对码、重命名、删除、权限设置。
- 读取安全传感器状态。
- 删除配件。
- 拉取原生诊断信息。

原生推 Flutter：

- 扫描结果。
- BLE 连接状态。
- 配网进度。
- 门体状态变化。
- 设备参数变化。
- 传感器告警、电量、离线状态。
- 操作指令结果。
- 原生错误与诊断信息。

## 6.2 Pigeon API 草案

```dart
@HostApi()
abstract class HardwareHostApi {
  PermissionSnapshot getPermissionSnapshot();
  PermissionSnapshot requestPermissions(List<PermissionKind> permissions);

  void startBleScan(BleScanFilter filter);
  void stopBleScan();
  DeviceConnection connectDevice(String deviceId);
  void disconnectDevice(String deviceId);

  CommandResult sendDoorCommand(String deviceId, DoorCommandDto command);
  DeviceSnapshot readDeviceSnapshot(String deviceId);

  ProvisioningSessionDto startProvisioning(ProvisioningRequestDto request);
  void cancelProvisioning(String sessionId);

  List<DeviceParameterDto> readParameters(String deviceId, List<String> keys);
  CommandResult writeParameters(String deviceId, List<DeviceParameterDto> params);

  CommandResult startTransmitterPairing(String deviceId);
  CommandResult renameTransmitter(String deviceId, String transmitterId, String name);
  CommandResult deleteTransmitter(String deviceId, String transmitterId);

  SafetySnapshotDto readSafetySnapshot(String deviceId);
  CommandResult deleteAccessory(String deviceId, String accessoryId);

  NativeDiagnosticsDto collectDiagnostics(String deviceId);
}

@FlutterApi()
abstract class HardwareFlutterApi {
  void onBleScanResult(BleDeviceDto device);
  void onConnectionChanged(ConnectionEventDto event);
  void onProvisioningProgress(ProvisioningProgressDto progress);
  void onDeviceSnapshotChanged(DeviceSnapshotDto snapshot);
  void onSafetyEvent(SafetyEventDto event);
  void onNativeError(NativeErrorDto error);
}
```

## 6.3 指令设计

门控指令必须统一建模，避免 UI 直接传字符串。

```text
DoorCommand
├─ open
├─ stop
└─ close
```

每次指令返回：

```text
CommandResult
├─ requestId
├─ accepted: bool
├─ deviceId
├─ command
├─ nativeCode
├─ domainCode
├─ message
└─ timestamp
```

原则：

- UI 看到的是 `DomainError`，不是原生错误码。
- 原生错误码必须保留到诊断日志，便于售后排查。
- 控制指令要有幂等 requestId，避免重复点击导致状态混乱。
- 指令发送后 UI 进入 pending 状态，收到设备状态事件后再确认最终状态。

## 7. 关键业务流程设计

## 7.1 添加设备流程

```text
Empty State
→ Choose Door Type
→ Choose Device Type
→ Scan QR / BLE Scan
→ Select Device
→ Check Permissions
→ Select Wi-Fi
→ Start Provisioning
→ Progress
→ Bind Device
→ Success / Failed Retry
→ Home
```

关键状态：

```text
idle
choosingDoorType
choosingDeviceType
scanning
selectingWifi
provisioning
binding
success
failed
```

失败处理：

- 蓝牙权限缺失：引导开启权限。
- 定位/附近设备权限缺失：引导授权。
- Wi-Fi 不可用：提示切换网络或打开定位/局域网权限。
- 设备连接失败：检查上电、距离、网络配置、设备是否被绑定。
- 配网超时：支持重试和重新扫描。

## 7.2 首页与控制页流程

首页展示云端/本地设备列表，设备状态来自三路合并：

```text
Cloud device list + Local cache + Native connection events
```

控制页进入策略：

- 如果设备在线且 BLE 已连接：直接展示实时状态。
- 如果设备在线但 BLE 未连接：展示可控制项，但硬件依赖操作前提示连接。
- 如果设备离线：展示离线态，只允许查看历史/信息，禁用控制。

开/停/关操作：

```text
用户点击按钮
→ 检查设备是否可操作
→ 检查连接状态
→ sendDoorCommand
→ optimistic pending UI
→ 等待状态事件 / 超时
→ 更新 UI / 展示错误
```

## 7.3 安全中心流程

安全中心是 v5.0.1 重点，建议独立状态模型：

```text
SafetyCenterState
├─ deviceConnection
├─ generalEvaluation
├─ sensorsEvaluation
├─ sensors
├─ blockingReason
├─ lastUpdatedAt
└─ diagnostics
```

General Evaluation 和 Safety Sensors Evaluation 都抽象成 Evaluation Card：

```text
EvaluationStatus
├─ normal
├─ warning
├─ critical
├─ offline
└─ unknown
```

蓝牙未连接阻断提示不应散落在页面里，应由 `SafetyGuard` 统一判断：

```text
SafetyActionGuard.canDeleteSensor(deviceId)
SafetyActionGuard.canReadRealtimeSensor(deviceId)
```

## 7.4 遥控器管理流程

```text
Settings
→ Transmitter Management
→ Transmitter List
→ Pairing / Detail
→ Rename / Delete / Share / Permission
→ Result Feedback
```

对码过程建议状态：

```text
idle
waitingForDevice
pairing
success
failed
timeout
```

注意：遥控器权限和分享通常涉及云端账号体系，删除/对码可能涉及设备本地协议。Repository 要能组合 cloud API 和 native protocol。

## 7.5 配件管理流程

```text
Security Center
→ Sensor manage
→ Accessory List
→ Delete Accessory
→ Check BLE Connected
→ Native Delete Command
→ Refresh Safety Snapshot
```

配件删除要严格做前置校验：

- 当前设备是否存在。
- 当前用户是否有权限。
- BLE 是否连接。
- 设备是否处于允许删除的状态。
- 删除后是否需要同步云端。

## 8. 数据模型建议

## 8.1 Device

```dart
class Device {
  final String id;
  final String name;
  final DoorType doorType;
  final DeviceType deviceType;
  final DeviceOnlineState onlineState;
  final BleConnectionState bleState;
  final DoorState doorState;
  final int cycleCount;
  final int remainingLifePercent;
  final DateTime? lastSeenAt;
}
```

## 8.2 SafetySensor

```dart
class SafetySensor {
  final String id;
  final String name;
  final SensorType type;
  final SensorPosition position;
  final SensorHealthStatus status;
  final int? batteryPercent;
  final bool isOnline;
  final DateTime? lastUpdatedAt;
}
```

## 8.3 OperationRecord

```dart
class OperationRecord {
  final String id;
  final String deviceId;
  final RecordType type;
  final String title;
  final String? operatorName;
  final DateTime occurredAt;
  final Map<String, Object?> metadata;
}
```

## 9. 错误体系

统一错误模型：

```text
AppError
├─ PermissionDenied
├─ BluetoothUnavailable
├─ BluetoothDisconnected
├─ DeviceOffline
├─ DeviceBusy
├─ CommandTimeout
├─ ProvisioningFailed
├─ PairingFailed
├─ AccessDenied
├─ NetworkUnavailable
├─ ServerError
└─ Unknown
```

每个错误包含：

```text
code
message
userAction
nativeCode?
requestId?
deviceId?
retryable
```

UI 不直接判断 nativeCode，而是判断 `userAction`：

```text
openSettings
connectBluetooth
retry
contactSupport
none
```

## 10. 权限设计

权限集中管理，避免每个页面各自申请。

权限类型：

- Bluetooth scan/connect。
- Location，Android BLE 扫描可能涉及。
- Camera，用于扫码。
- Local Network，iOS 配网/局域网发现可能涉及。
- Notification，门未关提醒和告警通知。

权限策略：

- 页面进入时只检查，不强行弹权限。
- 用户触发具体能力时再申请权限。
- 权限被永久拒绝时，引导到系统设置。
- 权限快照存入 Application 层状态，供页面展示阻断原因。

## 11. 缓存与离线策略

建议本地缓存：

- 设备列表和最近状态。
- 最近一次安全中心快照。
- 操作记录最近 N 条。
- 用户基本资料。
- 设备参数缓存。

策略：

- 首页优先显示缓存，再刷新云端和硬件状态。
- 控制页的门体状态以硬件实时事件优先。
- 安全中心离线时展示最后更新时间，避免误以为是实时数据。
- 所有控制类操作不做离线队列，必须实时发送并确认。

## 12. 日志与诊断

产品有售后排查场景，建议第一期就打好诊断底座。

日志分类：

- App lifecycle。
- Auth/session。
- Device discovery。
- BLE connection。
- Command request/response。
- Provisioning。
- Safety center。
- Transmitter pairing。
- Accessory management。
- API request summary。

日志要求：

- 每次硬件操作带 `requestId`。
- Flutter 和原生日志共用同一个 requestId。
- 敏感数据脱敏，如 token、Wi-Fi 密码、设备密钥。
- 支持导出诊断包给售后。

## 13. 安全设计

- token 存 Secure Storage / Keychain / Android Keystore。
- Wi-Fi 密码只在配网流程短暂使用，不落库。
- 设备密钥和绑定凭证使用安全存储。
- 分享权限由服务端校验，客户端只做展示和交互限制。
- 硬件指令必须校验当前用户是否拥有设备操作权限。
- 诊断日志默认脱敏。

## 14. 测试策略

## 14.1 Flutter 测试

- Domain use case 单元测试。
- Repository mock 测试。
- Controller/provider 状态流测试。
- Widget golden test：空状态、连接失败、安全中心离线、蓝牙阻断、对码成功/失败。
- 路由测试：登录态、设备详情、安全中心详情。

## 14.2 原生测试

- 协议编解码单元测试。
- BLE 状态机测试。
- 配网超时/重试测试。
- Pigeon bridge contract 测试。
- 权限状态测试。

## 14.3 联调测试

- Mock hardware mode：Flutter 全流程可跑通。
- Simulated native mode：原生返回固定扫描结果、状态、错误码。
- Real device mode：真实设备联调。

## 15. 开发里程碑

### Phase 0：工程底座

- 初始化 Flutter 项目。
- 配置 FVM、lint、格式化、CI。
- 建立 feature-first 目录结构。
- 建立路由、主题、国际化、日志、错误模型。
- 建立 Pigeon bridge 初版和 mock gateway。

### Phase 1：核心闭环

- 设备添加主流程。
- 首页设备列表。
- 控制页开/停/关。
- BLE 连接状态事件。
- 基础设备参数读取。

### Phase 2：设置与遥控器

- 设置页。
- 遥控器列表、对码、重命名、删除。
- 门未关提醒开关与时长弹层。
- 常用参数读写。

### Phase 3：安全中心与配件

- 安全中心首页和详情。
- 传感器状态、电量、离线态。
- 配件管理与删除。
- 蓝牙未连接阻断提示。

### Phase 4：记录、账号、售后诊断

- 操作记录/历史记录。
- 用户资料、第三方账号、账户安全。
- 诊断日志导出。
- 异常场景完善。

## 16. 风险与应对

| 风险 | 影响 | 应对 |
| --- | --- | --- |
| BLE 行为 iOS/Android 差异大 | 联调周期不可控 | 原生层做统一状态机，Flutter 只消费标准事件 |
| 配网流程失败原因复杂 | 用户体验差，售后压力大 | 错误码归一化，提供可操作提示和诊断日志 |
| UI 开发等待硬件 | 进度阻塞 | mock gateway 和 simulated native mode 先行 |
| 安全中心状态多 | 页面逻辑膨胀 | 独立 feature + Evaluation 模型 + SafetyGuard |
| 原生 channel 手写易错 | 运行时问题多 | 使用 Pigeon 生成类型安全接口 |
| 控制指令重复点击 | 门体状态混乱 | requestId、pending 状态、防抖、超时确认 |

## 17. 推荐落地规范

- 所有 feature 必须有 `domain/application/data/presentation` 四段，简单 feature 可合并但不反向依赖。
- UI 不允许直接 import `platform_bridge/pigeon` 生成类。
- 原生错误码只在 data/platform 层转换，不穿透到页面。
- 硬件操作必须带 requestId。
- 控制类按钮必须有 pending/disabled 状态。
- 蓝牙连接、设备在线、用户权限的判断统一放 guard/use case。
- 新增页面必须覆盖 loading/empty/error/offline 四类状态。
- Mock gateway 必须长期保留，用于开发、测试、演示。

## 18. 第一版工程交付物建议

```text
.fluttersdk / .fvmrc
analysis_options.yaml
lib/app/router/app_router.dart
lib/app/theme/app_theme.dart
lib/core/errors/app_error.dart
lib/core/logging/app_logger.dart
lib/platform_bridge/hardware_gateway.dart
lib/platform_bridge/mock_hardware_gateway.dart
lib/platform_bridge/pigeon/hardware_api.dart
lib/features/add_device/...
lib/features/home/...
lib/features/device_control/...
lib/features/security_center/...
ios/Runner/FLINXHardware/...
android/app/src/main/.../flinxhardware/...
test/features/.../controller_test.dart
```

## 19. 架构验收标准

第一阶段完成后，应该能做到：

- 没有真实硬件时，App 可通过 mock gateway 完整跑通添加设备、首页、控制、安全中心主要状态。
- 接入真实硬件时，只替换 `HardwareGateway` 实现，不改 UI 页面。
- 任一硬件错误都能映射为用户可理解的提示。
- 安全中心离线、蓝牙未连接、设备离线等异常态可稳定复现。
- Flutter 和原生日志能通过 requestId 串起一次完整操作。

## 20. 参考资料

- Flutter App Architecture Guide: https://docs.flutter.dev/app-architecture/guide
- Flutter Platform Channels: https://docs.flutter.dev/platform-integration/platform-channels
- go_router package: https://pub.dev/packages/go_router
- FVM package: https://pub.dev/packages/fvm
