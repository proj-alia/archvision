# 专题附录 — 数据、初始化与恢复

本文定义逻辑数据归属、约束与恢复；首版从空库初始化。

## 1. 身份与核心聚合

| 聚合 | 键与强制责任 |
|---|---|
| identities / identity_branches | tenant_id + identity_id，分支另含 branch_id；稳定身份独立于名字、账号、模型和设备；谱系固定共同历史快照 |
| actors / conversations | 认证 Principal/Actor、参与者与受众独立建模，不能作为身份或全部经历的替代 |
| events / snapshots | tenant/identity/branch + sequence 唯一；事件、当前状态版本与 outbox 同事务；快照关联确切 reducer 与契约 |
| persona / memory / beliefs / relations | 各聚合唯一写入者、预期版本提交；来源边、有效时间与记录时间分开，保留必要修订和撤回依据 |
| goals / tasks / checkpoints | 可取消、暂停、恢复；计划、执行结果和外部效果分别记录 |

活动对象具有 tenant/identity/branch、data_policy（owner、purpose、classification、retention、lineage）。access_scope 表示授权域，不等同于敏感等级。复合归属与引用由存储约束验证。

记忆 source_kind、evidence_status、lifecycle 分开；来源未知只可候选，不能成为已确认亲历。虚构使用 fiction_scope。effective_from/effective_to 与 recorded_at 分开；区间结束晚于开始。删除后只保留最少 tombstone，不保留可恢复原内容。

## 2. 扩展、授权与交付

这些是逻辑聚合和一致性责任；可共用物理表及事务，不要求独立服务。

| 表/聚合 | 主键、索引与强制约束 |
|---|---|
| contract_versions | tenant + contract_id + version 唯一，固定 schema_digest；同版本修改拒绝；保留授权允许的历史契约用于回放 |
| extension_packages / installations | 包 ID/版本/摘要不可变；安装与启用分离，授权范围按 installation 保存 |
| extension_sessions | tenant + session_id 唯一；generation 由宿主单调分配；session 引用安装/包摘要，终态不能复用 |
| provider_registrations | tenant/session/generation/contract/version 的提供者槽唯一；同一契约允许多个安装/会话并存；保留、发布、撤销与 generation 同事务 |
| consumer_bindings | tenant + binding_id；复合 FK 指向准确 provider/session/generation/contract；失效与替换不得重定向旧绑定 |
| connector_definitions / ConnectorManager | 包内 definition_id/version/摘要不可变，按 installation 可用性发现；交互接入专用，不为工具创建空定义 |
| connector_instances / ConnectorManager | tenant + connector_id 唯一；关联 installation/definition 精确引用；配置与运行修订分列，记录 applied_configuration_revision/connection_generation，账号和凭据不得跨实例混用 |
| setup_sessions / ConnectorManager | tenant/connector_id/setup_id 与操作者、配置修订、宿主会话代次、步骤修订和 TTL；认证终态不恢复为活跃挑战 |
| credential_slots / CredentialStore | tenant/installation/resource_type/resource_id/slot 归属；交互资源为 connector.instance，工具使用其获准资源；仅持引用，普通配置、诊断和 UI 不复制已有密钥 |
| extension_calls / stream_checkpoints | binding + request 唯一；领域动作幂等键含 tenant/branch/capability，交互管理另按 tenant/connector/operation/配置修订去重；序列与 cursor 仅在匹配契约内恢复 |
| authorization_records | 不可变授权 ID、参数摘要、受众、有效期、policy_revision、revocation_epoch；由策略服务写入，客户端只可引用 |
| context_sources | tenant/identity/branch/access_scope/source_session/source_key 唯一；revision 乐观锁、expires_at 索引 |
| deletion_barriers | tenant + protected resource/scope；monotonic epoch，与 tombstone 持久保存并先于派生任务提交核对 |
| output_deliveries / delivery_segments | tenant/branch/output/channel/audience/segment 唯一；位置范围与状态检查，content_ref 关联受控已发内容 |
| appraisals / commitments / common_ground / learning_changes | tenant/identity/branch + object_id/version；证据边、适用范围、状态、读集和回滚引用 |

