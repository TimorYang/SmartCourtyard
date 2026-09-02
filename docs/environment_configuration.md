# 环境配置

REST 服务根地址默认指向当前联调环境；可通过 `--dart-define-from-file` 覆盖为其他环境。

1. 复制 `config/env/dev.json.example` 为本机忽略的 `config/env/dev.json`。
2. 填写该环境的地址与授权值。
3. 使用对应文件运行或构建。

```sh
flutter run --dart-define-from-file=config/env/dev.json
flutter test --dart-define-from-file=config/env/test.json
flutter build ipa --dart-define-from-file=config/env/prod.json
flutter build appbundle --dart-define-from-file=config/env/prod.json
```

VS Code 的 Flutter 启动配置也会自动使用 `config/env/dev.json`。请在 Run and
Debug 中选择 `FLINX Dev`；编辑器中的直接 Run 入口也通过工作区设置传入同一份
环境文件。

打包时也必须显式传入环境文件，不能直接在 Xcode 中 Archive 或执行不带环境参数的
Flutter 构建。Ad Hoc iOS 包可以使用：

```sh
bash tool/build_ios_adhoc.sh --env config/env/dev.json
```

正式 iOS 包和 Android 包应使用已填写真实服务地址、授权值及 Google Client ID 的
本机忽略配置：

```sh
flutter build ipa --release --dart-define-from-file=config/env/prod.json
flutter build appbundle --release --dart-define-from-file=config/env/prod.json
flutter build apk --release --dart-define-from-file=config/env/prod.json
```

`config/env/prod.json`、`config/env/staging.json` 等真实环境文件不会提交到仓库；
应从对应的 `.example` 文件复制后，在本机填写真实值。

必填字段：

- `FLINX_API_ORIGIN`：仅包含 `http` 或 `https` 的服务 origin，例如 `https://api.example.com`。
- `FLINX_API_PATH_PREFIX`：所有 REST 接口共享的路径前缀，例如 `/api/force-door`。
- `FLINX_CLIENT_AUTHORIZATION`：当前 auth 握手使用的 Basic 凭据部分。
- `FLINX_FACEBOOK_APP_ID`：Facebook App ID。未配置时 Facebook 按钮保留，但不会调用 SDK。
- `FLINX_FACEBOOK_CLIENT_TOKEN`：Facebook Client Token。真实值只放在本机忽略的环境文件中。
- `FLINX_FACEBOOK_DISPLAY_NAME`：Meta 应用显示名称；启用 Facebook 登录时需与 App ID、Client Token 一起提供。
- `FLINX_GOOGLE_IOS_CLIENT_ID`：GCP 中登记 `com.feizhou.znty` 的 iOS OAuth Client ID；iOS 构建阶段会从该值自动生成 reversed client ID 回调 Scheme。
- `FLINX_GOOGLE_SERVER_CLIENT_ID`：GCP Web OAuth Client ID，同时作为 Google 登录的
  `serverClientId`，用于 Android 登录及后端授权码校验。
- `FLINX_GOOGLE_HOSTED_DOMAIN`：可选的 Google Workspace 托管域限制；普通账号登录保持为空。
- `FLINX_ENGAGELAB_APP_KEY`：极光 EngageLab AppKey；为空时推送能力安全禁用。
- `FLINX_ENGAGELAB_CHANNEL`：EngageLab 渠道名，例如 `developer` 或 `production`。
- `FLINX_ENGAGELAB_IOS_PRODUCTION`：iOS 是否使用生产 APNs 环境，开发/测试填写 `false`，正式包填写 `true`。

Facebook 的 App ID、Client Token、Display Name 和平台回调配置还需要同步填写到 Meta
开发者后台。iOS `Info.plist` 与 Android Facebook resources 会在 Flutter 构建时，
从同一份 `DART_DEFINES` 自动生成；仓库中的原生模板只保留占位标记，不要手工写入真实凭据。

Google 登录使用 Dart 编译期环境变量传入 Client ID，不需要提交
`GoogleService-Info.plist`。iOS 的 `Info.plist` 只保留回调 Scheme 模板，Flutter
构建时会从同一次 `DART_DEFINES` 注入的 `FLINX_GOOGLE_IOS_CLIENT_ID` 自动生成
对应 Scheme，因此不同环境不能绕过 Flutter 构建直接使用未配置的 Xcode Archive。
Android 需要在 GCP 登记包名 `com.feizhou.znty`，并为 Debug/Release 签名配置对应
SHA；未使用 `google-services.json` 时，Android 直接使用
`FLINX_GOOGLE_SERVER_CLIENT_ID`。

Google Client ID 属于公开客户端标识，不是服务端密钥；但本项目仍按环境配置规则，
将真实值保存在本机忽略的 `config/env/*.json` 中，提交的 `.example` 文件只保留占位值。

## 调试抓包

Android Debug 构建会读取设备当前的系统 HTTP 代理，并让 Dio 使用该代理，因此配置 Charles、Proxyman 或 mitmproxy 后无需在项目中填写电脑局域网 IP。修改手机 Wi-Fi 代理后，重新启动 App 以刷新代理地址。

iOS Debug 构建继续使用 `NetworkDebugSettings.proxy` 中的手动代理配置，格式为 Dart `HttpClient.findProxy` 使用的 `PROXY <电脑局域网 IP>:<端口>`。Android 不会读取该手动配置，两个平台的调试代理互不影响。

`NetworkDebugSettings.allowInvalidProxyCertificates` 仅用于尚未在设备安装抓包根证书时接受代理签发的 HTTPS 证书。它只在 debug 模式生效；release/profile 构建会忽略代理与证书放行配置。

优先在设备中安装并信任抓包工具根证书，然后仅设置代理，不要长期启用无效证书放行。

`FLINX_CLIENT_AUTHORIZATION` 会随移动端应用分发，不能作为真正的服务端秘密。服务端必须把它视为公开客户端标识，并继续实施用户认证、授权、限流与滥用防护。
