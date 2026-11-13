# 05 — 状态、事件、命令和 API 的稳定契约

## A. 所有领域事件通用 Envelope
见 `schemas/core/event.schema.json`。必须有 `schema_version,scope,data_policy,event_id,event_type,sequence,occurred_at,recorded_at,correlation_id,causation_id,source,payload_contract,payload,content_parts`。scope 包含 `tenant_id,identity_id,branch_id,access_scope`；source 与 data_policy 按活动 Schema 验证。外部事件不具备默认系统权限；原始二进制用 blob ref + ACL + TTL。

### 领域事件种类
- `observation.received`, `observation.validated`, `observation.ignored`
- `dialogue.turn.opened`, `dialogue.turn.waiting`, `dialogue.turn.closed`, `dialogue.turn.interrupted`
- `decision.proposed`, `decision.validated`, `decision.rejected`
- `expression.intent.created`, `expression.delivery.started`, `expression.delivery.completed`, `expression.delivery.interrupted`
- `memory.candidate.created`, `memory.committed`, `memory.disputed`, `memory.retracted`, `memory.deleted`
- `belief.asserted`, `belief.revised`, `persona.change.proposed`, `persona.change.approved`
- `relationship.boundary.updated`, `goal.created`, `goal.activated`, `goal.paused`
- `task.created`, `task.leased`, `task.completed`, `task.failed`, `task.cancelled`
- `capability.registered`, `action.proposed`, `action.authorized`, `action.dispatched`, `action.result.observed`, `action.reconciled`
- `privacy.consent.revoked`, `privacy.deletion.requested`, `privacy.deletion.completed`
- `identity.forked`, `identity.migrated`, `runtime.checkpoint.created`, `runtime.resumed`

## B. 决策状态机
`observed -> admitted -> context_prepared -> decision_proposed -> validated -> [wait | silent | defer | reply | clarify | act | queue_task | refuse]`。
所有需要行动的选择必须经过 `policy` 与 `capability` 检查才能进入动作执行；不是模型直接写数据库。`silent` 无聊天气泡；`defer` 留待办；`wait` 有 timeout/cancel。

## C. 任务状态机
`proposed -> awaiting_approval? -> armed -> queued -> leased -> running -> [completed|failed|cancelled|paused|needs_reconciliation]`。只有完成并确认环境效果后，才可声明 `completed`；网络超时/重复请求产生 `needs_reconciliation`。

## D. 工具动作状态机
`proposed -> validated -> authorized -> dispatched -> [acknowledged -> completed | failed | timeout | uncertain] -> reconciled`。`requested` 和 `success` 永不混同。记录外部 request IDs/attempts/rollback policy。

## E. 表达状态机

内部表达计划 planned → released → started；释放与实际送达分开。DeliveryReceipt 整体使用 planned/started/partial/completed/interrupted/failed/suppressed，segments 记录 delivered/interrupted/failed 及真实位置。只有实际 delivered 范围计入“已说过”的经历；各通道部分结果不能被单一 completed 掩盖。

## F. 记忆状态

生命周期 lifecycle 使用 candidate/validated/active/superseded/retracted/deleted；evidence_status 独立表示 unknown/supported/confirmed/disputed；source_kind 独立表示观察、转述、推断等来源。validated 表示通过候选验证，active 还需完成合法提交；状态含义与 Schema 一致。active 需要满足来源、授权与证据规则，删除清除内容和派生检索。时间字段按契约使用 effective_from/effective_to 与 recorded_at。

## G. 模块操作与 I/O 边界

以下为设计语义，不是已实现的 Rust 类型。纯领域规则用同步值与命令/事件；只有实际 I/O 边界需要应用 Port。不要求每个模块建立异步 trait、动态分派或独立服务。

