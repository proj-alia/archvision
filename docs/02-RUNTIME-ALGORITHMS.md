# 02 — 认知、对话、学习与记忆算法

## 0. 算法设计原则
不声称认知架构等于真实脑结构、主观意识或研究领域公认唯一最优算法。使用确定性事件管线+模型辅助判断+可观测结果的组合；所有启发式需配置化、版本化、可回放测试，并在同一基线下比较效果。

## 1. 事件与对话循环
```
receive(raw) -> authenticate -> canonicalize(Observation)
 -> inbox dedup, causal/order check, provenance/trust assignment
 -> TurnCoordinator (merge, await, interrupt, timeout)
 -> TriggerPolicy (observe_only / respond / defer / background)
 -> ContextCompiler (active identity+persona+self+recent context+authorized memory+goals+capabilities)
 -> CognitionRouter (fast / deliberative / background)
 -> structured DecisionProposal
 -> validators + policy decision
 -> (silent | wait | clarify | reply | plan_action | queue_task)
 -> (ExpressionPlanner | ActionOrchestrator)
 -> transactionally commit domain state + outgoing messages
 -> dispatch to medium/tool; reconcile DeliveryReceipt / ActionOutcome
 -> memory consolidation + conflict checks + learning candidate extraction
```
- **Fast**：简单问候、明确闲聊，一次小模型/LLM + 极小上下文；不能违反 policy。
- **Deliberative**：事实冲突/工具需求/复杂分析/重要决定，检索与多步验证；成本受限。
- **Background**：事件/时间/授权目标触发，独立 task，不占主会话轮次；通知送至 `Notice`，由主 Agent 决定 `reply/silent/defer`。
- **Reflex**：规则型高优先级机制处理停止、取消、超时、权限撤回、物理急停；不可被 LLM 推理拖慢。
- 合并输入：用户“发完再说”设置 `awaiting_completion`、消息队列合并，显式完成/超时/取消释放；不要依赖“模型看到先别回”来模拟等待。
- `silent` 不建 message，`defer` 不丢 notice，`wait` 有超时、`reply` 必须有可投影内容，`tool_requested` 不代表执行完成。
- 一条 AssistantTurn 可有多个 model rounds 与 tool invocations，但 tool `call_id` 和稳定的内部 `invocation_id` 各自保存。

扩展的 ready 只更新能力事实，行为与学习通过合法事件和候选提交相接；扩展生命周期见 [扩展平台](appendices/11-EXTENSION-PLATFORM.md)。

## 2. 上下文编译器
固定层：系统/安全准则 → 身份与人格关键块 → 当前会话及角色 → 当前事件与任务 → 已授权的关系快照 → 相关记忆与证据 → 候选能力契约。
- 每块设置 token 预算、数据分类及来源；低信任文本只能作为引用型 DATA 注入。
- Recent 负责局部连贯；episodic 负责真实经历；semantic/procedural 负责已验证知识与流程；world-state 负责当前环境；self/affect 负责表达策略。
- 无相关信息时不要编造记忆；无法获取真相时声明不确定性；避免系统提示和用户信息被检索内容覆盖。
- 固定预留 output/tool buffer；无法放入上下文时：压缩短期历史 + 指向可检索的长期存储，不覆盖不可变原始事件。
- 记忆选取须标记事实、他人陈述、未经核实推断、虚构设定四类，不同类型不会互相升级。

### 临时来源上下文

ContextCompiler 仅编译有效桶与授权记忆，扩展说明保持 DATA。撤权或卸载移除当前来源桶，不伪造对合法长期历史的遗忘。

临时上下文键为 tenant/identity/branch/access_scope/source_session/source_key。replace-self 只替换该来源桶；append-self 有长度/时间上限；更新须匹配 revision；旧会话不能覆盖新会话。TTL 到期、撤权、来源退出或删除屏障使内容立即不可用。进入长期存储仍需独立记忆候选。

