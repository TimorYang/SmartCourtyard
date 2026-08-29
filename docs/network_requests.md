# 网络请求使用指南

本文说明 FLINX Flutter 项目的网络请求架构、环境配置、接口接入方式、错误处理、日志规范和测试要求。新增或修改 REST 接口前，请先阅读本文以及 `docs/flutter_architecture.md`。

## 1. 总体原则

项目使用以下组件：

- Dio：HTTP 客户端、超时、拦截器、代理和底层网络异常。
- Retrofit：声明接口并生成 Dio 调用代码。
- Freezed + json_serializable：解析服务端 JSON。
- Riverpod：组装 Dio、API、DataSource、Repository 和 UseCase。

网络调用必须遵循以下方向：

```text
Page / Widget
  → Controller / Provider
  → UseCase
  → Domain Repository
  → RepositoryImpl
  → RemoteDataSource
  → Retrofit API
  → Dio
```

禁止：

- Widget 或 Page 直接调用 Dio、Retrofit API 或 RemoteDataSource。
- Domain 层导入 Dio、Retrofit、JSON DTO 或 Flutter Widget。
- UI 根据 HTTP 状态码、DioException 或服务端原始错误码决定展示内容。
- 在日志中输出 token、密码、Wi-Fi 密码、设备密钥、Authorization 或完整请求体。

## 2. 目录职责

```text
lib/core/config/                     API 地址与环境配置
lib/core/network/                    Dio、通用响应、网络异常、代理和 Provider
lib/core/logging/                    统一日志接口
lib/features/<feature>/data/         API、DTO、DataSource、RepositoryImpl
lib/features/<feature>/domain/       Entity、Repository、UseCase、领域错误
lib/features/<feature>/application/  Riverpod 依赖组装和页面状态
```

通用网络能力放在 `core/network`。只服务于某个 feature 的接口协议、DTO 和异常必须留在该 feature 的 `data` 层。

## 3. 环境配置

服务地址通过编译期环境变量提供：

- `FLINX_API_ORIGIN`：服务 origin，例如 `https://api.example.com`。
- `FLINX_API_PATH_PREFIX`：REST 公共路径前缀，例如 `/api/force-door`。
- `FLINX_CLIENT_AUTHORIZATION`：当前认证握手所需的 Basic 凭据部分。

本地开发时复制示例文件：

```sh
cp config/env/dev.json.example config/env/dev.json
```

填写本地文件后运行：

```sh
flutter run --dart-define-from-file=config/env/dev.json
```

构建和测试示例：

```sh
flutter test --dart-define-from-file=config/env/test.json
flutter build ipa --dart-define-from-file=config/env/prod.json
flutter build appbundle --dart-define-from-file=config/env/prod.json
```

`config/env/*.json` 已被 Git 忽略，只提交 `*.json.example`。不要把真实凭据提交到仓库。

`AppApiConfiguration` 会校验 origin 和路径前缀，并组合出 Dio 使用的 `baseUrl`。Retrofit 接口路径应写成相对于该 `baseUrl` 的路径，不要重复公共前缀。

更完整的环境与抓包说明见 `docs/environment_configuration.md`。

## 4. Dio 的统一配置

业务代码通过 `dioProvider` 获取共享 Dio 实例，不要自行创建 Dio。

当前统一配置包括：

- 连接、发送、接收超时均为 15 秒。
- 请求与响应默认使用 JSON。
- 从请求 `extra` 读取 `requestId`，写入 `X-Request-Id` 请求头。
- 记录请求开始、完成和失败日志。
- Debug 模式下按 `NetworkDebugSettings` 配置抓包代理。

Provider 的典型依赖关系：

```dart
final featureApiProvider = Provider<FeatureApi>((ref) {
  return FeatureApi(ref.watch(dioProvider));
});
```

除独立探测或测试替身外，不要使用 `Dio()` 绕过统一配置，否则请求不会自动获得超时、关联 ID、日志和调试代理能力。

## 5. 服务端响应模型

通用响应使用 `ApiEnvelopeDto<T>`：

```json
{
  "code": 200,
  "success": true,
  "msg": null,
  "data": {}
}
```

其中：

- `code`：服务端业务响应码。
- `success`：服务端业务成功标志。
- `msg`：服务端消息，仅用于诊断或映射，不直接展示给用户。
- `data`：接口数据。

有固定结构的 `data` 必须定义强类型 DTO。只有服务端明确返回布尔值或暂时没有固定结构时，才使用 `dynamic`。

## 6. 新增接口的标准步骤

以下示例沿用当前注册模块的实现方式。

### 6.1 定义网络 DTO

DTO 表示服务端传输格式，只放在 Data 层：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'example_response_dto.freezed.dart';
part 'example_response_dto.g.dart';

