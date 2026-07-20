# 添加设备与 BLE 诊断日志

添加设备流程使用两个日志标识：

- `FLINX_BIND`：页面流转、设备密钥请求、鉴权结果、配网和云端绑定。
- `FLINX_BLE`：扫描、连接、GATT、原始帧、协议解析和 AES 解密。

每次添加设备会生成一个 `onboardingFlowId`。该值同时出现在 Flutter、HTTP、iOS 和 Android 日志中；同一流程的 `requestId` 格式为：

```text
<onboardingFlowId>:<operation>:<sequence>
```

## 开启详细协议日志

进入“账号 → 关于 → 硬件诊断”，开启“详细硬件诊断日志”。设置会保留到用户主动关闭。关闭时仍会记录流程节点、耗时和错误码，但不会输出 `rawHex` 或 `plainHex`。

AES Key、鉴权 Token、Wi-Fi 密码、Authorization 和设备凭据在任何模式下都不会写入日志。Wi-Fi 配网帧只记录长度和脱敏后的协议摘要。

## Android

同时查看绑定和 BLE 日志：

```sh
adb logcat | rg 'FLINX_BIND|FLINX_BLE'
```

定位单次流程：

```sh
adb logcat | rg 'FLINX_BIND|FLINX_BLE' | rg '<onboardingFlowId>'
```

原生 BLE 日志也可以使用 Tag 过滤：

```sh
adb logcat -s FLINX_BLE
```

Flutter 的 binding 日志由 Flutter Engine 输出，但每行都包含 `[FLINX_BIND]`，因此完整流程应使用前面的正则过滤方式。

## iOS

在 Console.app 或 Xcode 控制台中搜索：

```text
category == FLINX_BLE OR message CONTAINS FLINX_BIND
```

再追加 `onboardingFlowId` 即可限制到单次流程。原生 BLE 使用 `FLINX_BLE` OSLog category；Flutter 绑定日志包含 `[FLINX_BIND]` 前缀。

## 关键错误

- `authentication_decrypt_failed`：设备返回了合法的 AES 加密包，但服务端下发的 AES Key 无法解出与待处理鉴权命令、序列匹配的响应。该错误会立即结束鉴权，不再等待超时。
- `invalid_aes_key`：服务端 Key 不是 32 位十六进制 AES-128 Key。
- `command_timeout`：在超时时间内未收到可识别的设备响应。
- `authentication_failed`：响应成功解密，但设备明确拒绝鉴权。

排查 `authentication_decrypt_failed` 时，对照同一 flowId 下的 `aesKeyVersion`、设备 SN、原始密文长度、AES 模式和请求序列；不要尝试把真实 AES Key 写入日志。
