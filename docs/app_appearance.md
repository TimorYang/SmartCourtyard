# 全局皮肤

FLINX 复用同一套页面、路由和业务状态，通过三套主题配置与资源映射换肤。
默认简约风，手动应用，与系统深浅色、账号和登录状态无关。

## 调整颜色与资源

- `lib/app/theme/skins/minimalist_skin.dart`：简约风基础配置；旧组件的不同色值仍保留在 `AppColors` 中，解析时保持原值。
- `lib/app/theme/skins/dark_skin.dart`：暗黑风深蓝纯色配置。
- `lib/app/theme/skins/technology_skin.dart`：科技风配置。只有门控内容背景使用淡紫、淡蓝渐变；按钮、列表、卡片、弹窗均为纯色。
- `lib/app/theme/app_skin_catalog.dart`：语义颜色映射、主题插值、系统栏和 `AppSkinAssets` 资源解析。
- `lib/app/theme/app_design_tokens.dart`：共享布局、字体和组件 token。页面使用 `context.colors` / `context.appText`，标准 Material 组件由 `AppTheme` 配置。
- `lib/app/theme/app_appearance_tokens.dart`：换肤页面样式。

不要在业务页面按皮肤 ID 分支配色。需要增加组件颜色时，在共享 token 中增加语义角色和简约风原值，并为其他皮肤配置对应颜色。主题过渡对原始组件颜色逐一插值，避免简约风在动画中跳色。

缺失切图使用本地化占位。简约风继续使用现有切图；门体动画、头像和第三方登录标识为共享原图。完整候选资源槽见 [skin_assets.md](skin_assets.md)。正式图片可直接放到列出的占位路径，可配套提供 `2.0x` / `3.0x`。尚未提供三套预览图和暗黑风、科技风专属切图，不将当前占位截图视为最终设计验收。

## 保存与切换

调用链：换肤页 → `AppSkinController` → 读写用例 → `AppSkinRepository` → 本地数据源。

仅在 Application Support 的 `app_skin_preference.json` 保存稳定的 `skinId`。
写入时先 flush 临时文件，再替换原文件；无记录、损坏记录、未知 ID 或读取失败均回退简约风。存储目录不可用时，应用皮肤返回失败而不伪装为已持久化。

启动先恢复语言和皮肤，再创建业务路由。预览不改变全局选择；应用时阻止重复提交，保存成功后才切换，失败保留原主题并显示本地化提示。登出和会话失效不会清理偏好。

`MaterialApp.router` 及路由实例保持稳定，切换只更新主题。遵循系统减少动画设置。系统栏由主题统一生成；无 AppBar 的欢迎页、扫码页使用 `FlinxSystemUi`，图片头部页面通过前景色配置图标明暗。

WebView 的 Flutter 容器、导航栏、加载条和原生容器背景随主题更新。远端 H5 页面自己的 CSS、系统权限弹窗与系统键盘由页面或平台控制，不注入未经约定的网页样式。

## 验证

2026-09-10：最终 `flutter analyze --no-pub` 通过；完整 Flutter 回归 **929 项通过**。

已验证：

- 缺失、损坏、未知偏好，读写失败及控制器重建后的恢复；实际文件写入失败不覆盖原偏好。
- 预览隔离、保存中禁用、保存失败提示和重复提交防护。
- 启动恢复后再创建路由；连续换肤保留输入、页面实例与待执行硬件请求。
- 登出、会话失效、切换账号后保留皮肤；系统减少动画设置变化。
- 三套皮肤的组件和真实页面状态截图（18 个页面/状态 × 3，共 54 张），含登录、欢迎、首页空态/离线、账户、添加设备、权限阻断、通知空态/加载/错误、门控就绪/操作中、安全中心、综合评估、传感器及换肤列表。
- 资源映射目录声明、缺失资源占位、门体原图保持。

命令：

```sh
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub --dart-define=SKIN_QA=true \
  test/features/appearance test/app/theme \
  test/features/device_control/presentation/pages/device_command_page_test.dart \
  test/features/security_center/presentation/pages/security_report_pages_test.dart
```

截图输出到 `build/skin_qa/`（不提交生成图片）。需要可读字体时，可附加 `--dart-define=SKIN_QA_FONT=/absolute/path/to/font.ttf`；字体仅供测试使用，不新增应用依赖。

仍需在 iOS / Android 真机检查系统栏、全面屏底部区域、键盘和弹窗；本次未安装到已连接的个人设备。正式资源提供后需要对所有页面补做最终视觉验收。当前截图覆盖主要页面和代表状态，并非全部路由的逐页截图。
