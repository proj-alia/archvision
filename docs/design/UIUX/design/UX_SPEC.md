# 运维控制台交互规范

控制台以真实服务状态、认证命令和回执支持管理操作。视觉规则仅适用于管理界面；原型演示范围见[目录说明](../README.md)。

## 信息架构（13 个独立路由）

| 工作台 | 持续身份系统 | 连接与能力 | 配置与运行 |
|---|---|---|---|
| `/overview` 运行概览 | `/identity` 身份与人格 | `/platforms` 接入渠道 | `/config` 配置文件 |
| `/console` 测试沙盒 | `/memory` 记忆管理 | `/models` 模型服务 | `/tasks` 自动化任务 |
| | | `/extensions` 扩展管理 | `/data` 数据与日志 |
| | | `/deps` 依赖管理 | `/governance` 权限与审批 |
| | | | `/settings` 系统设置 |

路由由前端导航实现，数据和操作对接下列应用接口。

## 页面级核心布局

- `概览`：4 个小型真实指标 → 事件趋势 → 待办列表 → 资源入口；不出现营销大横幅。
- `扩展管理`：顶部 Plugins / Market / Skills / MCP / Commands；已安装为「左目录右参数」主从布局；市场为带搜索与分类的紧凑卡片目录；安装前确认依赖与权限。
- `配置文件`：档案选择器 + 垂直子导航 + 右侧多节表单 + Dirty/Save；人格为版本引用而非复制 Prompt；具体插件配置放在扩展中。
- `接入渠道`：平台列表 + 连接详情（地址 / 凭据 / 会话隔离 / 连接测试）；后台连接测试结果不可由客户端编造。
- `模型服务`：提供商列表 + 详情配置（endpoint / 秘钥重置 / 模型 / 超时 / 回退）；秘钥只可替换不可回显。
- `依赖管理`：表格展示当前版本、目标版本、兼容性、可更新状态、单个和批量操作。
- `数据与日志`：统计 / 会话 / 日志 / 追踪；追踪默认列表 + 选中详情。真实实现必须服务端筛选分页。
- `沙盒`：输入、选择配置、模拟执行步骤、输出、Trace 关联；明确的隔离标签。
- `记忆管理`：索引、分类、来源、版本与修订请求；禁止显示无定义的「记忆健康 92%」。
- `身份与人格`：稳定 ID、版本化人格、变更比对与回滚。
- `审批`：请求标识、风险、作用域、操作者、有效期、确认与审计。

## 组件设计

- Sidebar 230px；Header 62px；底部状态栏 26px。
- Panel 细分割线与极轻阴影；8–9px 圆角。
- Button/Input：32–33px，高密度操作；触摸设备点击面积至少 40×40px。
- 左侧列表 / 右侧详情；窄屏改为可滚动的横向资源选择器，并采用单列详情。
- Badge 仅用于真实状态：已启用、已停用、待校验、加载失败、待审批。
- 错误状态为就地字段错误 + 页面级提示；Dirty 状态有明显保存与撤销。
- 危险操作必须二次确认；授权按钮不得直接绕过服务器决定。
- 不使用角色立绘、背景插画、大型渐变或空泛的拟人文案。

## 表单状态机

`idle → editing → validation → saving → saved / error`

- editing：页面出现「未保存」提示与撤销。
- validation：输入就地标错，不提交不合法配置。
- saving：提交按钮转为加载中并阻止重复提交。
- saved：以服务端返回的 revision 作为确认为准。
- error：保留用户输入，错误可定位、可重试。
- 切路由遇 Dirty：提示「保存 / 放弃 / 取消」。保存结果以服务端回执为准。

## 安装流程

`发现 → 展示来源和版本 → 依赖/许可/权限审查 → 安装 → 安装成功但未启用 → 单独授权 → 启用 → 可调用 → 停用/卸载`

安装和启用不应在同一步隐式完成；插件未安装、安装失败、缺依赖、权限拒绝等均是独立 UI 状态。

## 响应式

- ≥1000px：左固定主导航，资源详情使用双栏或双面板。
- 721–999px：缩小侧栏与表单 label 宽度，统计区为 2 列。
- ≤720px：抽屉主导航、单列内容、资源选择横向滚动、工具栏折行；表格允许自身局部横向滚动，但不能造成整页溢出。
- 390/360px 需人工测试操作可达性、底部按钮是否被遮挡。

## 可访问性

- 使用真实 button / input / select / dialog，支持键盘导航、label 关联、禁用状态与 aria-live 反馈。
- 语义色不能替代文字；区分「未连接」与「运行异常」。
- 实现时满足 WCAG 2.2 AA 对比度和键盘可用性，不能仅以本原型的浏览器无异常检查冒充通过。


## 前端应用接口设计

- `listExtensions({status,query,page}) → {items,total}`
- `getExtension(id) → {id,version,manifest,capabilities,configSchema,installed,enabled,diagnostic}`
- `planExtensionInstall(id,version) → {dependencies,permissions,sourceIntegrity,risks}`
- `installExtension({id,version,planRevision}) → {operationId,status}`
- `changeExtensionState(id,{enabled,expectedRevision}) → {revision,status}`
- `listConfigProfiles()`, `getConfigProfile(id)`, `validateConfigProfile(draft)`, `saveConfigProfile({draft,expectedRevision})`
- `listConnectors()`, `testConnector(id)`, `setConnectorState(id,command)`
- `listModelProviders()`, `updateProvider(id,{keyReplacement,...})`, `testProvider(id)`
- `listTraces({query,filters,cursor})`, `getTrace(id)`
- `requestApproval(action)`, `decideApproval({requestId,expectedVersion,decision,scope})`

**禁止**在浏览器侧相信 `enabled`、`approved` 和 `installed` 的本地临时值；以服务端结果与版本号为唯一可信依据。

## UI 验收目标

- [ ] 控制台以可操作导航、列表、表单和反馈呈现管理任务，避免装饰挤占操作。
- [ ] 左侧全局导航 + 内部二级导航逻辑清楚、适合管理工作流。
- [ ] 扩展：检索/排序/已安装/市场/配置/安装审查/停用卸载安全操作均能完整走通。
- [ ] 配置：分区、schema、脏表单、验证、保存、错误、撤销、离开保护齐全。
- [ ] 依赖：表格、版本差异、确认、安装状态、失败回滚入口存在。
- [ ] Trace：实时/历史独立，服务端过滤分页，选中加载详情，不用卡片代替记录。
- [ ] 模型与渠道：凭据不回显、连接状态区别于配置状态。
- [ ] 身份/记忆/关系不与运行时 Provider/Plugin 混淆。
- [ ] 所有危险操作服务端鉴权与审计，前端明确等待返回结果。
- [ ] 响应式：360、390、768、1280、1440px 可交互，桌面与移动端信息结构一致。
- [ ] 状态：loading / empty / error / retry / success / unauthorized / unsaved changes。
- [ ] 用实际 Playwright/E2E 记录验证，不以 CSS 截图代替功能测试。
