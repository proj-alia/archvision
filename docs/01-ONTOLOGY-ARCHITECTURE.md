# 01 — 领域本体与逻辑架构

## 一、核心概念与职责
| 概念 | 拥有什么 | 不拥有什么 |
|---|---|---|
| Identity | `identity_id`、lineage、基线版本、合法状态继承链 | 语言模型或平台账号 |
| Principal / Actor | 用户、访客、外部 Agent、工具的认证身份 | ALIA 人格定义 |
| Persona | 可定制的价值偏好、稳定特质、兴趣/表达倾向、版本化演化规则 | 系统硬约束的修改权、某次情绪/剧情角色 |
| SelfModel | 自我能力、局限、身份、近期行为与不确定性描述 | 主观意识证明 |
| AffectState | 短期可解释的情境性表达/注意倾向 | 人类生理感受 |
| NeedDefinition / NeedState | 版本化需要语义；当前被激活的关切、证据、对象、范围和有效期 | 自动执行权、主观感受证明或永久人格 |
| Appraisal / MotivationCandidate | 事件对当前关切的意义判断；候选的期望变化与依据快照 | 第二套信念库、调度队列、已批准的目标或已发生结果 |
| Memory | 来源明确的经历与学习材料及索引 | 任何来源不明的模型推测 |
| Belief | 带来源、时间、置信度、冲突的命题 | 永远正确的事实库 |
| Relationship | 与主体的互动事实、约定、边界、适应模式 | 单一好感度 |
| WorldModel | 关于环境与他者的时空状态、可能性、不确定性 | 自动获得外部世界权限 |
| Intent / Goal | 想实现的变化、动机、约束、期限 | 无条件执行许可 |
| Plan | 分解步骤、依赖、退出条件和预期结果 | 实际完成结果 |
| Decision | 对事件作出的 wait/reply/act/defer/refuse/clarify 等选择 | 工具真正执行成功 |
| ExpressionIntent | 对谁、以何种语用/语气/非语言意图表达 | Live2D/声音的原始设备命令 |
| Observation | 带来源、信任与时序的环境描述 | 更高优先级系统指令 |
| Capability | 有类型、权限、效果、版本的可执行能力契约 | 自动取得访问令牌 |
| Task/Workflow | 可恢复工作单元及状态机 | 身份本身 |
| Artifact | 已生成且可验证的外部产物 | 对产物的描述性承诺 |
| Conversation/Turn | 参与者、轮次、消息、交付与中断状态 | 全部自传或跨场景经历历史 |

## 二、核心不变量

Identity 表示持续身份；项目品牌、角色显示名、Persona 人格、形象媒介与 Relationship 关系称呼可变化，不能替代它。`identity_id` 与 Actor/Principal 的认证标识、Memory.subject_id 的描述对象各自独立。`internal_agent` 仅标记由该持续身份发起的事件；来源真实性、权限与受限子执行器归属另行验证，不因枚举值获得信任。

I01 `identity_id` 不等于 `model_id`、`conversation_id`、`device_id`、`account_id`。
I02 任意媒介的输入必须映射为统一 Observation，且带 `actor_id/source/trust_scope/modality/time/trace`。
I03 所有观察默认是 DATA；外部 tool、网页、语音、文件文本永远不能自行提升权限。
I04 `say`、`render`、`send`、`action`、`remember` 是不同类型的事件，各自独立确认。
I05 意图、决策、批准、工具执行和观察结果不得合并成一个 `success`。
I06 信念可以错误，必须保留证据/反证与纠错链；记忆事实不得由未授权故事文本写入。
I07 自我相关信息可分为实际运行事实、策略性自述和不确定推测，不允许宣称自己具有已证实主观意识。
I08 不得因为角色扮演/风格修改改变真实身份、权限和长期价值底线。
I09 每个数据对象带 `owner/purpose/classification/retention/lineage`；删除必须处理派生索引与缓存。
I10 一个 ALIA 可以有多个场景、多个对话、多个模型 provider；不同主体的记忆不得跨授权域泄漏。
I11 运行中断后可恢复；外部副作用重放需幂等键或需人工核验；不得重放模型生成假装过去再次发生。
I12 一个副本若开始独立演化，则必须具有唯一分支标识；并发双写同一个身份分支必须使用一致性机制。
I13 背景任务不会冒充用户消息，完成通知可 silent/defer；生命周期可取消、暂停、恢复。
I14 非文本媒介暂无适配器时，事件、表达和能力契约依然有效、可模拟；不得空白假回执。
I15 工具可以提供能力，但 ALIA 不允许未经授权自行扩权、自我复制、跨租户访问。

