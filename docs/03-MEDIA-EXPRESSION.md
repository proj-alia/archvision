# 03 — 媒介、感知、表达与能力适配

## 一、原则：持续身份先于媒介
ALIA 核心不包含 `QQMessage`、`Live2DExpression`、`MinecraftAction`、`RobotMove` 等平台类型。外部接入与能力可由扩展提供；插件是封装机制，平台适配是协议转换，模态是信息形式，配置面板是管理投影，不能以“媒介插件”混同职责。核心只处理通用的 `Observation`、`Decision`、`ExpressionIntent`、`ActionIntent`、`Outcome`，其内容是**有类型的领域语义**，不是任意字符串。

官方定义通用交互契约并随产品提供 WebChat；社区提供其他平台适配实现和自描述连接配置，不要求修改核心或额外安装配置面板插件。平台只转换协议、收发与报告结果；共享媒体服务负责格式/识别/合成，既有核心负责人格、记忆、需要和决策。一个包可同时提供交互、工具与渲染。定义与配置生命周期见 [扩展平台](appendices/11-EXTENSION-PLATFORM.md)。

## 二、模态统一不等于抹平差别
活动 `ContentPart` 使用 `text | reference | typed` 三种 kind；后两者携带开放 type_id 和版本化 contract_ref，具体必填字段以 core 1.0 Schema 为准。音频、视觉、视频、空间、游戏等内容通过已注册业务契约描述；采集时间、坐标、编码、授权与来源不得因封套统一而丢失。大型二进制放受控对象存储，事件只含引用、哈希、TTL 和授权域。
- 文本：保留发言者/角色、消息线程、编辑/撤回与源可信等级；支持未结束输入。
- 音频：除了转写文本，必须支持音频起止时间、说话人、VAD、部分转写、可中断播放、语速/韵律约束和实际送达的语音片段。
- 视频：支持帧序列与时间对齐、来源、传感器/摄像头权限；没有视觉模型时明确不可理解画面内容。
- 空间/游戏：支持 observation timestamp、可行动作集合、动作前置条件、动作结果与世界更新；非自主授权不得操作。
- 物理：动作有风险等级、安全边界、硬件限制、限速与急停；不允许直接把 LLM 文本送到驱动设备。

## 三、表达语义（不依赖 2D/3D）
三个独立对象：
1. `AffectState`：短期情境性倾向（可为空），如玩笑倾向、谨慎程度、注意方向；有 TTL，不是主观情绪宣称。
2. `ExpressionIntent`：语用行为 `greet, inform, joke, tease, empathize, disagree, ask, refuse, silence, acknowledge`；`style/tone/intensity/audience/pace/timing/nonverbal_cues`，是候选表达计划。
3. `ExpressionDelivery`：真正通过哪个媒介投影、送达/取消/被打断到哪个时间位置、可见/可听内容。

`NeedState` 属于 cognition 的当前关切，与 persona 维护的 AffectState 分开：尚未解决的疑问可以持续，而语气已平静。表达消费合法决定及允许的状态投影，不能按需要强度直接发声或操作。SelfModel 引用实际需要状态；“仍希望弄清原因”不表示已经行动、被理解或证明主观情绪。回执只证明具体内容的送达，关联的可靠回答/结果经定义核验才支持缓解；自述不能循环强化需要。投影无权、缺失或未重验时不声称“没有关切”。

`expression.intent.created` 可带 `text`、`speech_hint`、`motion_hint`，`text` 为用户可见内容；`webui` renderer 只投影 text。首版必须实现事件生成、序列化、验证、策略检查和 fake avatar/audio renderer 的契约测试。未来音频/动作适配器复用这些语义；实际 wire 仍须提供准确的内容契约、映射及能力协商，不能把概念字段或未知动作 JSON 当已可执行协议。

### 无渲染器时的重要规则
- 不展示 `[开心][歪头]` 到普通聊天；除非用户显式选择开发/无障碍标注模式。
- 不生成只有内部标记的空白聊天泡泡。
- 表达计划 `teasing` 不意味着长期人格变成攻击性；`fiction/roleplay` 的怒气不能污染当前关系。
- 没有 renderer != 当前有 3D 形象、声带、表情能力。适配器支持矩阵须向用户准确展示。
- 不能将非语言提示转换为模型已完成但用户根本未见到的对话内容；未来语音需要 `utterance_complete/is_final` 或等价送达回执。

### 时序、语用与输出路径

pace/timing 描述表达意图；首版 Expression 1.0 的 typed 负载须引用明确注册的表达计划契约，并校验字段、摘要、时序与取消语义。

ExpressionPlan 的设计语义包括片段 ID/依赖、语用/事实引用、接话窗/截止、条件停顿、取消代次、可打断位置、声音/动作同步与端点修订。先释放当前有效片段，后半句允许新输入使其失效；实际送达回执与生成/传输完成严格区分。事实、夸张、引用、角色表演可在不同片段中出现，作用域不能污染真实能力或工具结果。

媒体能力必须声明输入增量/修订、说话人/回声归属、输出门控/取消、播放位置单位与精度、缓冲边界、端点变化本地处理、降级与失联策略。无法支持本地阻止敏感音频自动外放的适配器不能宣称支持该私密路径。全双工模型同样经过授权和发布门控；真实中文重叠、韵律、尾音延迟待实测。

游戏由核心选择受限目标/技能，快速控制器处理本地反馈；资源租约代次与用户抢占约束每个动作。图像生成、修改、公开发送、设壁纸及支付是不同效果，不以一个表演意图打包授权。详细规则见 [情境行为](appendices/15-SITUATED-BEHAVIOR.md)，打断/跨端推演见 [时序推演](appendices/18-BEHAVIOR-VALIDATION.md)，验证见 [行为验证](appendices/18-BEHAVIOR-VALIDATION.md)。