| 操作 / 责任 | 输入 → 输出及边界 |
|---|---|
| StateStore | Scope、expected_version、read_set、合法事件、outbox → Snapshot/CommitReceipt；数据库事务 I/O |
| PerceptionPort | 带来源的适配器输入 → Observation；采集 I/O 在适配器，标准化规则保持纯函数 |
| ContextCompiler | 合法状态与授权检索结果 → ContextView；检索 I/O 与编译规则分开 |
| DecisionEngine | ContextView、候选与模型响应 → DecisionProposal；确定性守卫不在模型中 |
| PolicyEngine | 认证请求、当前政策与数据范围 → AuthorizationRecord 或拒绝；凭证解析通过受信任存储 |
| MemoryStore | 授权查询/记忆候选 → 证据结果/提交候选；聚合验证与持久化分开 |
| ExpressionPlanner | 合法决定、受众、端点 → ExpressionIntent/Plan；设备播放由适配器执行 |
| CapabilityRegistry | 当前契约、绑定与能力事实 → 可用能力描述；发现不授予权限 |
| ActionExecutor | AuthorizedAction → 接收/结果/不确定回执；外部 I/O 受期限、取消与核验约束 |
| ModelProvider | generate/stream/tool-call/structured-output/cancel/usage/health 请求 → 模型候选与使用量；外部推理 I/O |
| Reducer | DomainState、ValidatedDomainEvent → 新状态或领域错误；同步、确定性、无 I/O |

Rust/TS DTO 与首版 Schema 语义一致，不能作为另一套权威。异步调度、取消、deadline 与 trace 在应用层传递，框架句柄不进入领域。具体调用与所有权形式在实际实现中按消费者选择，避免为假想后端预建通用抽象。

## H. 首版 WebUI API
`POST /v1/events`（提交输入，Idempotency-Key）、`GET /v1/conversations/{id}/events`（按 cursor 回放）、`GET /v1/streams`（SSE 事件推送）、`POST /v1/decisions/{id}/approve`、`GET /v1/memory`、`PATCH /v1/memory/{id}`、`POST /v1/memory/deletion-requests`、`GET /v1/identities/{id}/state`、`GET /v1/tasks`、`GET /v1/capabilities`、`GET /v1/traces/{id}`（仅调试权限）。
所有接口需要 AuthN/AuthZ、版本、分页/流断线恢复、审计与错误码。不得直接把内部人格结构写给匿名用户。

## I. 数据归属

逻辑聚合、键、约束、事务、初始化与恢复以 [存储设计](appendices/13-DATA-STORAGE.md) 为唯一来源。事件日志同样受用途、保留与删除政策约束。接口不能绕过聚合所有者直接修改表。

## J. 首版契约与验证责任

本章定义领域语义、应用边界、目标 API 与逻辑存储责任。首版契约草案见 [Schema 目录](../schemas/README.md)。未知版本和不合法对象拒绝，不设置其他版本入口。

公共契约对象：ExtensionManifest、ServiceContract、ExtensionSession、Binding、ExtensionMessage、HostControl、BindingGrant、AuthorizationRecord、DeliveryReceipt。核心对象统一 scope/data_policy；Decision/Action/Expression/Memory 候选记录 read_set。候选不能自报已授权；授权由可信 Policy 单独签发并引用。

服务契约是方法/事件/流的开放集合；通信控制 kind 与生命周期状态由宿主协议固定。注册成功不证明 payload、授权或效果真实。事件 payload_contract 的已注册 Schema 由运行时二次校验；event_type 与具体契约匹配由验证器强制。

发言权及 per-channel/segment 交付位置见 [媒介表达](03-MEDIA-EXPRESSION.md)；Memory 的 source_kind、evidence_status、lifecycle 分离。关联和数据库约束见 [数据存储](appendices/13-DATA-STORAGE.md)。审批接口只接受认证结构化请求并绑定明确动作版本；不能批准整个后续自由文本计划。

## K. 情境行为概念契约