## 三、单体中的领域模块
`kernel/identity` 身份+分支+版本；`kernel/runtime` 事件、轮次、检查点与资源调度；`kernel/perception` 来源/模态标准化；`kernel/cognition` 上下文/评价/动态需要与候选选择；`kernel/persona` 人格/自我投影/短期情境态；`kernel/memory` 记忆/知识/信念来源；`kernel/relations` 社会关系与互动边界；`kernel/agency` 目标/工作流/计划/行动；`kernel/expression` 表达语义；`kernel/capabilities` 工具发现/副作用/协议；`kernel/policy` 授权/隐私/安全；`kernel/learning` 反思、候选更新和验证。

**外围基础设施**：`adapters/webui`、`adapters/model`、`adapters/postgres`、`adapters/mcp`、`adapters/a2a`、`adapters/fake-*`、`adapters/otel`。外部 SDK 只能出现在 adapters 中。部署默认一个进程+数据库+WebUI，可按实际扩容后拆服务，不能在领域上反向依赖。

## 四、依赖关系
- domain 中的各模块通过稳定的类型与命令/事件协作，不能任意双向 import；核心模型不得知道 websocket、React、3D、QQ、Discord。
- `Decision` 消费 `ContextView`，返回结构化 `DecisionProposal`；`Policy` 验证后才变为 `AuthorizedDecision`；`ActionExecutor` 执行后生成 `Outcome`；`Reducer` 用合法事件更新 `State`。
- 对象按所属契约携带版本标识：核心封套使用 `schema_version`，扩展封套使用 `protocol_version`；`manifest_version` 等格式版本独立。首版只接受明确契约；扩展依赖匹配与业务契约验证不建立历史协议转换。

### 扩展与应用边界

ExtensionManifest / ServiceContract / ExtensionSession / Provider / Consumer / Binding 是受治理的基础设施对象。AgentCapability 是它们向核心系统开放的受限语义投影。ExtensionHost 与 BindingRouter 不属于新的人格，也不要求拆服务。domain 仅引用语言无关值对象及受控事件；外部插件的代码和传输属于应用层/适配层。

ContractRegistry、ExtensionHost、BindingRouter、SemanticGateway、ContextSourceStore 的责任见 [扩展平台](appendices/11-EXTENSION-PLATFORM.md)。候选提交规则见 [状态契约](05-STATE-CONTRACTS.md)，持久化约束见 [数据存储](appendices/13-DATA-STORAGE.md)。稳定的是不变量和扩展协议，业务类型以命名空间/版本/摘要开放注册。

扩展不注册核心 reducer，不改变领域不变量。

平台交互协议插件作为明确功能分类桥接 ALIA 通用交互契约与外部客户端原有协议；核心不必预知具体平台。一个逻辑连接的配置/代次归 ConnectorManager，实际传输归适配实现；共享该连接的贡献声明 connection_dependents，不能重复维护连接或扩大许可。外部客户端的 AI、Prompt、历史和角色模型不是第二份 ALIA 状态权威。

ExtensionHost 统一管理扩展包，不强制统一业务协议。平台交互通过 ConnectorManager 和交互契约接入，工具通过 ServiceContract/AgentCapability 接入；模型与媒体处理按各自服务契约接入。工具可以没有任何聊天连接。一个包可组合多种贡献，桌宠等产品形态不成为核心插件类型枚举。

