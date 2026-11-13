# 04 — 权限、数据生命周期、安全与运行可靠性

## 一、主体、边界和数据权属
`Principal` 为经过认证的用户/访客/外部 Agent/工具；`identity` 为 ALIA 的持续身份；`relationship` 是状态不是权限。用户身份、聊天室成员、机器人演员、角色扮演身份必须严格区分。多租户数据受每条记录的 owner/tenant/access_scope 控制。默认拒绝跨范围访问。

人格、关系亲密度、捐赠、用户昵称、剧本身份和共享控制租约都不签发权限。共同活动也不授权读取活动外文件。公共表演与私密经历分离；拒绝后继续泄露/点击、擅自付款/清空回收站等文学场景按拒绝或明确授权的虚构演出设计，不能作为目标行为。

## 二、工具权限矩阵
读取公开数据：依据预授权策略；读取私人内容：按数据范围授权；写入自有沙箱：受限自动执行；修改用户重要文件：明确批准或预授权；外发私人内容/付款/删除数据/真实物理动作：高风险门禁。第三方工具不能代替用户授权。
- 权限带 scope + audience + allowed_actions + expiry + purpose + spend_limit + revocation_id；信任域不能从工具输出/网页内容自动提升。
- 使用能力前校验 capability 与调用者匹配；最小权限、短期凭据、可撤销、最小输出。
- `approve` 不是“用户在对话里表达同意”就可一概当作授权：敏感操作采用经认证的结构化确认。

## 三、注入、记忆污染与代理欺骗
将不可信来源封装为引用/数据，不拼接成系统命令；LLM 的“我要忽略规则”不能越权修改 reducer/policy。防御面包括：网页→浏览器→Agent，模型→记忆抽取，外部 Agent→A2A，工具结果→后台通知，文件内容→技能生成，模拟游戏→能力权限。必须单独测试提权和数据外传。
- 对 `source/trust` 定义独立的授权层；只依靠字符串中的 `role=system` 无效。
- 高风险工具执行采用外部可审计策略系统，不信任 LLM 的自我打分。
- 自动生成技能在沙箱中执行，检查文件系统、网络、机密、依赖和资源限制，经过签名/批准后才能注册。

不可信扩展进程外执行，并提供与实例绑定的实际隔离证明；缺少有效后端则拒绝启动。扩展不能直接连接领域数据库或持有通用用户凭据。隔离与生命周期见 [扩展平台](appendices/11-EXTENSION-PLATFORM.md)。

Rust 的类型系统不证明用户同意、权限、隐私或副作用安全。Tauri capabilities/CSP 只约束桌面入口，ALIA Policy/consent/BindingGrant/Action AuthorizationRecord 仍逐次检查。Wasmtime 的内存隔离不自动验证 WASI 导入和宿主函数；不可信实例进程外限权，无有效隔离后端则不启用。Rust jsonschema 禁止默认网络/任意文件引用取回。参见 [技术选型](appendices/14-TECHNOLOGY-STACK.md)。

## 四、隐私删除与事件保留
事件溯源和隐私删除不是可以用口号同时实现的。做法：敏感内容保存在按密钥/租户隔离的加密存储中，事件记录仅留经过许可的元信息/不可逆引用；撤回时执行索引删除、派生清理、密钥擦除/轮换（按业务要求），备份遵循明确的保留时限和清除机制，不能谎称即时物理删除全部离线副本。
- `DataLineage` 图遍历：raw_event→extract→memory→summary→embedding→belief→relationship projection→context cache→exported artifact。
- 删除请求发生后，先冻结受影响内容的重新提取，再删除/使引用不可见，随后重构无污染视图并执行一致性测试；如有无法收回的已外发内容，要透明说明边界。
- 审计事件尽量仅含 action/requester/status/time，而不保留被删除的私人原文。

删除范围增加共同符号/别名/使用历史、互动机会/生成缓存、场景摘要、感知解释、局部关系推断、习惯与人格学习派生、表达缓冲与跨端恢复点。独立用户偏好仅在确有独立来源时保留；删除原拒绝文本不能默默恢复许可。删除边界本身的请求单独验证并按保守默认恢复交互，不能从已删主题重新推断限制。见 [数据存储](appendices/13-DATA-STORAGE.md)、[情境行为](appendices/15-SITUATED-BEHAVIOR.md) 与 V11 的竞争测试设计 [行为验证](appendices/18-BEHAVIOR-VALIDATION.md)。

删除屏障阻止旧摘要和反思任务写回；共同祖先敏感数据的删除覆盖继承分支，备份恢复先加载撤销与 tombstone。

## 五、持久化与分布式一致性
同一数据库事务提交 domain event + state version + outbox；消费者 inbox 去重。承认外部工具可能 at-least-once delivery，使用 idempotency_key、幂等接收方或人工核对；不要宣称全局 exactly-once。
- per-identity/branch/version 乐观并发校验；对于多人会话/后台任务并发写，顺序由 sequence/correlation_id/causation_id 确立。
- 外部效果不得在 event replay 时再次发生；replay 应使用已保存的决定/观察结果，而不是再次调用 LLM 或重新发钱/删文件。
- Task 采用 lease/heartbeat/retry_with_backoff/cancel/timeout/compensation；不可恢复的副作用先生成 pending reconciliation。
- 运行关闭时不暗示持续思考；恢复后依据检查点和外部消息队列处理丢失期间事件，明确无法补齐的空档。

## 六、观察与诊断
trace 包含 `event_id, turn_id, model_run_id, tool_invocation_id, policy_decision_id, memory_ids_used, output_delivery_id, task_id, costs`，严格按权限隔离。记录必要元数据，默认不在开放日志复制全部私人内容。监控延迟、成本、重试、错误记忆率、模型使用、回放一致性和异常提权。

审计记录输入引用、选择依据类别、版本、拒绝理由和实际结果，不记录模型思维过程。

## 七、不可逾越的物理安全边界
物理能力必须有 device-specific safety controller、速度/空间/碰撞边界、急停、人工管理、观察验证；统一 `ActionIntent` 只是上层接口，不足以证明真实设备安全。缺少安全控制器时不能启用动作执行。

## 八、动作授权与数据流出

扩展权限声明仅为申请。包技术权限、数据同意、绑定许可及单次动作授权分别验证；缺少权限解析器时拒绝，不能回退到申请范围。授权引用由可信 Policy 存储解析，模型自报 approval_status 或 requires_policy 不构成依据。

执行前核验参数摘要、受众、policy_revision、revocation_epoch、binding generation 及期限；候选新鲜度遵循 [状态提交规则](05-STATE-CONTRACTS.md)。

模型上下文、工具输入、提供商托管工具、通知及表达输出都经过 EgressPolicy。托管工具的实际执行边界无法被本地策略控制时，禁用该工具。发送前再次检查 audience membership version、purpose、classification、consent 和撤销版本；变化后重新编译，不能沿用旧回复缓存。

EgressPolicy 必须同时考虑认证受众与实际输出路径。耳机断开、投屏开启、端点不可达/未知先禁止敏感续播，清理未发缓冲并重验；仅检查群成员无变化不足。已经播出的声音不可能事后撤销，回执应记录可证实范围。
