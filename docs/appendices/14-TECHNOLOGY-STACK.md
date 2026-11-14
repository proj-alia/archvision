# 专题附录 — Rust 核心与 React/Vite 技术栈

精确直接版本以 [机器清单](../../config/technology-stack.json) 为唯一来源，依赖解析、构建与平台验证尚未执行。

## 1. 目标与不变量

Rust 模块化单体 + PostgreSQL/pgvector + React/TypeScript/Vite；保持 core 1.0、扩展协议 1.0、AEIP 1.0 和 I01–I15。框架用于实现已确定的行为，不定义身份、人格或意识。

直接依赖采用清单中的精确版本候选。Rust 使用 Edition 2024。Rust/Cargo 真实工程建立后写入 rust-toolchain.toml 和 Cargo.lock；前端建立后写入精确 packageManager、直接依赖及 pnpm-lock.yaml。该清单不替代这些尚不存在的解析锁文件。

## 2. 层次与具体选择

| 层 | 技术 | 责任 |
|---|---|---|
| 领域 | Rust 纯类型、命令/事件、reducer | 身份、记忆、关系、信念、目标与不变量；同步、可回放 |
| 应用 | Tokio、Rust Port traits | 有界调度、取消、期限、任务、依赖与调用编排 |
| 网络适配 | Axum、Tower、tower-http | HTTP 命令、SSE 事件、WebSocket 双向通信、认证和流控 |
| 存储适配 | SQLx、PostgreSQL、pgvector | 显式 SQL、事务、初始化、RLS/FK、检索与恢复 |
| 契约层 | Serde、serde_json、jsonschema | DTO 序列化、2020-12 验证与受限本地引用 |
| 网页 | React、TypeScript、Vite、React Vite plugin | SPA；独立静态部署或由 Rust 网络适配提供资源 |
| 交互组件 | Tailwind CSS、shadcn/ui | 可访问基础组件；生成源码纳入本仓库维护与审查 |
| 页面状态 | TanStack Router/Query、Zustand | 路由、服务状态投影及临时交互，分开管理 |
| 桌面 | Tauri 2 与 JS API/CLI | 共享 SPA、窗口、受控原生桥、打包更新 |
| 扩展 | 进程外协议、Wasmtime/WASI | 契约与实现解耦；Wasm 只是执行后端之一 |
| 观测/验证 | tracing、OpenTelemetry、proptest、Vitest、Playwright | 结构化关联、属性测试、界面/端到端测试 |

默认构建工具 Node Active LTS + pnpm。暂不增加 Next.js/SSR 或第二套 Node 业务后端。Rust 核心服务无需依赖生产 Node 运行时来承载领域逻辑。

## 3. Cargo 与应用边界

有界队列、异步任务与取消机制位于 application；CPU 密集或不可信工作使用受限执行器，不阻塞控制调度。Tokio 任务不替代领域任务状态机。

后续工作区按 domain、contracts、application、adapters、composition root 组织；这些是依赖责任，不能用空目录标记实现完成。

- domain 不依赖 Tokio、Axum、Tower、SQLx、Tauri、Wasmtime、网络/数据库/前端 SDK。通过纯值、受验证命令与事件执行 reducer；异步 I/O 不在 reducer 中发生。
- contracts 保存按版本的 DTO 及 Schema 引用；其 Serde/jsonschema 细节不得成为领域状态转换的另一套规则。
- application 使用 Send + Sync 的 Port traits，调用方注入适配器；禁止 trait 接口泄漏 Router、SQLx Transaction、Tauri AppHandle 或 Wasmtime Store。
- Port 只为确切的 I/O 和可替换资源定义；领域使用纯值，异步调用方式在工程实施时按实际调用需求选择，避免为所有类型建立动态分派层。
- PostgreSQL 实现通过 SQLx 显式事务保留 event/state/outbox 原子性，初始化前依据 [数据存储](13-DATA-STORAGE.md) 的约束与核验。
- tracing 和使用量采集位于应用/适配层；领域可返回结构化审计事件，不直接写开放日志或依赖采集器。

## 4. 网页、桌面与核心通信

[AEIP](12-EXTERNAL-INTERACTION-PROTOCOL.md)在已有 Axum/Tower 网络适配边界定义公开 WebSocket 与 HTTP/SSE 绑定，不新增框架或核心依赖。AEIP 会话与 HostControl 包激活分别处理；独立 peer 无须 Rust、官方 SDK 或扩展 manifest。公开 DTO/Schema 与内部业务投影显式映射，适配器注册复用现有宿主；本次没有创建工程或解析新依赖。

浏览器使用认证 HTTP 命令入口和可按 cursor 恢复的 SSE；双向/连续流由既有扩展通信协议或明确的流适配承载。大媒体引用及独立数据面保持首版设计，不能把高频 chunk 当作全部需要落库的领域事件。

TanStack Query 保存服务快照和缓存投影，SSE 按 scope/version/sequence 更新或失效这些视图。Zustand 仅保存选中面板、输入草稿、展开状态等临时 UI 数据，不能授予权限或成为身份、记忆、任务的唯一存储。浏览器刷新/重连通过快照与 cursor 恢复。

Tauri 共享相同 React 源码和应用命令边界；原生桥只转交经过验证的操作。窗口关闭不会创建新身份或清除历史；核心按明确运行策略停止/继续，重开窗口从服务恢复。不得用绕过策略的桌面“快捷通道”直接访问领域数据库。

桌面 JS API、Rust crate 和 CLI 的版本分别锁定，不假定补丁号必须相同。Tauri capabilities、CSP、窗口范围是额外边界，ALIA 的 consent、Policy、BindingGrant、Action AuthorizationRecord 仍独立强制执行。远端页面不能自动取得本地原生权限。