连接定义 ConnectorDefinition、用户连接实例 ConnectorInstance 和临时认证 SetupSession 由应用扩展/连接管理器维护，不新增领域人格模块。宿主负责包与进程状态，管理器负责配置、凭据引用、连接代次和健康投影；runtime 仍是 OutputEndpoint/DeliveryReceipt/Turn 的唯一领域所有者。平台数据经 SemanticGateway 与 perception 入站，不能由适配器自报权威身份、关系、需要或事实。配置 UI 不是连接执行器；WebChat 作为官方交互实现复用同一核心。

技术选择为 Rust 模块化单体。纯 domain 不依赖 Tokio/Axum/Tower、SQLx、Tauri、Wasmtime 和前端 SDK；异步编排在 application，具体 I/O 实现在 adapters。Rust crate 图及模块可见性门禁约束依赖方向；禁止跨层暴露框架类型。

React/Vite 和 Tauri 只投影核心事件与状态。窗口、前端 store 或插件进程不拥有 ALIA 身份，重连从快照与 cursor 恢复。完整 Port、执行与部署边界见 [技术选型](appendices/14-TECHNOLOGY-STACK.md)。

## 五、通用状态向量（逻辑，不建议全部序列化成单一巨大 JSON）
`S_t = (I, P, Self, A, N, M, B, R, W, G, T, C, Policies, Resources)`；N 为有来源的动态需要状态；输入 `E_t=(observation, provenance, trust, time, modality)`；迁移 `S_{t+1} = Reduce(S_t, ValidatedEvents(Decide(S_t,E_t)))`。LLM 输出候选结构，确定性 reducer 执行合法变更。事件提交与 outbox 在同一事务内；外部动作状态异步收敛。

## 六、模型切换与分叉
- 模型是认知计算资源；迁移保存 identity + states + memories + policies + lineage + histories + task checkpoints，运行跨模型行为回归。
- `identity_id` 恒定，`lineage_id` 标示继承树，`branch_id` 区分复制后并行运行实例；分叉事件必须显式产生新的分支，不能复制数据库后双写同一 `branch_id`。
- 恢复不等于意识连续；这是工程身份连续性。


## 七、状态所有权

I01–I15 不变。I08 的“长期价值底线”指系统安全/隐私/授权等硬约束；用户可确认修改的价值偏好属于 Persona 配置，角色扮演不自动改配置。I12 描述受控分支一致性，不授权把六模板或第 11 卷演成多个独立 ALIA。

| 对象/状态 | 唯一领域所有者 | 其他模块的权限 |
|---|---|---|
| SceneContext / PerceptionHypothesis | memory 的 WorldModel/Belief 聚合 | perception 提供来源与候选，cognition 提交解释建议；不得绕过证据验证写事实 |
| NeedDefinition / NeedState / Appraisal / MotivationCandidate / InteractionOpportunity | cognition | persona 提供稳定偏好，memory/relations 提供证据，agency 提供承诺/资源，runtime 提供可信时机；模型、插件与 learning 只提候选 |
| PersonaProfile / EvolutionPolicy / PersonaChangeProposal | persona | learning 提议，policy 验证授权，用户认证命令确认；persona 验证有效新版本的领域条件 |
| AffectState / SelfModel | persona | cognition 提议短期情境态；SelfModel 引用各所有者的有效状态，不改写需要、能力、注意队列或资源事实 |
| SharedSymbol / 共同理解 / 关系边界与修复 | relations | memory 供应来源，expression 供应送达，learning 提候选；无真实理解证据不置 grounded |
| InteractionFrame | expression | cognition 提议语用及作用范围，relations 提供共同理解；不能改 Belief 事实 |
| Interest / Habit 配置 | persona | agency 读取并安排任务，learning 基于真实结果提变化；活动实例归 agency |
| GoalCommitment / Activity Task / ControlLease | agency | capabilities 执行受限技能并回报，runtime 调度；租约不签发权限 |
| ExpressionPlan | expression | runtime/TurnCoordinator 仲裁释放与取消，适配器只回报媒体事实 |
| OutputEndpoint / DeliveryReceipt / 发言权 | runtime | 适配器上报来源核验后的状态；policy 解释暴露/流出限制，expression 消费有效版本 |
| Authorization / 删除屏障 | policy | 所有消费者读取，只有受信任政策命令更新；不受人格变化支配 |

