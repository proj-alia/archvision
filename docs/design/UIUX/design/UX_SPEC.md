# 运维控制台交互规范

控制台以真实服务状态、认证命令和回执支持管理操作。视觉规则仅适用于管理界面；原型演示范围见[目录说明](../README.md)。

## 信息架构（14 个独立路由）

| 工作台 | 持续身份系统 | 连接与能力 | 配置与运行 |
|---|---|---|---|
| `/overview` 运行概览 | `/identity` 身份与人格 | `/platforms` 接入渠道 | `/config` 配置文件 |
| `/console` 测试沙盒 | `/memory` 记忆管理 | `/models` 模型服务 | `/tasks` 自动化任务 |
| `/chat` 正式聊天 | | | |
| | | `/extensions` 扩展管理 | `/data` 数据与日志 |
| | | `/deps` 依赖管理 | `/governance` 权限与审批 |
| | | | `/settings` 系统设置 |

路由由前端导航实现，数据和操作对接下列应用接口。

## 页面级核心布局

- `概览`：4 个小型真实指标 → 事件趋势 → 待办列表 → 资源入口；不出现营销大横幅。
- `扩展管理`：顶部 Plugins / Market / Skills / MCP / Commands；已安装为「左目录右参数」主从布局；市场为带搜索与分类的紧凑卡片目录；安装前确认依赖与权限。
- `配置文件`：档案选择器 + 垂直子导航 + 右侧多节表单 + Dirty/Save；人格为版本引用而非复制 Prompt；具体插件配置放在扩展中。
- `接入渠道`：按已安装 ConnectorDefinition 发现类型，展示实例列表 + 定义驱动配置/认证/状态；不维护 QQ 等平台枚举，不要求另外安装前端插件。后台连接测试结果不可由客户端编造。
- `正式聊天`：内置 WebChat，部署并完成用户认证/模型配置后可用；会话列表、真实消息、输入/停止、历史恢复及实际交付状态。复用通用交互契约，普通聊天权限不自动获得控制台管理权限；缺模型/未登录/断线明确提示，不输出模拟答复。
- `模型服务`：提供商列表 + 详情配置（endpoint / 秘钥重置 / 模型 / 超时 / 回退）；秘钥只可替换不可回显。
- `依赖管理`：表格展示当前版本、目标版本、兼容性、可更新状态、单个和批量操作。
- `数据与日志`：统计 / 会话 / 日志 / 追踪；追踪默认列表 + 选中详情。真实实现必须服务端筛选分页。
- `沙盒`：输入、选择配置、模拟执行步骤、输出、Trace 关联；明确的隔离标签。
- `记忆管理`：索引、分类、来源、版本与修订请求；禁止显示无定义的「记忆健康 92%」。
- `身份与人格`：稳定 ID、版本化人格、变更比对与回滚；当前关切使用经授权的状态投影，与长期偏好分开显示。
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
- `listConnectorDefinitions() → {items:[definitionRef,displayName,availability]}`，来自包内已校验声明，不依赖平台连接成功。
- `createConnector({definitionRef,config,expectedInstallationRevision,idempotencyKey}) → {id,configurationRevision,status}`；初始禁用，凭据另行写入受控槽。
- `getConnector(id) → {definition,configProjection,credentialStatus,configurationRevision,runtimeRevision,appliedConfigurationRevision,status}`；只返回获准的脱敏投影。
- `validateConnectorConfig(id,draft) → {valid,fieldErrors}`、`saveConnectorConfig(id,{draft,expectedRevision,idempotencyKey}) → {configurationRevision,reconnectRequired}`。
- `listConnectors()`、`testConnector(id,{expectedRevision,idempotencyKey})`、`setConnectorState(id,{command,expectedRevision,idempotencyKey})`、`getConnectorStatus(id)`；接单返回 operationId，异步结果由服务端关联。
- `beginConnectorSetup(id,{expectedRevision,idempotencyKey})`、`submitConnectorSetup(id,{setupId,expectedRevision,stepId,stepRevision,input,idempotencyKey})`、`cancelConnectorSetup(id,{setupId,expectedRevision,idempotencyKey})`、`pollConnectorSetup(id,setupId)`；按实例权限返回步骤/期限/脱敏结果。
- `listModelProviders()`, `updateProvider(id,{keyReplacement,...})`, `testProvider(id)`
- `listTraces({query,filters,cursor})`, `getTrace(id)`
- `requestApproval(action)`, `decideApproval({requestId,expectedVersion,decision,scope})`

**禁止**在浏览器侧相信 `enabled`、`approved` 和 `installed` 的本地临时值；以服务端结果与版本号为唯一可信依据。

### 自描述连接配置

本节 Connector 接口仅用于交互接入。浏览器等工具仍在扩展/能力页面查看参数、权限、可用性和执行结果，不要求先创建聊天连接；包级 configSchema 可复用配置组件。一个包的交互、工具和渲染贡献分别呈现可用性，不能用一个“已连接”替代全部状态。未知平台通过已安装定义发现，无硬编码平台列表。