身份域对象的跨表关联使用包括 tenant/identity/branch 的复合 FK，或经过明确授权的 inherited-from 分支引用；租户级扩展包与契约按 tenant 和各自作用域关联，不强加身份字段。不允许仅靠全局 memory_id 绕过分支边界。分叉固定共同历史快照/祖先版本，后续写入归新分支。删除共同祖先敏感数据时查 lineage 同时处理继承分支，不以只删当前分支替代撤回。

CHECK：version/generation/sequence 非负、有效时间区间、终态/送达范围有效、活动记忆至少一个来源。跨行来源存在性、授权有效性、读集新鲜度由事务验证器及 FK/触发约束配合完成；JSON Schema 不能证明这些事实。

domain event + state version + outbox 同事务提交，消费者 inbox 唯一去重；snapshot 指向确切 schema/reducer/contract 版本。当前回放不得再次执行外部能力。


BindingGrant 与行动 AuthorizationRecord 分别表达绑定许可和单次动作许可，不能互代；均由可信 Policy 保存并验证撤销状态。Schema 合法不证明授权真实。

connection_dependents 随不可变连接定义保存，引用既有贡献，不创建第二套连接/提供者记录；安装时检查单一连接所有者及能力子集，运行绑定携带相同实例资源。配置、启停、重连和撤权使关联服务准入同步失效；每项能力是否仍可用由声明依赖与实际观察派生，管理状态不反向决定领域人格。记录外部协议兼容诊断和映射/动作资源修订用于核验，不能把旧探测快照恢复为当前可用事实。

外部回显关联到既有 output_delivery_id/segment_id 或操作记录，参与者输入沿原 inbox 去重；不把同一自发输出重新写为用户经历。表达的执行归属与关联在 outbox 中唯一选择，交互与渲染路径不能重复发送；不确定的外侧效果仍进入核验。

## 3. 情境行为与派生状态

| 逻辑聚合 / 所有者 | 关键关联与归属 | 存储/约束 / 删除恢复 |
|---|---|---|
| 场景与活动投影 / WorldModel | tenant/identity/branch/access_scope；活动 ID、参与者、话题、对象；每个来源会话/覆盖/修订 | 每场景当前版本唯一；证据覆盖区间有来源，活动状态与传感覆盖分列；恢复后过期覆盖设未知；删源重算投影 |
| 感知解释 / Belief | 原观察、替代解释、实体候选、修订/反证边、有效时间 | 解释可多条，不以实体名唯一合并；当前投影引用可用版本；纠错与依赖失效同一提交屏障；删除不留可复原原图的描述 |
| 需要定义 / cognition | NeedDefinition ID/版本、受信任配置来源、可用性、语义和时间校准配置精确引用 | 版本不可变，发布与人格采用分开；停用阻止新选择但不改历史；迁移记录旧/新定义及人格版本，稳定偏好语义改变沿必要确认 |
| 动态需要 / cognition | NeedState ID/版本、tenant/identity/branch/access_scope、fiction_scope、对象/问题/活动连续性、定义/人格/评价/原始证据/目标引用、强度与支持、窗口及 data_policy | 同一关切仅一个当前实例；别名/对话/定义升级不自动分裂。贡献按原始来源修订替换，时间区间去重；active 与 settled/expired/invalidated/withdrawn 依据分别保存 |
| 评价与动机依据 / cognition | Appraisal 的确切输入/输出版本、观察与解释；MotivationCandidate 不可变快照、成本估计/期限及接收引用 | 因果边按修订成有向无环依赖，关联边不冒充证据；动机随决定/机会/目标保留，不单建调度聚合。交接幂等，授权与结果归原所有者 |
| 互动机会 / cognition | 原事件锚点、对象/话题、场景、读集、合并成员、有效窗口与被选决定 | 唯一机会 ID；合并保留成员来源，不能同一效果重复消费；短命可仅持久化必要检查点；恢复重新仲裁，删除使成员与派生候选失效 |
| 人格配置 / persona | PersonaProfile 版本、前驱、变更提案/确认摘要、政策版本、来源边 | 每分支当前版本指针唯一，版本不可原地覆写；确认绑定基线与差异；用户编辑与自动候选竞争事务检查；删除影响历史配置内容/投影，不能靠回滚再生 |
| 演化政策 / persona | 认证修改者、允许/锁定字段、频率/幅度预算、漂移和回归版本 | 策略修改不追授旧候选；缺字段或过期则自动提交关闭；审批/同意沿原 Policy 记录，不复制伪授权 |
| 共同符号 / relations | 实体、命名事件、知情者、presented/grounded 证据、适用范围/禁用/最近使用 | 允许争议/多称呼，不全局唯一昵称；共同理解提交必须有送达及采纳来源；回用计数只基于真实送达去重；删除级联别名/索引/候选 |
| 社交反馈/边界/修复 / relations | 反馈者认证归属、被反馈表达范围、对象/主题/场合、证据强度与边界版本 | 来源不明只待解释；禁止多数票覆盖个人拒绝；有效边界与原文分开最小化，原文删除不默默解禁；明确删边界后用保守默认而非恢复被删推断 |
| 人物可靠性 / relations | 人物×领域×情境及有效时间；引用 memory 的原始说法/验证结果及独立来源 | 不另存全局可信事实副本；新领域未知，修订/删除重算局部判断；不能提升来源技术信任或授权 |
| 兴趣/习惯 / persona；活动实例 / agency | 偏好/习惯来源、触发/退出条件、规则版本；Goal/Task/Action/Outcome | 真实活动结果才支持经历；归纳习惯不能用模型自述替代；习惯失效不删除独立承诺，活动取消不虚报完成 |
| 语用框架/表达计划 / expression | 框架前提与范围、片段依赖 DAG、决定/授权/发言权/端点版本、各通道投影 | 禁止依赖环；未发布可重做，已发内容按已发版本关联；框架不能更新事实真假；删除清缓冲/字幕/缓存并标记不可续播 |
| 输出端点 / runtime | 认证绑定/会话/代次、通道、可达性、私密性、受众/路径修订 | 端点变化使旧流出决定无效；未知不自动私密；恢复不复用旧设备状态；不需要保存推测旁听者身份 |
| 资源租约 / agency | tenant/branch/resource、holder task、generation、deadline、允许控制范围 | 同一独占资源最多一有效代次；释放/撤销/超时后旧代次永失效；用户接管优先；租约与动作授权分别核验 |

