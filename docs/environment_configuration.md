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

HTTP Proxy 测试配置位于“账号 → 关于 → 硬件诊断 → HTTP Proxy”，Debug、Profile
和 Release 构建均可使用。页面中的开关是唯一的代理控制来源：开启后，所有后续
HTTP 请求使用页面填写的 Host/IP 与端口；关闭后直连。Android 不会再自动读取手机
Wi-Fi 的系统代理，因此系统代理不会覆盖页面配置。

配置保存在应用 Application Support 目录的 `network_proxy_settings.json` 中，应用
重启后仍然保留。默认状态为关闭；文件缺失、损坏或配置非法时会回退为关闭状态。
Host/IP 只填写主机名、IPv4 或 IPv6 literal，不包含协议、路径或端口。页面不会发起
额外的连通性测试，实际业务请求负责验证代理是否可用。

代理仅用于测试。请先在设备中安装并信任 Charles、Proxyman 或 mitmproxy 等工具的
根证书；应用始终执行系统 HTTPS 证书校验，不提供无效证书放行，也不支持代理账号
密码。

`FLINX_CLIENT_AUTHORIZATION` 会随移动端应用分发，不能作为真正的服务端秘密。服务端必须把它视为公开客户端标识，并继续实施用户认证、授权、限流与滥用防护。