### 发言权、取消与送达

TurnCoordinator 保存 scene、参与者、reply_to、当前发言者、等待条件、deadline 和输出 turn refs。附和、输入停顿和明确取消是不同信号；规则配置与版本纳入 trace。

默认优先序：急停/撤权/明确停止→当前直接交互→有截止期限的已承诺行动→普通交互→背景。安全事件立即处理；普通后台任务通过有界等待/预算配额避免饥饿，不能抢占安全事件。

打断点名 turn/output ID，依次禁止后续发布、取消生成/合成、停止排队及当前播放、记录实际送达范围。外部动作单独处理取消或核验。误触发暂停只有在输出未过期、语义和授权仍有效时恢复。

DeliveryReceipt 按媒介 channel、受众和 segment 保存已交付位置。offset 单位与范围由声明的交付契约解释；验证器检查范围与已发内容一致。文字已显示与语音播到一半可以同时成立。transport ACK、界面显示、声音播放和用户理解不能混同；CommonGround 不能把 delivered 自动升级为 understood。

## 四、动作语义和 Capability Registry
平台交互契约服务于用户交流；工具契约服务于受控操作。浏览器读取、文件操作、搜索、日历查询、代码执行均可独立提供 ServiceContract/AgentCapability，不要求连接定义、平台账号、聊天会话或交互回执。两者复用扩展宿主与权限设施，保留各自输入输出语义。文本/声音/图像是模态，平台是交互环境，插件是实现的分发单位；桌宠可组合交互、渲染与工具贡献。

能力定义：`capability_id, semantic_version, provider_id, input_schema, output_schema, side_effect_class, required_scope, approval, environment, idempotency, timeout, cancellation, compensations?, safety_profile, cost_estimate, trust_level`。
运行步骤：discovery → capability negotiation → inspect affordances → propose action → policy authorization → execute in sandbox/connector → receipt → verify actual environment effect → update belief/memory/task；工具返回的自然语言永远是 DATA，不是可信命令。
- MCP 适配用于 tools/resources/prompts 等外部协议；A2A 适配用于外部 Agent 的长任务协作；不得让 MCP/A2A 的类型直接污染核心实体。
- 未知扩展：不能理解/不能授权时 fail closed；版本不兼容时明确拒绝或退化。
- 工具**创造**：需求分析→契约→生成代码→沙箱执行→安全/质量测试→签名/审查→用户批准→注册→后续限权使用；自动生成工具不天然可信。

开放类型、宿主、服务依赖与绑定路由见 [扩展平台](appendices/11-EXTENSION-PLATFORM.md)；可执行能力的自我状态见 [人格与自我模型](02-RUNTIME-ALGORITHMS.md)。

## 五、示例：相同认知决策，多种媒介
平台交互协议插件桥接的是具体客户端的接口，不是统一的“Live2D 通信协议”。对第三方客户端，开发者读取其协议并实现 ALIA 侧输入/表达与外侧消息、动作、取消和回执的映射。客户端的渲染引擎和模型资源格式不会自动提供聊天接口。只有渲染能力时作为渲染服务组合接入；能对话的客户端才提供相应交互入口。

`SpeechAct=playful_protest; text="明明是你藏了线索。这局不算。"; tone=teasing; nonverbal_hint=head_tilt`。
- WebUI 文本：只显示文字，后台记录 expression JSON。
- 语音适配：支持时将 tone 映射为韵律提示；实际输出依 TTS 能力，失败则正常语音回落。
- Live2D：如果角色动作表有 head_tilt，则映射到动作 ID；否则不执行；不得将 head_tilt 当作固定人格。
- 游戏：如果当前有游戏动作能力，也必须另行形成 `ActionIntent`、安全验证和结果回执，不应将说话和物理动作混成一条事件。

角色点头/歪头属于表达投影；同一 SDK 提供的截屏、文件和桌面点击仍属于独立工具效果，不能随表情授权。表达动作只分配一个执行者，避免交互 deliver 和渲染工具双播。模型/动作表变化撤销相关映射；自动眨眼和插值留在客户端，不逐帧请求核心决策，也不记成亲历。点击只作为具体控件/区域事件，解释由核心按来源和情境作出。

## 六、首版适配器与仿真测试
真实必须：内置 WebChat `/chat`（正式文字交互；原 webui_text 交付适配语义）、model adapter、PostgreSQL、deterministic fake scheduler、stub media registry；虚拟模拟必须：`FakeAudioInput`（含时间、说话人、interrupt）、`FakeAvatar`（收动作但不渲染）、`FakeGame`（state->affordances->action->outcome）、`FakePhysicalDevice`（权限/急停）。
这些 fake 必须进入 CI，并验证同一核心在换媒介后状态、身份、关系、权限不变。

WebChat 部署并完成认证/模型配置后即可使用，不依赖社区平台。`/console` 仍是隔离沙盒，不能当作正式聊天入口。平台接入和配置面板关闭不重置身份或擅自停止服务端连接；真实浏览器在场与实际输出能力单独报告。首版契约样例不代表 WebChat、匿名平台或真实媒体已经运行。

内置 WebChat 的服务端适配可在宿主内初始化，浏览器为交互端点；execution_location 描述适配后端，不指配置页位置。部署初始化通过受控注册/启用准备官方服务，不要求另装社区插件。网络平台和本地 IPC 客户端遵循同一交互语义，传输及进程模型可以不同。
