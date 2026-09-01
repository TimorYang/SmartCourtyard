# REST 业务错误消息审计

本记录对应 REST 业务成功条件和 HTTP 400 错误消息统一变更。统一规则为：只有
`code == 200 && success == true` 才成功；HTTP 200 业务失败和所有接口的 HTTP 400
消息均沿 RemoteDataSource → Repository → `AppError.userMessage` 透传。用户主动操作
优先显示后端消息，消息缺失时使用本地化 fallback；自动加载和后台刷新不新增
Toast。HTTP 401、403、408、429 和 5xx 仍使用原有分类，不展示响应体消息。

## 原本使用固定本地文案、忽略后端业务消息

| 请求或入口 | 原行为 | 修复后行为 |
| --- | --- | --- |
| 所有 REST 接口的 HTTP 400 | Dio 提前抛错，响应体的 `msg` 未进入领域错误 | 公共 `NetworkException` 提取 `msg`/`message`，Repository 映射到 `AppError.userMessage`；登录、保存、删除和控制等主动操作优先展示该消息 |
| 账户注销 | Controller 返回布尔值，页面固定显示注销失败 | Controller 保留最近一次 `AppError`；页面显示后端消息或注销本地化 fallback |
| 昵称、头像、地区、语言保存 | 页面只根据布尔结果显示固定失败文案 | 保存失败保留 `AppError`；后端消息优先，字段对应的本地化文案兜底 |
| 登录设备删除、接收设备删除 | 页面捕获失败后固定显示删除失败 | 直接解析捕获的 `AppError`，后端消息优先 |
| 首页设备置顶、解绑、重命名、移动、封面更新 | Dialog/Page 吞掉异常或固定显示失败 | 捕获原始 `AppError` 并统一使用后端消息优先、本地化 fallback |
| 场景创建、删除、重命名 | 固定英文或本地失败提示覆盖业务消息 | 使用场景操作对应的中英文 fallback，并优先显示后端消息 |
| 通知全部已读 | Controller 只返回 `bool`，页面固定显示失败 | Controller 返回具体 `AppError`；页面优先显示后端消息 |
| 安全传感器删除 | 页面固定显示删除失败 | 页面显示后端业务消息，缺失时使用安全传感器删除 fallback |
| 设置更新 | Controller 将异常字符串写入状态或只返回 `false` | 状态仅保留可展示的业务消息；页面已有本地化文案继续作为 fallback |

## 原本既没有本地 fallback、也没有使用后端消息

| 请求或入口 | 原行为 | 修复后行为 |
| --- | --- | --- |
| 门详情及遥控器管理状态 | `error.toString()` 进入 application state，可能暴露实现类型，且没有稳定 UI 文案 | 仅提取 `AppError.userMessage`；没有业务消息时留空，由对应 UI 状态使用本地化文案 |
| 设备能力、门设置加载状态 | `error.toString()` 直接保存，非 `AppError` 也可能进入 UI | 仅保存可展示业务消息；自动加载仍只更新错误态，不弹 Toast |
| 通知全部已读的未知异常 | 只返回 `false`，错误原因完全丢失 | 返回稳定 `AppError`，由页面提供本地化 fallback |

## 不适用项

BLE、设备协议、本地文件、图片选择器和系统权限错误没有 REST 业务信封，不套用
后端 `msg` 透传规则；这些路径继续使用已有的领域错误与本地化文案。
