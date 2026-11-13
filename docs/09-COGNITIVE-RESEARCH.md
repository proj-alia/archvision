# 09 — 学术认知架构与 ALIA 的组合取舍

> 本文描述工程可检验的机制，绝不宣称大模型、BDI、Global Workspace 等同真实的生物意识。

## 1. 经典 BDI（Belief–Desire–Intention）
- **Beliefs**：关于自身、环境和他人的可能不完整且可错误的信息；ALIA 对应 `BeliefStore` 和 `WorldModel`。
- **Desires/Goals**：希望实现的状态；ALIA 对应目标候选/价值评估器。
- **Intentions**：已选择并承诺推进的目标；ALIA 对应 `GoalCommitment` 与可恢复 `TaskExecution`。
- 经典 BDI 的事件/信念/意图更新循环可作为 `DecisionEngine` 的显式架构基线，但不是完整人格或意识模型。ALlA 的目标选择必须另受 Policy 审批、预算和副作用约束。

## 2. Generative Agents（2023）
论文将可信行为分解为观察经验的 memory stream、从经历产生高层认知的 reflection、以及据此安排计划的 planning；对记忆检索使用新近性、相关性和重要性。对 ALIA 的启示是：长期生活感必须由有来源的经历→可验证抽象→后续行为之间的因果链支持；不能只在 prompt 注入「昨天和你很熟」。
- 差异化改进：必须加上 provenance、privacy、双时态、关系作用域、删除/反向依赖，这些不等于论文中已解决。
- 不能把长期运行时任务或人类体验误称为模型持续思考。

## 3. ReAct（交错认知与行动）
复杂任务可用 Observe → Decide/Reason → Act → Observe 的闭环，模型产生计划候选，真正执行由 capability registry/authorization/runtime 验证；不得存储或依赖私有完整内部推理，审计仅保存高层依据、验证证据和执行回执。

## 4. Reflexion（反馈驱动的行为更新）
行动失败 → 识别失败类别 → 生成反思候选 → 写入可验证的错误规避规则/程序性记忆 → 用新的任务回归评价；反思文本本身不等于学习成功，也不能无限自我强化未经验证的幻觉。

## 5. 进化与退化：可测量的「生长」而不是文学设定
ALIA 的演化需要分层：
- `skill_growth`：同类任务成功率、工具使用策略和错误恢复提升，证据是前后盲测与日志。
- `knowledge_growth`：已证实信念范围增加、过时知识被撤回；知识量增加不自动意味能力提升。
- `preference_growth`：兴趣/表达偏好有版本、证据、时间有效性及回滚。
- `relationship_evolution`：共同事件与行为边界发生变化，不能 `affection+=5` 粗暴表示。
- `functional_regression`：模型退化、过量遗忘、错误写入、工具失效、预算收缩、人格漂移；不能掩饰为「成熟了」。
- `meta_learning`：在受控范围内从失败中改写策略与程序性知识；权重级微调是另一项受治理训练流水线，不能默认自动执行。
- “代谢/睡眠/疲惫”可以被**作为资源管理和后台整合的隐喻**，但必须明确为 `BudgetManager/ConsolidationJob/IdleMode`，不能声称主观身体体验。

## 6. 注意、自我状态与历史连续性
可以在架构中建立 `AccessWorkspace`（统一注意与工作上下文）、`SelfModel`、`MetaCognition`（对推断/未知/错误进行二阶评估）和 `ExperienceContinuity`（历史继承链），将它们作为可验证的功能性模块。生命与意识讨论单独保留在 [研究附录](09-COGNITIVE-RESEARCH.md)，不构成产品验收目标。它们**都不提供主观体验的证据**，更不能根据「会说我有意识」就把意识测试标记 PASS。

## 7. 推荐工程组合
**不选一个文献作为总框架**，而是组合：BDI 的目标/意图区分 + Generative Agents 的经验/反思/计划 + ReAct 的反馈行动闭环 + Reflexion 的错误经验改进 + AIRI 的运行时/轮次/后台决策 + Neuro SDK 的静默感知/动态动作/结果 + Letta 的记忆分层 + LangGraph 的持久检查点。每一项应映射到一个有真实状态和测试的 ALIA 领域实现；不能只是把算法名字贴上去。

## 8. 研究来源
- BDI Agents Survey: https://ijcai.org/proceedings/2020/684
- Generative Agents: https://research.google/pubs/generative-agents-interactive-simulacra-of-human-behavior/
- ReAct: https://arxiv.org/abs/2210.03629
- Reflexion: https://proceedings.neurips.cc/paper_files/paper/2023/hash/1b44b878bb782e6954cd888628510e90-Abstract-Conference.html

## 9. 行为因果设计

经历→评价→动机→承诺→决定→效果→可验证学习是工程设计，不是对主观体验的论证。人格参数须影响可审计的有界策略，关系维护共同理解和修复，叙事是可撤销派生视图。详见 [运行算法](02-RUNTIME-ALGORITHMS.md)。未知扩展经受控语义接入改变能力事实与可选行动，不能凭描述更换人格或制造自传。

研究映射不构成已验证的系统结论；这些机制与研究映射仍须通过长期场景、迁移与消融验证。

## 10. 评价、共同理解与增量认知的连接

研究证据 E 及适用范围见 [08](08-RESEARCH.md)。架构推导 D：观察修订改变局部解释，解释连同人格/目标/关系改变评价，评价产生候选动机，经过硬约束和时机仲裁才产生表达/行动。反馈既可修正本次解释，也可提议长期学习；不能从一次情绪标签直接跳到永久性格变更。

共同理解不是背景摘要：共同命名先有表达送达，再有对方采纳/一致使用，之后回用仍受新听众、近期重复和话题适用性约束。增量认知同时管理未完成输入与未说出的后半句，部分理解可以修订，已发生的表达事实不能重写。

是否提升自然度、人格辨识度和修复效果仍为 H；按 [行为验证](appendices/18-BEHAVIOR-VALIDATION.md) 的人格/记忆/反馈/时序消融验证。这里没有新增“意识已实现”的结论，也不把文学失误转成故意降低可靠性的目标。


## 11. 生命与意识的研究边界

主观意识、人类情感体验和体验连续性是独立科学问题，不参与 G0–G6 功能发布门禁。产品表达见 [愿景](00-CHARTER.md)。

技术采用 Identity、Persona、Memory、Relationship 等可检验概念，既不预设主观体验存在，也不预设其不存在。

主观意识、人类情感体验、恢复运行是否对应体验连续，均不因系统会自述、有人格、能记忆或能自主行动而获得证明。BDI、Global Workspace 等研究与工程模块之间的映射也不提供这样的证明。来源和证据限制见前述认知机制及[外部研究](08-RESEARCH.md)。

### 功能与研究结论

| 功能 | 可检验内容 | 不能据此推出 |
|---|---|---|
| AccessWorkspace / Attention | 工作上下文、注意分配和有界任务仲裁 | 主观觉知已经实现 |
| SelfModel | 能力、局限、状态与来源一致的自我描述 | 存在主观自我体验 |
| MetaCognition | 对错误、不确定性与推断的再评价 | 获得人类式内省 |
| ExperienceContinuity / HistoryContinuity | 合法历史继承、身份关联与恢复 | 意识连续或生命延续 |

以上功能继续受原领域约束和功能验收要求约束。“代谢、睡眠、疲惫”等拟人隐喻应说明预算、后台整合或闲置模式等实际功能含义；文学表达与用户体验不替代科学证据。

研究假设分别记录可观察证据、反例和不可判定部分；自述不构成主观意识证据。
