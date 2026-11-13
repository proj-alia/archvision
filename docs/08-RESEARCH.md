# 08 — 参考产品、公开证据和技术取舍（核查日：2026-11-12）

## AIRI（开源，研究机制不是复制外壳）
- 核心 Agent 关于 scheduling、context、`Conversation/Turn/Round` 和 tool invocation，明确将 core ports 与 stage UI 隔离： https://github.com/moeru-ai/airi/blob/0f77855b45c81314090abd5f6a77361cb5bd32cc/packages/core-agent/README.md
- 2026-10-10 已接受 ADR：角色主会话、skills/recipes、后台任务、automations、memory index + per-fact entries、静默通知： https://github.com/moeru-ai/airi/blob/0f77855b45c81314090abd5f6a77361cb5bd32cc/docs/ai/adr/2026-10-10-skills-automations-and-memory.md
- Minecraft 多层认知机制 perception/reflex/reasoning/action： https://github.com/moeru-ai/airi/blob/0f77855b45c81314090abd5f6a77361cb5bd32cc/integrations/minecraft/README.md
- 注意：上述资料同时说明该实现存在 open work，不可把所有计划/提案视为完全验证。

## Neuro-sama（公开 SDK，不是完整内部算法）
- 官方 SDK： https://github.com/VedalAI/neuro-sdk
- API：`context.silent`、动态 `actions/register`、`actions/force` 与 `action/result`： https://github.com/VedalAI/neuro-sdk/blob/3957516556cf2185b3bdc21f1d3d6660e54186aa/API/SPECIFICATION.md
- 最佳实践：优先有意义的事件，不要高频无关状态刷屏；行动结果须回报有效变化： https://github.com/VedalAI/neuro-sdk/blob/3957516556cf2185b3bdc21f1d3d6660e54186aa/API/BEST_PRACTICES.md
- 未公开的训练、记忆、人格和完整认知流水线无法凭 SDK 反向声称已掌握。

## Letta / MemGPT
- Core blocks、archival、conversation history 的职能分离：https://github.com/letta-ai/skills/blob/main/letta/agent-development/references/memory-architecture.md
- Agent State / multiple conversations 及 export/import：https://docs.letta.com/api/resources/agents
- 借鉴概念与存储策略，不将 Letta Agent ID 直接当成 ALIA 永久 identity 的唯一实现。

## LangGraph / Agno
- Checkpoints + long-term stores：https://github.com/langchain-ai/docs/blob/main/src/oss/langgraph/persistence.mdx
- tools/state/memory/knowledge/learning/workflow 分层：https://github.com/agno-agi/agno/blob/main/cookbook/00_quickstart/README.md
- 可以参考 durable workflow 与结构化学习机制，核心仍使用自有 ports，不要求引入这些框架。

## MCP / A2A
- MCP 2026-07-28 spec 概览：https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/docs/specification/2026-07-28/basic/index.mdx
- A2A 1.0 协议（AgentCard/Task/Message/Artifact/stream）：https://github.com/a2aproject/A2A/blob/main/docs/specification.md
- 两者是边界适配协议而不是 ALIA 本体；外部 agent messages 不能自动读取本体的私人记忆。

## Agentic AI Security
- OWASP Agentic Top 10，目标劫持、工具滥用、身份/权限、记忆污染、代理消息欺骗等：https://genai.owasp.org/2025/12/09/owasp-top-10-for-agentic-applications-the-benchmark-for-agentic-security-in-the-age-of-autonomous-ai/
- 实际 Q3 2026 exploit roundup：https://genai.owasp.org/2026/10/08/genai-and-agentic-ai-exploit-roundup-q3-2026/

## 证据与推断区分
“公开已实现/已有文档” ≠ “我们复现并测试通过”；“同类型模块存在” ≠ “效果不低于成熟系统”；“推导了架构” ≠ “解决数字意识”。对这些区别保持审计证据。