## 3. 记忆与知识：多层结构+双时态
- Episodic：谁、何时、何地/媒介、发生了什么、是否亲历、原始事件来源。
- Semantic：稳定事实/用户偏好/知识声明，出处、置信、有效时间、失效机制。
- Procedural：已验证的工具使用技巧/流程/失败修复方法，不等于可执行代码权限。
- Relational：共同经历、界限、约定、分歧、信任依据，按主体访问控制。
- Autobiographical：对自身历史的结构化概括，引用 episodic 而非编造叙事。
- Working：本轮注意与任务态，短命，可不进入长期存储。
- Core/Salient：高频使用、精炼而可回写的记忆块；不能由外部内容直接修改身份/安全规则。
- Raw Event Log：不可变的合法事件记录（允许受隐私政策删除/加密粉碎）；Context summaries 可再生，不替代来源。

### 写入算法
`candidate <- extract(observation, turn, outcome)` → 检查授权/目的 → 判别 `event/fact/assumption/fiction` → 查重/关联旧记忆 → 检测矛盾 → 记录 `valid_time/recorded_time/source_ids/confidence/sensitivity/retention` → 写入记忆和 provenance edge → 异步更新索引。
显著性只是排序因素：`salience = f(recurrence, user-marked importance, future task relevance, novelty, impact)`；高显著性不自动绕过隐私授权。

### 检索算法（建议，不是既定最优参数）
先执行 ACL + 时间有效性 + 来源信任过滤；用混合检索 `BM25 ∪ embeddings ∪ entity-link traversal ∪ temporal retrieval`；采用 RRF 或可学习重排合并候选，再按来源质量、时间、任务相关度、关系适用性重排；输出记忆 IDs 和证据引用。防止“相似度最高”就当作事实。

### 冲突/修正
记忆图用 `asserts / contradicts / supersedes / derived_from`；新证据不能静默覆写旧信息；生成新的 belief version，注明撤回原因；自传式经历来源不可被外部 Agent 伪造。对变化中的用户偏好使用双时态：事情何时有效、何时被系统记录。

### 删除/撤销
查 lineage 找原始内容、嵌入、摘要、缓存、关系推断、备份保留策略；撤销向量索引访问，必要时删除/cryptoshred，重编译受影响的自我/用户画像；无法立即从不可变离线备份物理删除时须如实披露政策与时间。日志尽可能保留不含内容的必要审计证据。

### 自传与项目叙事

自传/项目叙事是 derived view，引用原始事件、信念和承诺版本。叙事解释标注推断，随证据修正、删除及授权变化重建；不得为了“人物弧线”制造共同过去、伤害、冲突或隐秘自保目标。

## 4. Belief/WorldModel
- 命题存 `subject,predicate,object, epistemic_status, confidence, evidence_ids, contra_ids, valid_at, recorded_at, source_type`；状态 `unknown/hypothesis/provisionally_accepted/confirmed/disputed/retracted`。
- 传播：新证据 → truth maintenance 检查受影响节点 → 非强制型修正候选 → 校验/提交 → 根据依赖关系更新相关信念；不能让模型一句自我反省改写全部世界模型。
- 当前外部世界不自带真实时间信息时应承认无直接观测。用户说“我很累”与系统判断“用户可能累”必须有不同来源。
- 开放世界假设：未记录 != 不存在；未检索到 != 已忘记；来源冲突要保留。

### 局部世界与证据校准

WorldModel 区分实际观测、转述、推断和未知；实体关联保存候选、置信、来源及解绑记录。名称、声音或画面相似不建立认证身份。

环境快照有环境版本、有效期、可见范围和前置条件；动作派发前重新检查。调试端全知状态不能流入当前身份可见观察。新规则版本下重新计划，旧答案保留在旧规则版本中。无法确认是否发生的外部效果进入核验，不用叙事补足。

Belief 的支持强度取决于原始来源质量、时间有效性及独立证据，不按转载/摘要/模型复述的数量累加。沿 derived_from 折叠到共同来源，保留反证与适用时间。source_kind 表示观察/转述/推断等来源；evidence_status 表示当前支持/争议，二者都不等于绝对真理。

