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

必填字段：

- `FLINX_API_ORIGIN`：仅包含 `http` 或 `https` 的服务 origin，例如 `https://api.example.com`。
- `FLINX_API_PATH_PREFIX`：所有 REST 接口共享的路径前缀，例如 `/api/force-door`。
- `FLINX_CLIENT_AUTHORIZATION`：当前 auth 握手使用的 Basic 凭据部分。
- `FLINX_FACEBOOK_APP_ID`：Facebook App ID。未配置时 Facebook 按钮保留，但不会调用 SDK。
- `FLINX_FACEBOOK_CLIENT_TOKEN`：Facebook Client Token。真实值只放在本机忽略的环境文件中。

Facebook 的 App ID、Client Token 和平台回调配置还需要同步填写到 Meta
开发者后台以及 Android `strings.xml`、iOS `Info.plist`。仓库中的原生值是
仅用于保证无配置构建可启动的占位值，不要提交真实凭据。

## 调试抓包

Android Debug 构建会读取设备当前的系统 HTTP 代理，并让 Dio 使用该代理，因此配置 Charles、Proxyman 或 mitmproxy 后无需在项目中填写电脑局域网 IP。修改手机 Wi-Fi 代理后，重新启动 App 以刷新代理地址。

iOS Debug 构建继续使用 `NetworkDebugSettings.proxy` 中的手动代理配置，格式为 Dart `HttpClient.findProxy` 使用的 `PROXY <电脑局域网 IP>:<端口>`。Android 不会读取该手动配置，两个平台的调试代理互不影响。

`NetworkDebugSettings.allowInvalidProxyCertificates` 仅用于尚未在设备安装抓包根证书时接受代理签发的 HTTPS 证书。它只在 debug 模式生效；release/profile 构建会忽略代理与证书放行配置。

优先在设备中安装并信任抓包工具根证书，然后仅设置代理，不要长期启用无效证书放行。

`FLINX_CLIENT_AUTHORIZATION` 会随移动端应用分发，不能作为真正的服务端秘密。服务端必须把它视为公开客户端标识，并继续实施用户认证、授权、限流与滥用防护。