系统 WebView 的版本、媒体权限、音频、视频、渲染和后台行为按 Windows/macOS/Linux 实测。首个验证平台沿当前 Windows 环境推进，跨平台支持只在各自门禁通过后声明。

## 5. 开放扩展与执行后端

未来扩展仍声明开放契约，宿主选择运行位置、传输和隔离；Rust 的语言选择不限定扩展实现语言。禁止以 Rust trait object、内存布局或 libloading 的内部 Rust ABI 作为跨包稳定协议。

Wasmtime/WASI 是选定的扩展执行技术；具体扩展按实际能力选择必要后端，不要求同时实现所有后端。执行实例由宿主控制；每个不可信实例最小导入、默认无文件/网络/凭据访问，配置内存上限、fuel/epoch 中断与期限，并由外部隔离进程/OS 配额保护宿主。Wasmtime 内存隔离不自动证明宿主导入、WASI 预打开目录或网络授权正确。需要原生能力的扩展继续使用有实际 OS 约束的进程外协议；隔离后端不具备时拒绝运行。

UI 扩展不直接执行未受信任代码到 React 主窗口。可信本地组件走审查后的构建贡献；不可信界面内容必须隔离、限权并通过版本化消息桥接，不能访问主窗口凭据或共享状态。

## 6. 契约语言映射与差分门禁

JSON Schema 2020-12 继续是现有 wire 验证事实来源。Rust 和 TypeScript 的类型必须与版本化 DTO 对齐；Serde 解析成功不代表通过 Schema，TS 类型不提供运行时安全。Protobuf 在需要时使用相同语义的显式映射与兼容测试，不另建矛盾权威。

jsonschema 关闭默认网络/文件取回，采用只解析已授权注册契约的本地 retriever；显式启用已知 format 断言，拒绝未注册的 format。限制 Schema/输入深度、大小、正则和验证耗时。

PowerShell 7.6 的 Test-Json 默认将 format 作为注解，不能独自拒绝非法日期。因此本地入口先运行 Test-Json，再通过 PowerShell 自带的 JsonSchema.Net 显式采用 Draft202012、开启 RequireFormatValidation / OnlyKnownFormats，并禁止外部引用取回。该库对 date-time 仍接受 2 月 30 日，入口补充实际日历校验；实现见 [验证入口](../../tests/Schema-Validation.ps1)。Rust 必须遵守这一明确的校验配置，不能只复现默认行为。

数字在 wire 校验前不得经 JavaScript Number 或有损浮点转换。后续 Rust 使用 serde_json 的 arbitrary_precision 保留数字，再按领域 DTO 的有界整数/小数规则转换；超界必须显式拒绝，不可舍入。Schema 接受任意精度整数并不等于领域 DTO 可以存储；前端需要超过安全整数范围时应使用契约明确规定的字符串表示，不能私改现有字段类型。JCS 摘要还必须满足其数字范围限制；不可精确表达的输入须拒绝或由新版本契约定义表示方式。

后续同一份 tests/contracts 夹具分别由 Rust 与 PowerShell 执行，比较逐例接受/拒绝及契约选择，不只比较总数量。[差分向量](../../tests/technology-stack/differential-matrix.json) 覆盖 date-time/时区、非有限值与数字精度、整数边界、Unicode、局部/外部引用、额外字段；既有动态业务夹具同样纳入。当前仅执行 PowerShell 侧 oracle，Rust 差分保持 specified；RFC 8785 摘要单独核验，不能用普通 serde_json map 序列化替代。

## 7. 版本核查与升级规则

清单区分来源版本核查、依赖解析、构建和平台验证。登记库“版本已发布”只证明可取得的元数据，不证明 MSRV、feature、peer dependency、系统依赖或全组合可用。

选型初始基线 Rust 1.100.0、PostgreSQL 18.7、Tauri 2.12.5 为指定版本候选；完整清单记录官方来源及核查日期。升级须修改清单与对应真实锁文件、说明风险、执行受影响构建/契约/数据/平台门禁；不能在失败后默默降级或删掉核心能力。

前端 plugin 的 peer ranges、编译器/Node 要求及 Rust crate 的 MSRV 必须在建立真实工程时解析；未解析的完整依赖树保持 unverified。shadcn/ui 作为生成式源码工具使用，生成时记录 CLI 版本及上游来源，生成的组件不是运行时动态执行的插件。

## 8. 成熟作品的适用依据

以下记录的是公开分支清单中的技术选择，不表示我们运行了这些产品，或其完整组合都适合原样移植。固定快照见机器清单 reference_projects。

| 作品 | 核查内容 | 对 ALIA 的用途 |
|---|---|---|
| AIRI | Vue/Vite/Pinia；桌面 Electron；Three.js 等分层渲染依赖 | 学习舞台、媒体、来源状态和扩展边界；本项目已选择 React |
| Jan | React/Vite/Tauri；Rust native crate 与 UI 入口分开 | 共享网页组件、Rust 桌面桥及原生适配参考 |
| Open WebUI | Svelte/SvelteKit | 交互和功能组织参照，不切换已选前端 |
| LobeHub | React/Next.js，同时有 Vite SPA 构建路径 | React 应用与功能分层参照，不引入其服务端全栈 |

官方依据：[Rust 发布公告](https://blog.rust-lang.org/2026/11/12/Rust-1.100.0/)、[Axum](https://docs.rs/axum/0.8.9/axum/)、[SQLx](https://github.com/transact-rs/sqlx)、[jsonschema](https://docs.rs/jsonschema/0.61.2/jsonschema/)、[Tauri 前端](https://v2.tauri.app/start/frontend/)、[Wasmtime 安全](https://docs.wasmtime.dev/security.html)、[PostgreSQL](https://www.postgresql.org/support/versioning/)。