@freezed
abstract class ExampleResponseDto with _$ExampleResponseDto {
  const factory ExampleResponseDto({
    required String id,
    required String status,
  }) = _ExampleResponseDto;

  factory ExampleResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ExampleResponseDtoFromJson(json);
}
```

DTO 字段名应忠实反映接口协议。服务端字段与 Dart 命名不一致时使用 `@JsonKey(name: ...)`，不要为了迁就 UI 修改 DTO 语义。

### 6.2 定义 Retrofit API

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/network/api_envelope_dto.dart';
import '../dto/example_response_dto.dart';

part 'feature_api.g.dart';

@RestApi()
abstract class FeatureApi {
  factory FeatureApi(Dio dio, {String? baseUrl}) = _FeatureApi;

  @GET('app/example/{id}')
  Future<ApiEnvelopeDto<ExampleResponseDto>> fetchExample(
    @Path('id') String id,
    @DioOptions() Options options,
  );
}
```

接口路径不要以 `/` 开头，避免覆盖 `AppApiConfiguration` 中的公共路径前缀。

### 6.3 在 RemoteDataSource 校验协议

RemoteDataSource 负责：

- 组装 Header、Query 和 Body。
- 调用 Retrofit API。
- 校验 `code`、`success`、`data` 和业务协议字段。
- 把 `DioException` 转换为 Data 层异常。

```dart
Future<ExampleResponseDto> fetchExample({
  required String id,
  required String requestId,
}) async {
  try {
    final response = await api.fetchExample(
      id,
      Options(
        extra: {NetworkRequestExtras.requestId: requestId},
      ),
    );
    final data = response.data;
    if (response.code != 200 || !response.success || data == null) {
      throw const ExampleRemoteException.invalidResponse();
    }
    return data;
  } on DioException catch (error) {
    throw ExampleRemoteException.fromNetwork(
      NetworkException.fromDio(error),
    );
  } on ExampleRemoteException {
    rethrow;
  }
}
```

不要在这里返回 UI 文案，也不要让 DioException 穿透到 Repository、UseCase 或 UI。

### 6.4 DTO 转换为 Domain Entity

DTO 是服务端协议模型，Domain Entity 是业务模型。转换应发生在 Data 层的 Mapper 或 RepositoryImpl 中：

```dart
final dto = await remoteDataSource.fetchExample(
  id: id,
  requestId: requestId,
);

return Example(
  id: dto.id,
  state: ExampleState.fromWireValue(dto.status),
);
```

转换规则属于 feature 的业务接入，不属于通用 JSON 基础设施。复杂或多处复用的转换应抽到 `data/mappers/`；简单且只使用一次的转换可以留在 RepositoryImpl。

### 6.5 Repository 映射统一 AppError

RepositoryImpl 应把 Data 层异常映射成项目统一的 `AppError`：

```dart
try {
  // 调用 DataSource 并映射 Entity
} on ExampleRemoteException catch (error, stackTrace) {
  logger.error(
    'Failed to fetch example.',
    requestId: requestId,
    error: error,
    stackTrace: stackTrace,
  );

  throw AppError(
    code: AppErrorCode.networkUnavailable,
    messageKey: 'example.networkUnavailable',
    action: AppErrorAction.retry,
    requestId: requestId,
    retryable: true,
  );
}
```

HTTP 401/403、超时、断网、服务端失败和响应格式错误应根据业务语义映射成稳定的领域错误。UI 只能消费 `AppError` 或 Application 层进一步转换后的状态。

### 6.6 注册 Riverpod Provider

依赖从底层向上组装：

```dart
final featureApiProvider = Provider<FeatureApi>((ref) {
  return FeatureApi(ref.watch(dioProvider));
});

final featureRemoteDataSourceProvider = Provider<FeatureRemoteDataSource>(
  (ref) => FeatureRemoteDataSourceImpl(
    api: ref.watch(featureApiProvider),
  ),
);

final featureRepositoryProvider = Provider<FeatureRepository>(
  (ref) => FeatureRepositoryImpl(
    remoteDataSource: ref.watch(featureRemoteDataSourceProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);
```

测试时通过 Provider override 注入 Fake API 或 Fake Repository，不要让 Widget Test 访问真实网络。

## 7. requestId 规范

每个业务操作必须生成一个 `requestId`，同一操作跨 UseCase、Repository、DataSource、HTTP Header 和日志时应复用同一个值。

传给 Dio 的方式：

```dart
Options(
  extra: {
    NetworkRequestExtras.requestId: requestId,
  },
)
```

Dio 拦截器会将其写入：

```text
X-Request-Id: <requestId>
```

建议格式：

```text
<feature>-<operation>-<UTC microseconds>
```

例如：

```text
register-verify-code-1783843200000000
```

不要为一次业务操作的每一层重新生成不同 ID。

## 8. Authorization 与敏感信息