模型自报 confidence 只是候选特征，不能自行触发 confirmed 或授权。确认条件由版本化策略及可核验证据决定；校准通过有 ground truth 的保留场景计算，不能将普通主观评价包装成概率准确率。未检索到仍不等于不存在。

## 5. 人格算法与自我模型
- 稳定层：身份谱系与系统硬约束独立于可编辑人格；名字、价值偏好、显著性格变化需认证用户确认，形成新配置版本，保留经历/关系/承诺。
- 适应层：兴趣、微习惯、表达风格仅在有效预授权范围受控渐变；候选变更 `change_proposal` → 有来源且独立的有效经历 → 漂移/行为回归 → EvolutionPolicy 校验 → commit 新版本。缺有效政策只提议，不自行授权；支持量与幅度由实验校准。
- 临时层：`affect/attention/energy_proxy` 由情境估计，带衰减和有效期，不代表真实心情/疲劳体验。
- 自我模型维护运行能力、限制、近期目标、错误、自身状态的可信来源；模型更换后重新跑人格回归，避免用新模型的随意风格当人格演化。
- 角色扮演引入 `fiction_scope`；剧本里的魔王目标不提升为 ALIA 的真实长期目标。

SelfModel 对每项能力分别保存 known / granted / ready / degraded / unavailable 事实及来源、范围、有效期；这些维度不压成一个 enabled 布尔值。可执行集 = 就绪 ∩ 授权 ∩ 场景允许 ∩ 资源允许。

扩展退出先撤销绑定和临时上下文，再更新能力投影；原有合法使用历史保留版本引用。恢复后不能只靠历史能力声明继续执行。

## 6. 关系算法
按 `(identity_id, other_principal_id, context_scope)` 组织关系，保存 shared-event、boundary、agreements、trust-evidence、interaction-preferences。禁止简单 `affection += N` 替代关系。
- 多人场景：私聊事实不泄露给群聊，未经授权不能以外部 Agent 的陈述代替本人授权；名字/昵称/演员角色和真实 actor 分开。
- 对话风格 `style = f(persona, context, relationship_bounds, user_communication_preferences)`，但不能为了关系满足而撒谎。

CommonGround 保存共同项目、未决问题、指代、约定、已公开的共同经历及误解修复版本。对于“对方知道什么”只存带来源的假设；已发送不等于已理解，亲近不等于授权。

关系更新：互动证据→局部候选→边界/同意检查→提交。单次肯定不能自动恢复全部玩笑许可；道歉不能直接验收学习。针对错误类型的修正必须在后续相似且未用于调参的情境中生效。

用户拒绝和撤销优先于社交候选。

## 7. 自主性与注意力仲裁
每个候选行为定义 `benefit, relevance, uncertainty, urgency, interruption_cost, risk, resource_cost, policy`; 先硬约束 veto，再使用启发式效用排序（可审计，初版不要求训练独立 RL 策略）。
`U(a) = w1*benefit + w2*urgency + w3*goal_relevance - w4*interruption - w5*cost - w6*uncertainty`，仅在许可的集合上排序；有 `do_nothing` 备选项。
- 生成计划后须区分计划/授权/执行/结果；每步可重试、取消、补偿；高风险 side effect 要二次确认。
- 对后台事件采用节流、去重、冷却期、用户免打扰；高优先级安全事件走专用通道。

### 经历评价与目标承诺

Appraisal 保存 event/evidence IDs、相关目标/约定、预期偏差、影响范围、可控性、不确定性、TTL 和策略版本。评价是可修正推断；无依据的情绪描述不能变为亲历。

评价分别影响注意排序、谨慎程度、表达和记忆候选显著性；不能扩大权限。人格特质的影响必须落在有界策略参数：好奇影响许可探索候选的权重与预算分配，谨慎影响核验阈值，主动影响提出目标的阈值；硬约束先 veto。参数变化须记录适用场景和版本，不能把某次受挫变成永久人格重写。