上表数据政策与 tenant/identity/branch 复合归属沿用第 1、2 节。跨场景引用必须经授权，不能因相同实体别名跨主体串读。所有派生记录必须能追到独立原来源，不能只追到一段模型总结。长期内容遵守 retention；高频帧/音频按热数据策略，不逐帧永久存成自传。

### 3.1 事务与竞争边界

1. 对人格/关系/场景等聚合采用预期版本提交；事件、当前投影、相关候选失效标记与 outbox 在同一事务边界，不能先发布新版本后让旧决定无条件发出。
2. 发言权/资源租约按资源争用范围序列化，核心与实际执行器都检查代次。数据库锁不能单独阻止已在设备缓冲中的动作，故本地接管/取消必须配合，实际停止位置回报。
3. 表达提交与外部播放不能构成分布式原子事务。先验证释放，适配器执行前/每个可控片段再验证有效取消代次；撤权发生时禁止续发，已播内容按事实留痕。不得声称可瞬间撤回已发生效果。
4. 学习/索引/恢复任务必须携带来源和删除 epoch；最终提交复查，删除优先阻止旧任务写回。删除完成的范围包含在途生成缓存与端点缓存的清理确认；无法同步清理的端点隔离，不虚报全部完成。
5. 每个回执有去重关联；重复片段回执不增加梗使用/学习证据次数。迟到回执仍用于实际效果核验，不能为当时未授权的动作补同意。
6. cognition 验证评价/需要转换及贡献去重；应用 StateStore 以预期版本协调评价依据、需要新版本、相关候选失效、事件及 outbox 的原子提交。模型生成在事务外；提交失败不使用未成立状态，状态提交后行为生成失败不回滚该状态。再次提交/释放重验 read_set；无语义变化的检查不改需要版本。不让领域模块直接访问数据库。
7. 来源修订/撤回、人格编辑、定义停用、撤权与迟到反馈竞争时，受影响的当前依据版本/屏障先阻断旧投影使用，重算可有界异步完成。当前有效性不能仅依靠已存 active 标签或后台失效任务；读取和释放均验证必要依赖。无关状态不全局取消；迟到结果不能追授权限或复活已删数据。
8. 同一关切并发创建以作用域及归并依据检查唯一性；同目的动机交接的接收记录、目标引用和必要 outbox 同事务，崩溃重试返回原接收结果。机会升级为持续目标需记录承接，不能留下两个活跃执行入口。多需要对应同一候选只占用一次执行预算。
9. 来源贡献与普通目标关联分开，均保留删除关联但只有贡献参与支持计算。承诺中的历史动机不是每一步的当前前置条件；任务实际读集遵循[状态契约](../05-STATE-CONTRACTS.md)。删除历史动机仍清理其内容及派生；独立承诺只有经无污染来源重建后才继续。