## 学术认知机制
- BDI: https://ijcai.org/proceedings/2020/684
- Generative Agents: https://research.google/pubs/generative-agents-interactive-simulacra-of-human-behavior/
- ReAct: https://arxiv.org/abs/2210.03629
- Reflexion: https://proceedings.neurips.cc/paper_files/paper/2023/hash/1b44b878bb782e6954cd888628510e90-Abstract-Conference.html

## 扩展机制证据矩阵
研究快照记录 AIRI 0f77855b45c81314090abd5f6a77361cb5bd32cc、Neuro SDK 3957516556cf2185b3bdc21f1d3d6660e54186aa 的文档及部分源码；未在本机运行其测试。Letta/LangGraph/MCP 等仅作公开研究参考，不作为 ALIA 已实现功能的证据。
| 结论类别 | 公开依据 | ALIA 取舍 |
|---|---|---|
| 源码/已有测试：清单、Kit、注册事务、会话代次 | [SDK](https://github.com/moeru-ai/airi/blob/0f77855b45c81314090abd5f6a77361cb5bd32cc/packages/plugin-sdk/README.md)、[注册测试](https://github.com/moeru-ai/airi/blob/0f77855b45c81314090abd5f6a77361cb5bd32cc/packages/plugin-sdk/src/plugin-host/hosted-kits.test.ts) | 提取对象边界、回滚和旧句柄隔离，测试存在不等于我们已运行 |
| 源码：依赖未就绪等待、权限解析默认回退 | [宿主](https://github.com/moeru-ai/airi/blob/0f77855b45c81314090abd5f6a77361cb5bd32cc/packages/plugin-sdk/src/plugin-host/core.ts) | 学习等待机制；不继承缺少 resolver 时回退申请权限的默认行为 |
| 后续阶段：通用扩展间方法/事件路由 | [Kit 契约](https://github.com/moeru-ai/airi/blob/0f77855b45c81314090abd5f6a77361cb5bd32cc/packages/plugin-sdk/src/kit/contract.ts) | Phase 3 保存 handler、Phase 4 路由，不声称完整路由已验证 |
| 设计/提案：控制数据面、多运行位置 | [平台设计](https://github.com/moeru-ai/airi/blob/0f77855b45c81314090abd5f6a77361cb5bd32cc/packages/plugin-sdk/docs/design/architecture.md)、[传输设计](https://github.com/moeru-ai/airi/blob/0f77855b45c81314090abd5f6a77361cb5bd32cc/packages/plugin-sdk/docs/design/multi-transport.md) | 吸收分面/宿主管理传输，可靠性和隔离须自行实现验收 |
| 源码：按来源替换/追加上下文 | [ContextRegistry](https://github.com/moeru-ai/airi/blob/0f77855b45c81314090abd5f6a77361cb5bd32cc/packages/core-agent/src/runtime/context-registry.ts) | 加上 ALIA 的 ACL、TTL、revision 和删除屏障 |
| 官方接入协议：能力描述、静默观察、动作反馈 | [Neuro 规范](https://github.com/VedalAI/neuro-sdk/blob/3957516556cf2185b3bdc21f1d3d6660e54186aa/API/SPECIFICATION.md)、[实践](https://github.com/VedalAI/neuro-sdk/blob/3957516556cf2185b3bdc21f1d3d6660e54186aa/API/BEST_PRACTICES.md) | 提取认知可理解描述与反馈；action/result 常在执行前回报，不能映射真实 completed |
| 官方协议：可选旁路与降级 | [Voice Chat](https://github.com/VedalAI/neuro-sdk/blob/3957516556cf2185b3bdc21f1d3d6660e54186aa/API/VOICE_CHAT.md) | 提取可选扩展和热数据独立生命周期，不把当前音频格式固定成内核 |
| 成熟扩展工程参照 | [VS Code Extension Host](https://code.visualstudio.com/api/advanced-topics/extension-host) | 契约与执行位置分离；不据此推断其具备 ALIA 伙伴语义 |
| ALIA 自身新增设计 | [设计决策](DECISIONS.md) | 语义接入、读集、撤销/删除屏障、身份连续性与学习治理；不是上述作品已解决的事实 |

## 技术选型研究

成熟作品的 WebUI、桌面及后端清单已记录到 [技术选型](appendices/14-TECHNOLOGY-STACK.md) 与 [机器版本清单](../config/technology-stack.json) 的固定 reference_projects。当前公开分支的依赖不等于产品完整稳定性验证。Rust 选型来自用户明确选择，没有 Rust/Go 性能基准；版本登记库元数据不等于完整组合通过构建。

## 日常互动与情境行为研究

研究查阅以下原始论文的摘要及与机制相关段落；没有复现实验或测量其模型。E 为论文在其设定中的结果；D 为 ALIA 自身设计推导；H 是尚待验证的效果。项目不把论文结论泛化为所有模型，也不把外部延迟数字当本机保证。

| 研究（E） | 可以支持什么 | ALIA 的推导 D / 尚未证明 H |
|---|---|---|
| [Grounding Gaps，NAACL 2024](https://arxiv.org/abs/2311.09144) | 所测模型在协作任务中常直接假定共同理解，grounding 行为与人类存在差异 | D：CommonGround 分开送达、采纳、误解与修复；H：这种显式状态是否改善陪伴熟人感 |
| [A General, Abstract Model of Incremental Dialogue Processing，2011](https://noah.nrw/ubbihs/download/pdf/5118474) | 增量对话架构处理未完成输入、修订、模块并发与替代解释 | D：感知假设可撤回，未播片段重新规划；H：中文场景中具体分段策略与接话质量 |
| [Moshi，2024](https://arxiv.org/abs/2410.00037) | 全双工语音架构通过并行语音流处理互动，而非只串联整轮问答 | D：能力契约要求重叠输入、取消与输出门控；H：提供者中文韵律、延迟、可控发布与设备适配表现 |
| [EMA: A Process Model of Appraisal Dynamics，2009](https://people.ict.usc.edu/~gratch/CSCI534/Readings/COGSYS-RS-EMOTION-2008-6.pdf) | 评价动态与对主体—环境关系的解释变化相连 | D：新观察/推断更新 Appraisal 再改变选择，不只给台词加情绪词；H：人格映射与关系反馈的有效性，不论证真实情感 |
| [Generative Agents，2023](https://arxiv.org/abs/2304.03442) | 模拟环境中的记忆、反思、规划及其消融为可信行为研究提供参照 | D：真实活动结果进入经历，再经验证影响偏好/习惯；H：长期自然度与跨媒介推广。论文不替代 ALIA 的权限/删除设计 |
| [LongMemEval，ICLR 2025](https://arxiv.org/abs/2410.10813) | 区分信息提取、多会话推理、时间推理、知识更新与证据不足时不作答 | D：V10 分能力建保留集；H：记忆正确性是否带来恰当回用/关系连续性。记得不等于该说 |

研究到设计的追踪：grounding→M04/Q02/V02；增量与全双工→M07/M08/Q06/Q07/V06/V07；评价→M03/M05/Q03/Q04；记忆/反思/规划→M06/Q05/V05；长期能力→V10。场景本身能推出的需求与论文依据分开记录，详见 [情境行为](appendices/15-SITUATED-BEHAVIOR.md) 和 [行为验证](appendices/18-BEHAVIOR-VALIDATION.md)。

## 开放愿景参考（2026-11-13）

[AIRI README](https://github.com/moeru-ai/airi) 将 waifu、虚拟角色、数字伙伴与赛博生命置于同一愿景，并用交谈、游戏、共同观看和跨设备体验说明目标。ALIA 借鉴这种开放表达，采用自己的愿景与功能验收；不将外部项目的宣传、路线图或“最好”等主张作为已验证事实。见 [设计决策](DECISIONS.md)。