所有下列对象复用 core 1.0 的 scope/data_policy/read_set/事件因果封套语义，不建立旁路授权。所有者见 [01](01-ONTOLOGY-ARCHITECTURE.md)，转换守卫/恢复/删除见 [情境行为](appendices/15-SITUATED-BEHAVIOR.md)。名称是架构对象，不是已存在的 Rust 类型或可写 API。

| 契约 | 最小语义与关联 | 生命周期 / 提交条件 |
|---|---|---|
| SceneContext | 活动/话题、参与者、共同关注、观察范围/时间、不确定性、来源修订 | 活动 proposed→active→suspended/ended；覆盖 current/stale/unavailable 独立；恢复后重验来源 |
| InteractionOpportunity | 原事件锚点、对象/话题、动机、窗口、失效/合并依据、资源成本与读集 | candidate→eligible→selected→consumed；blocked/expired/withdrawn；真实效果才消费 |
| PersonaProfile / EvolutionPolicy | 当前/历史版本、可编辑语义维度、允许/锁定字段、证据/漂移/回归规则 | 配置有版本；自动范围缺省关闭，非系统硬约束；回滚生成新版本 |
| PersonaChangeProposal | 认证作者类别、基线、结构化差异、来源、预期行为与确认摘要 | proposed→validated→awaiting_consent/eligible_auto→committed；rejected/stale/withdrawn |
| SharedSymbol / SocialFeedback | 对象/命名事件/知情者/使用范围；反馈主体、主题、证据与含混程度 | presented 不等于 grounded；明确拒绝先更新局部边界；修复不恢复全部许可 |
| InteractionFrame | 事实/玩笑/比喻/引用/表演、范围、前提、参与者及修复入口 | proposed→active→repairing/closed；新任务不能继承旧虚构前提 |
| ExpressionPlan | 片段、依赖、语用、停顿条件、接话窗、取消代次、动作关系及端点修订 | planned/released/started 为内部计划态；实际送达映射现有 DeliveryReceipt，保持回执状态语义一致 |
| OutputEndpoint | 认证绑定、设备/通道、路径私密性、可达性、观察时间、修订 | 私密性与可达性为独立维度；路径失效→暂停重验，旧授权不自动继承 |
| ControlLease | 资源、持有任务、用途、代次、期限、允许控制范围 | available→held→releasing/revoked/expired→available；旧代次不能复用，租约不是授权 |

应用接口语义：人格读取、预览、确认、版本列表、回滚、演化政策设置；场景修订、机会仲裁、共同理解更新、表达发布/取消、控制权申请/释放/用户接管。每个变更命令包含认证主体、作用域、预期版本与幂等关联；返回有效版本或明确的拒绝/过期/需澄清/需确认状态。自由文本不直接成为状态写入。具体 HTTP 与 typed payload 在消费者明确时按本语义定义，不额外创建一套状态权威。

未来时序 payload 通过已注册 typed content 接入，注册需契约版本/摘要、绑定事件类型、资源限制和领域验证器；缺此注册不能宣称 pace/timing 可执行。现有 DeliveryReceipt 整体 `partial` 与片段真实位置表达部分结果，`released` 不是对外已送达状态。读集修订单位以 L 节为准。


## L. 读集与状态提交

Decision、反思、记忆/关系/学习候选携带 read_set：读取的输入修订、身份分支版本、环境版本、策略/同意版本和删除屏障版本。依赖必须具体到资源，不要求无关状态变化令全部候选失效。

提交前由确定性验证器比较读集。相关事实改变则拒绝旧候选，重新编译和判断；纯表达投影可在语义仍有效且授权未变时重做。禁止仅刷新数据库 expectedVersion 后写入原决定。迟到回执保留审计/效果核验价值，但不能成为过去授权的补办。

首版 core 1.0 以整体对象修订作为读集单位；细粒度读集须先定义资源标识和修订语义。端点、受众和控制租约的相关变化同样触发候选失效。恢复先核对授权、撤销与删除屏障，回放只恢复状态，不重复外部效果。