## 4. 初始化与恢复

交互实例的配置提交使用预期修订；配置/启用状态、绑定与端点失效屏障、操作 outbox 协调提交，网络连接不置于数据库事务中。先记录将应用的配置和新连接代次，再发出幂等操作；迟到结果核对安装、实例、代次与操作关联。相同契约的提供者不能按加载顺序选择，绑定固定 provider 与实例资源。runtime 仍独占 OutputEndpoint/DeliveryReceipt/Turn 的领域提交，管理器只管理配置、认证及连接事实投影。

删除实例先撤销业务与管理绑定、终止认证/在途操作、使端点不可用，再按数据政策清理配置、凭据和挑战缓存；不自动抹除具有独立保留依据的合法历史。删除输入仍沿 lineage 清理记忆等派生内容。卸载和恢复不得重新启用已删实例或复活凭据；不将连接配置复制进身份分叉。恢复时历史 connected/ready 仅是旧观察，重新核验包、配置、授权和凭据并分配新代次后才可接入；不重放认证提交、发送或其他外部效果。工具使用通用调用/绑定持久化，不依赖这些交互实例记录。

1. 从空库创建首版键、约束、隔离策略和索引；配置样例作为初始化候选，不代表用户已同意人格自动演化或启用能力。
2. 建立身份和授权边界后再接纳事件；初始来源、共同理解、送达和活动状态未知时明确记录未知，不从文学或示例补造事实。
3. 快照恢复先加载撤销与删除屏障，再恢复合法数据及投影；已删除内容不能从备份、索引或后台任务重新生成。
4. 恢复后重新认证端点、核对私密性、授权与覆盖有效期，重新取得租约；未确定的外部动作先核验实际效果，不自动重做。
5. 跨设备搬迁保留 identity_id、谱系、合法历史和检查点；先停止原写入者或交接独占权，禁止同一分支无控制双写。分叉显式获得独立 branch_id。
6. 回放只恢复状态，不重复外部副作用，不补演停机期间的社交活动。
7. NeedState 恢复须重验定义/校准配置、人格、来源、场景和数据用途；过期、放弃和未能重验均不视为已解决。恢复调度基点，不补算离线显著性变化或批量补发请求。新分支只继承明确授权、快照有效且未被删除的需要，后续写入和时间窗口归属各分支；关联承诺由 agency 独立核验。
8. 活跃需要、来源边、检查和候选数受资源/保留政策约束；配额不足拒绝接纳或沿现有有界任务延后，不创建无限补算队列。初始化可从空需要集评价合法事件与当前场景；未评估或不可访问不伪装成空事实。

## 5. 验证责任

存储验收覆盖：空库初始化、复合 FK/唯一约束/RLS、事务失败与崩溃、并发写入、撤权与删除竞争、派生清理、备份恢复、分支及跨设备交接、幂等和外部效果核验。

需要机制另覆盖：同事件并发投递只形成一次贡献；来源修订替换旧贡献；评价与需要不能自我强化；时间区间重叠/回退；人格编辑与候选释放竞争；派生需要/评价/动机删除与离线恢复。以上是逻辑约束和待实施测试，本轮不新增 SQL 或数据库运行结果。

SQLx 查询检查不能代替真实 PostgreSQL 验证。实际执行结果见[验证记录](../06-VALIDATION.md#当前验证记录)。