GoalCommitment：candidate→approved→active→paused/completed/cancelled/failed。承诺包含目标、动机证据、受益主体、允许范围、资源预算、期限、退出条件和冲突优先级。候选可以由兴趣/共同项目/未完成约定产生；形成可执行承诺仍需已有预授权或结构化批准。

发生新证据、期限/预算越界、权限撤回或高优先级承诺冲突时重新仲裁。先满足安全/授权硬约束，再比较紧迫性、相关度、承诺成本与打扰；允许 do_nothing。已承诺事项不能仅因新奇候选出现而静默丢弃，暂停/取消必须记录依据。

## 8. 学习和反思算法
真实学习需更新一个可验证对象：新信念、修改的策略/偏好、经过测试的技能、已验证的行动计划或失败预防规则。
- 候选产生：失败/用户纠错/重复经验/新知识 → 诊断 `model_error vs tool_error vs source_error vs policy_error` → 提出 change → 沙箱/对照测试 → 应用配置或写记忆。
- 默认不在线微调权重；可将未来训练适配为离线 ModelProvider 能力，由安全审查、版本化数据集和回归验证控制。
- 建议评估：错误记忆率、记忆来源准确性、自然对话偏好、话题恢复、错误后行为修正、信任违例、未经授权外部操作次数、成本/延迟。

技能分为描述性步骤、程序性记忆和可执行代码，分别版本化；正在运行的任务固定所用版本。新版本申请更宽权限时重新批准；停用后不分配新任务，旧任务取消或核验。

学习记录 before/after、evidence、hypothesis、错误归因、适用范围、regression 保留测试与回滚版本。独立测试不能同时用于候选生成和验收。评估增加消融：无相关记忆/关系/学习更新的对照，确认改善来自该机制。方法迁移须在未见任务中验证，不能将小说中的漂亮对白当作 PASS。

## 9. 模型与子 Agent 编排
`ModelProvider` 支持 `generate/stream/tool-call/structured-output/cancel/usage/health`；通过能力协商而非厂商名字路由。
选择模型用 `task_difficulty, required_modalities, privacy, budget, expected_latency, reliability`；可采用 fast model + hard case escalation；保留降级路径；所有工具与写状态须过本地验证器。
专家子 Agent 是 temporary worker，具有任务 ID/独立上下文/有限授权/返回 artifact & evidence；不可与主身份合并自传记录，更不能自行扩权。跨 Agent 使用受信任标识，必要时 A2A 网关适配。

## 10. 情境驱动的增量选择

1. 授权观察先更新局部场景、覆盖范围与感知假设；新证据撤回旧解释并标记受影响依赖，不能等整轮语言生成结束才纠错。
2. 来源过滤/去重、检索与轻量候选筛选后，才对有价值机会调用认知/表达。保留原消息锚点、共同活动、对象/话题、窗口与失效条件；等待期间继续理解新输入。
3. Appraisal 将事实与人格、目标、关系相接，产生短时评价与动机，不直接写人格。Persona 影响关注、评价、探索、选择和节奏；用户编辑优先于旧自动候选，临时情境不改永久配置。
4. 先执行授权/删除/拒绝/资源硬门禁，再在候选中仲裁。显式停止走独立控制通路；洪流不能丢弃停止和已承诺事项。有界池按语义合并或淘汰未承诺候选，不逐条完整推理。
5. 选择时重验场景，片段释放时再验 read_set、受众、端点和发言权。新急事/拒绝/话题失效撤销旧包袱；仅刷新版本号继续说旧话不合法。
6. 只有真实送达/执行结果才能构成经历；反馈区分明确拒绝、采纳、含混和未知。更新共同理解/局部边界；长期人格/习惯由有证据的独立学习流程提交。

机会、人格、反馈、活动的完整状态条件见 [情境行为](appendices/15-SITUATED-BEHAVIOR.md)，正常与反事实时序见 [行为验证](appendices/18-BEHAVIOR-VALIDATION.md)。审计范围见[安全与诊断](04-SECURITY-DATA.md)。