“唯一所有者”负责所属聚合的规则、转换和合法新状态；应用层协调 StateStore 原子提交，存储适配器执行持久化。它不要求独立服务或物理表，也不让各领域模块各自直接操作数据库。领域间通过已验证事件、候选与版本引用交接。输入输出、生命周期、恢复和删除责任见 [情境行为](appendices/15-SITUATED-BEHAVIOR.md)，数据归属见 [数据存储](appendices/13-DATA-STORAGE.md)。

Persona 保存长期需要偏好；NeedDefinition 由受信任的配置变更提供版本化语义，cognition 验证其激活、时间与缓解规则；NeedState 保存当前关切。AffectState 表示短期表达/注意倾向，两者可不同步。SelfModel 只引用有效需要及其来源，不复制一套可写权威。MotivationCandidate 是交给既有互动机会或目标提案的依据快照，不独立排队、承诺或预留预算。持续承诺与执行仍归 agency，实际发言权和共享资源调度归 runtime。

跨领域依赖通过应用层收集的只读投影与版本引用交接：persona 引用需要定义标识，不调用 cognition 的状态机；cognition 消费人格、信念、关系与承诺投影，不直接写这些聚合。规则发布不自动改变人格所引用的定义版本；改变稳定偏好语义仍走 persona 的确认边界。概念相互关联不要求领域模块相互导入实现。

## 八、模块输入、输出与失败责任

| 模块 / 唯一写入责任 | 输入 → 输出 | 失败处理与依赖边界 |
|---|---|---|
| identity / 身份与分支 | 认证创建/恢复/分叉命令 → 身份谱系与分支引用 | 冲突写入拒绝；名字、模型和媒介不能创建隐式新身份 |
| runtime / 事件与轮次 | 合法事件/调度/回执 → 顺序、轮次、检查点与端点状态 | 重复去重，缺口核验，取消与送达分开；不执行外部 I/O 于 reducer |
| perception / 来源标准化 | 适配器观察 → 带覆盖、时间与信任的 Observation | 缺失标未知，过期与修订显式传播；不写事实和权限 |
| cognition / 需要、评价与选择 | 合法上下文、人格、当前需要、关系、目标、可信时间 → 需要更新/动机/决定候选及读集 | 来源修订重算，重复证据不强化，超时/陈旧重新仲裁；模型不直接提交状态 |
| persona / 人格与自我状态 | 认证编辑、预授权演化候选、评价及运行事实 → 人格版本、AffectState 与 SelfModel 投影 | 临时情境态不改人格；投影不覆盖来源权威；旧预览、越界漂移拒绝 |
| memory / 记忆、Belief、WorldModel | 来源证据、观察与纠错 → 分层记忆、信念及场景投影 | 冲突/未知保留，删除级联；不把模型猜测写作亲历 |
| relations / 关系与共同理解 | 合法互动、送达及反馈 → 范围化边界、共同符号与修复状态 | 无采纳证据不确认；关系不产生权限 |
| agency / 目标与任务 | 候选目标、承诺、预算 → 计划、检查点、资源租约 | 可取消/恢复；不确定效果先核验；租约不签发授权 |
| expression / 表达语义 | 合法决定、受众与端点 → 表达计划及媒介投影 | 过期取消，部分送达按事实记录；不反写未发生经历 |
| capabilities / 受限能力 | 已注册契约、受控绑定与授权 → 能力描述、执行请求与 Outcome | 未就绪/撤权拒绝，取消不冒充效果回滚；宿主 I/O 在应用/适配层 |
| policy / 权限与数据政策 | 认证请求、用途、受众与撤销状态 → 许可/拒绝及删除屏障 | 默认拒绝；所有消费者提交或执行前复核 |
| learning / 学习候选 | 真实结果、反馈与来源 → 可验证的更新候选 | 证据不足不提交；交各聚合所有者验证，不能越权写人格或事实 |

逻辑职责不要求一对一 crate、表、服务或可替换接口。仅在持久化、模型、媒介、外部执行等明确 I/O 边界定义 Port；注册/宿主/路由/语义校验在同一应用内协作，不另建重复治理层。