需要认证信息时，由 DataSource 通过 `Options.headers` 添加：

```dart
Options(
  headers: {
    'authorization': 'Basic $clientAuthorization',
  },
  extra: {
    NetworkRequestExtras.requestId: requestId,
  },
)
```

规则：

- 不在 Widget、Controller 或 UseCase 中拼接 Authorization。
- 用户 token 和设备密钥必须从安全存储读取。
- 不记录 Authorization、token、密码、密钥、nonce 或完整请求体。
- 移动端内置的客户端凭据不能视为服务端秘密，服务端仍需进行鉴权、授权、限流和滥用防护。

## 9. JSON 与代码生成

修改以下内容后必须重新生成代码：

- Freezed DTO。
- `fromJson` / `toJson` 模型。
- Retrofit API 定义。

执行：

```sh
dart run build_runner build
```

如果存在冲突的旧生成文件：

```sh
dart run build_runner build --delete-conflicting-outputs
```

生成文件需要提交到仓库。提交前执行：

```sh
bash tool/verify_generated.sh
```

不要手工修改 `.g.dart` 或 `.freezed.dart`。

## 10. 错误分层

错误应逐层收敛：

```text
DioException
  → NetworkException
  → FeatureRemoteException
  → AppError / Domain Error
  → Controller State
  → 本地化 UI 文案
```

各层职责：

- `NetworkException`：表达超时、连接、证书、取消和 HTTP 状态等通用网络类别。
- `FeatureRemoteException`：表达某个接口的配置错误、网络错误或协议响应错误。
- `AppError`：表达业务可理解的稳定错误码、重试性和推荐动作。
- Controller：将错误转换成页面状态或本地化 message key。
- UI：展示本地化文案，不解析底层异常。

服务端返回 `success: false` 即使 HTTP 状态为 200，也应视为业务失败并由 DataSource 校验。

## 11. 日志规范

统一使用 `AppLogger`，并携带相同的 `requestId`：

```dart
logger.info(
  'Fetched example.',
  requestId: requestId,
  context: {
    'entityId': entityId,
  },
);
```

允许记录：

- HTTP method、相对路径和状态码。
- requestId、非敏感实体 ID、耗时和错误类别。
- 对排障必要且已经脱敏的上下文。

禁止记录：

- 请求或响应的完整 Body。
- Authorization、token、密码、Wi-Fi 密码和设备密钥。
- RSA 私密材料或可用于重放认证的信息。

## 12. 抓包调试

Debug 构建可通过 `lib/core/network/network_debug_settings.dart` 配置代理：

```dart
static const proxy = 'PROXY 192.168.1.10:9090';
static const allowInvalidProxyCertificates = false;
```

真机必须使用电脑的局域网 IP；模拟器可以按平台情况使用 `127.0.0.1`。优先安装并信任抓包工具根证书，不要长期启用无效证书放行。

代理和证书放行只在 Debug 模式生效。个人代理地址不应提交到共享分支。

## 13. 启动网络探测

`StartupNetworkAccessProbe` 在应用启动后发起一次轻量请求，用于在首次安装时触发系统网络访问提示。

该探测：

- 不作为网络可用性的判断依据。
- 失败不会阻止应用启动。
- 不应承载业务数据。
- 不应替代真实请求的错误处理。

业务页面不得根据探测结果决定是否允许用户操作。

## 14. 测试要求

新增网络接口至少应覆盖：

1. DTO 能解析服务端正常响应。
2. 必填字段缺失或类型错误时解析失败。
3. 未知字段不会破坏兼容性。
4. DataSource 正确发送 Header、Body、Query 和 requestId。
5. `success: false`、空 data 或非法协议字段被拒绝。
6. DioException 被转换成 Data 层异常。
7. Repository 将 DTO 映射成正确的 Domain Entity。
8. Repository 将异常映射成正确的 AppError。
9. Controller 覆盖 loading、success、error 和防重复提交状态。
10. Widget Test 使用 Provider override，不访问真实服务器。

常用命令：

```sh
dart run build_runner build
bash tool/verify_generated.sh
flutter analyze
flutter test
```

## 15. 提交前检查清单

- [ ] UI 没有直接调用 Dio、Retrofit 或 DataSource。
- [ ] Domain 层没有导入网络或 JSON 实现。
- [ ] Retrofit 路径没有以 `/` 开头。
- [ ] 固定结构的响应使用了强类型 DTO。
- [ ] DTO 到 Domain Entity 的映射位于 Data 层。
- [ ] DioException 没有穿透到 Application 或 UI。
- [ ] 请求携带 requestId，并在各层保持一致。
- [ ] 日志没有敏感字段或完整请求体。
- [ ] 生成文件已更新并提交。
- [ ] Provider 可以在测试中被替换。
- [ ] 静态分析和相关测试通过。
