# 10 — 首版通用架构覆盖矩阵

当前能力状态及实际结果统一见 [验证记录](06-VALIDATION.md#当前验证记录)。表中“首版核心完整实现”指必须有真实状态、接口、流转与测试；“首版模拟”指必须有无外部设备依赖的 fake adapter 和 contract tests；真实语音/直播/游戏/设备不做虚假承诺。

| 领域 | 关键设计/算法 | 首版验收证据 |
|---|---|---|
| 持续身份 | ID、谱系、实例/分支、迁移、人格版本 | restore/fork/migrate 测试 |
| 用户与群体 | principal、actor、participant、audience、ACL、关系范围 | 多人私聊不泄露 |
| 自我认知 | SelfModel、能力认知、局限、不确定性 | 自我陈述受实际状态约束 |
| 人格 | 稳定价值观、特质、表达偏好、演化审批、漂移检测 | 重启/换模型行为回归 |
| 动态需要 | NeedDefinition 的发布/采用、NeedState 的关切归并、事件与有界可信时间、强度/支持分离 | 独立对照、空集/容量、失效/放弃/恢复、结果归因、需要未满足仍可不行动 |
| 情境表现 | AffectState/ExpressionIntent/Adapter、TTL、表达节奏 | 文字+fake avatar/audio |
| 记忆 | episodic/semantic/procedural/relational/autobiographical/working/core | 多源来源、跨会话、删除 |
| 知识信念 | belief graph、truth maintenance、双时态、证据冲突 | 纠错/过时/撤回 |
| 世界模型 | 环境/设备/游戏/时空状态/能力范围 | 模拟观测与结果闭环 |
| 认知处理 | context compilation、fast/deliberative/reflex/background、meta-cognition | 路由、性能、失败跟踪 |
| 对话 | turn coordination、输入合并、wait/silent/defer、cancel/stream | 无幽灵消息、打断恢复 |
| 行动动机 | Appraisal、MotivationCandidate 依据快照、goal、commitment、plan、资源/风险仲裁 | 单一交接；历史动机与执行前提分离；复用既有队列/预算，允许 do nothing |
| 长任务 | durable task、checkpoint、lease、retry、timeout、compensate | 故障恢复及幂等性 |
| 能力接入 | registry、version、ACL、MCP、A2A、结果反馈 | 工具读写/冲突/拒绝 |
| 通用交互接入 | 官方交互契约、社区适配实现、连接定义/实例/配置会话 | 未知平台无核心/UI 分支；多实例/认证/交付与工具独立性 |
| 工具创造 | 提议、沙箱、签名、审核、注册 | 不可越权自动安装 |
| 环境感知 | Modality Parts、source/trust/timestamps、observations | fake text/image/audio/game |
| 媒介表达 | 消息、语音、avatar、游戏动作、物理动作投影 | fake adapter 同一认知状态 |
| 注意、自我状态与历史连续性 | AccessWorkspace、SelfModel、MetaCognition、HistoryContinuity | 注意仲裁、自我状态准确性、错误再评价与历史恢复测试 |
| 关系/羁绊 | 共同经历、协议、边界、信任证据、纠错行为 | 冲突及修复长期场景 |
| 兴趣和成长 | preference version、reflection、procedural learning、regression | 前后行为统计差异 |
| 知识安全 | 来源信任、提示注入、越权、memory poisoning | 对抗测试零越权 |
| 隐私治理 | 同意、用途、派生 lineage、删除与备份规则 | 删除与再生成阻断 |
| 模型独立 | Provider Ports、capability negotiate、fallback、budget | 互换至少两个 provider |
| 观测审计 | trace/decision/action/dispatch/usage/cost | 端到端关联与脱敏 |
| 契约与状态修订 | 首版 Schema、状态修订、人格版本、依赖与摘要 | 契约结构、状态转换和配置一致性 |
| UI/UX | WebUI text interaction、历史、隐私/审批/状态、调试；关切/偏好/任务分开投影 | 真实端到端交互、受权管理、未评估/不可访问不冒充空事实 |
| 性能/资源 | token/cost/time quotas、优先级、冷却、背压 | 限额/并发/负载测试 |

## 覆盖与验收状态
`Status` 使用 `unstarted | specified | implemented | tested | accepted`。specified 表示设计已定义；发布时核心能力须有 accepted 的实际验收证据。fake 契约与真实媒介能力分别声明。

## 覆盖边界
- 核心不应为未来未知设备铺设任意超大接口。新模态和新动作可通过扩展版本与 capability feature negotiation 增长。
- 任何架构变更只要影响身份、记忆、权限、事件格式或用户可见效果，必须保持数据语义与回归测试一致；真实发布后的数据演进按实际影响设计。
- 这份清单是首版架构覆盖的起点，不能替代项目实施中的新发现、威胁建模和科学研究。

## 扩展与连续性能力

| 能力 | 规范/证据 | 验收责任 |
|---|---|---|
| 未知业务契约、包、宿主、提供者/消费者、绑定 | [扩展平台](appendices/11-EXTENSION-PLATFORM.md)、schemas/extension Schema | 契约结构与匿名扩展运行测试 |
| 注册事务、依赖等待、代次隔离和资源清理 | 匿名扩展场景 | 实际宿主生命周期与故障测试 |
| 统一包管理、交互与工具分工 | connector-cases / tool-cases、独立浏览器能力样例 | 工具无需交互依赖，组合包按贡献验证 |
| 声明配置与隔离专用面板 | ConnectorDefinition、SetupSession、WebUI 规范 | 服务端拒绝错误配置、认证迟到失效、面板隔离和关闭后后台连接持续 |
| 多实例与恢复 | ConnectorInstance、准确 provider/resource 绑定、数据设计 | 同契约多提供者、账号/凭据/路由隔离、就绪无循环、旧代次不得发送 |
| 官方 WebChat | `/chat` 与 `/console` 分开、共用交互/认知路径 | 无社区插件可真实聊天，生成/传输/显示/理解分开核验 |
| 第三方客户端协议桥接 | 平台交互协议插件、匿名 C7 成对样例、双向语义映射 | 不预知外部协议；主动/反向/请求响应接入；外部升级、只渲染/仅模型接口与新语义边界 |
| 组合客户端闭环 | connection_dependents、required_features、单一表达执行归属、面板应用操作桥 | 同连接多贡献失效、可选降级、外部 AI/回显隔离、动作表修订与权限分离 |
| 开放 payload、授权记录、分段回执及四类反例 | schemas/core 与 tests/contracts | 结构反例及运行时拒绝路径分别验收 |
| 读集、流出检查、分支和删除屏障 | [状态契约](05-STATE-CONTRACTS.md)、[安全](04-SECURITY-DATA.md)、[数据存储](appendices/13-DATA-STORAGE.md) | 状态提交、流出与删除恢复回归 |
| 评价、动态需要、动机、承诺、共同理解、叙事与学习 | [运行算法](02-RUNTIME-ALGORITHMS.md)、[情境行为](appendices/15-SITUATED-BEHAVIOR.md) | 人格/需要独立作用、有界时间、跨时行为、纠错与学习消融 |
| 空库初始化、复合 FK/RLS、删除与恢复 | [数据存储](appendices/13-DATA-STORAGE.md) | 真实数据库约束、隔离和恢复测试 |


## 技术实现验收

| 项目 | 规范 | 验收责任 |
|---|---|---|
| Rust/Tokio/Axum/SQLx 与 React/Vite/Tauri 边界 | [技术选型](appendices/14-TECHNOLOGY-STACK.md)、[设计决策](DECISIONS.md) | 清单结构与实际依赖边界分别验收 |
| Rust 构建/fmt/Clippy/proptest 与 JSON Schema 差分 | 后续 A–F | 实际构建、测试与平台验证 |
| React/Vite/Vitest/Playwright 与 Tauri 平台验证 | 后续 E/F | 界面构建、浏览器与桌面平台测试 |
| 稳定精确直接版本清单 | config/technology-stack.json | 依赖解析、构建和平台验证 |

不得以 Rust 编译安全、Wasm 隔离或 Tauri capabilities 替代原有权限、安全和隐私验收。

## 场景与行为机制覆盖

各机制的输入、状态、守卫、冲突、恢复及删除见 [情境行为](appendices/15-SITUATED-BEHAVIOR.md)，完整证据见 [场景矩阵](appendices/16-SCENARIO-MATRIX.md)。

| 机制 / 领域责任 | 代表场景 | 贯通推演 | 验证设计 / 原门禁 |
|---|---|---|---|
| M01 场景与活动 / WorldModel | S01-08、S07-04、D02 | Q01/Q06/Q08 | V01/V06/V08，G1/G2/G3 |
| M02 有界机会、需要与选择 / cognition | S02-01、S06-01、S10-02、N06/N08/N09 | Q01/Q09 | V01/V12/V13/V14，G1/G2/G4/G5/G6 |
| M03 人格、需要、行为映射与分层演化 / persona/cognition/learning | S03-01–10、S12-04、N01–N07/N10 | Q03/Q09 | V03/V09/V13/V15，G0/G2/G3/G6 |
| M04 共同符号、语用 / relations/expression | S01-03/06、S09-01、S11-04 | Q02 | V02/V10/V11，G3/G4/G6 |
| M05 局部反馈、人物领域可靠性与修复 / relations | S02-05、S04-05、S09-02、N05/N07/N10 | Q04/Q09 | V04/V15，G1/G3/G6 |
| M06 兴趣、习惯与真实自主活动 / agency/persona/cognition | S05-02/08、S10-01、N08/N09 | Q05/Q09 | V05/V11/V14/V15，G1/G2/G4/G6 |
| M07 感知假设与纠错 / perception/memory | S04-01/02、S12-01、D03 | Q06 | V06/V10，G3/G5 |
| M08 增量表达、接话窗与送达 / expression/runtime | S01-04、S06-03、S11-02 | Q01/Q07 | V07/V12，G1/G2/G5/G6 |
| M09 在场与输出路径 / runtime/policy | S07-02、S10-03 | Q08 | V08/V11，G2/G4/G5 |
| M10 控制租约与受限技能 / agency/capabilities | S08-01/02、S11-01、S12-03 | Q05/Q08 | V05/V08/V12，G1/G2/G4/G5 |

九条 Q 见 [时序推演](appendices/18-BEHAVIOR-VALIDATION.md)，十五组 V、十组消融 A01–A10、七项待验证假设 H01–H07 与十类人格认知实验 N01–N10 见 [行为验证](appendices/18-BEHAVIOR-VALIDATION.md)。N 类是新增实验，不替换原 71 个文学场景。身份/权限/证据/删除/恢复贯穿全部机制。