扩展目录明确展示“平台交互协议插件”“工具插件”等功能标签；按已验证贡献推导，允许同一包具有多个标签。角色客户端是用户实际交流的外部应用，不称作 WebUI 配置面板。连接详情区分“适配代码运行位置”和“外部客户端在线情况”，显示支持/实际协商的外部协议、必需与可选能力、受影响贡献及授权路由投影；不能用服务端运行就推定桌面客户端在线。

getExtension 的 configSchema 表示包级设置；连接实例使用 ConnectorDefinition.configuration_schema，不复制包级配置到每个账号。表单标签/分组/帮助由 ui_hints 提供，配置规则由 Schema 决定，保存时服务器再次验证。密钥使用独立写入控件，只显示是否已设置。复杂结构明确进入结构化编辑或所需面板，不能静默隐藏、清空或丢弃字段。

创建→编辑/验证→保存→认证（需要时）→测试→显式连接；这些操作和状态分别显示，测试不等于启用。展示安装/启用、配置、认证、连接和能力可用性；已保存新版本但旧连接尚未停止时，不显示“新配置已生效”。同一类型可建多个实例，名称只作显示，不用于账号合并。

扫码/配对通过 SetupSession 的通用 form/qr/link/notice 步骤显示，包含过期、取消、刷新结果和字段错误；不得在前端编造 succeeded 或自行延长挑战有效期。管理服务可就绪而账号未连接，保证登录面板可用。关闭页签不停止服务端连接；client 执行位置的真实在线依赖另行显示。

特殊面板按资源摘要装载到隔离上下文，allowed_operations 限定可请求的应用管理操作；宿主桥只调用 ConnectorManager，不向面板暴露 provider 方法/绑定或主窗口凭据。应用仍逐次验证操作者和实例权限，先合法提交配置/代次再操作外部连接。面板不能自报成功。面板失败时保留宿主的状态/断开/重试入口。基本表单无需插件前端代码；一个安装包可以同时携带适配实现、声明和可选面板。

平台配置和身份/参与者路由分别受权管理，选择一个模型文件不等于选择 ALIA 身份。客户端协议不兼容、无聊天接口、只支持渲染、动作映射缺失、可选能力失效各有具体诊断；可用文字路径不显示成“完整角色能力已就绪”。SDK 操作预览如会播放/截屏，应走受控表达或动作流程，不能伪装成无副作用的连接测试。

`/chat` 是真实交互，`/console` 是隔离实验。消息已提交、模型生成中、传输受理、界面已显示及用户理解不得合并为“成功”。浏览器刷新恢复合法历史与 cursor，不重放旧发送。当前 HTML 原型仍只演示旧 13 个运维页面，未实现本节新流程，不能作为验收证据。

当前关切的查看与管理复用身份状态、配置和 Trace 的应用边界；不新增独立权限或公开路由。显示可用依据摘要、有效范围、仍待处理/已缓解/已放弃/过期或暂不可用，不展示未经校准的“欲望百分比”。“不再跟进此问题”提交有明确对象和范围的命令，服务端验证后再更新；它不表示问题已解决、取消所有任务或删除数据。人格偏好与定义引用的变更提供语义差异，规则已发布不标为人格已采用。沙盒里的合成需要干预只存在于隔离夹具，不能直写真实身份状态。

## UI 验收目标

- [ ] 控制台以可操作导航、列表、表单和反馈呈现管理任务，避免装饰挤占操作。
- [ ] 左侧全局导航 + 内部二级导航逻辑清楚、适合管理工作流。
- [ ] 扩展：检索/排序/已安装/市场/配置/安装审查/停用卸载安全操作均能完整走通。
- [ ] 配置：分区、schema、脏表单、验证、保存、错误、撤销、离开保护齐全。
- [ ] 依赖：表格、版本差异、确认、安装状态、失败回滚入口存在。
- [ ] Trace：实时/历史独立，服务端过滤分页，选中加载详情，不用卡片代替记录。
- [ ] 模型与渠道：凭据不回显、连接状态区别于配置状态。
- [ ] 未知连接定义自动生成配置页；同契约多提供者、多账号不串线，普通表单与特殊面板共用服务端验证。
- [ ] 认证挑战过期/取消、配置升级、页面关闭、面板故障与旧回调有明确状态，不虚构连接结果。
- [ ] `/chat` 真实聊天与 `/console` 沙盒可明确区分；没有社区平台插件也能完成授权的 WebChat 闭环。
- [ ] 身份/记忆/关系不与运行时 Provider/Plugin 混淆。
- [ ] 当前关切、长期偏好与任务分别呈现；未评估/不可访问不伪装为空，无直接编辑强度或绕过人格确认的入口。
- [ ] 所有危险操作服务端鉴权与审计，前端明确等待返回结果。
- [ ] 响应式：360、390、768、1280、1440px 可交互，桌面与移动端信息结构一致。
- [ ] 状态：loading / empty / error / retry / success / unauthorized / unsaved changes。
- [ ] 用实际 Playwright/E2E 记录验证，不以 CSS 截图代替功能测试。
