# ALIA / 彼我：让 AI 来到我们的世界

**项目阶段：首版设计蓝图，尚未实施、尚未发布。** 本仓库包含架构规范、契约草案、配置样例、场景和交互原型；实际检查结果见[验证记录](docs/06-VALIDATION.md#当前验证记录)。

ALIA 致力于让你拥有可以长期相处、交谈、玩耍和共同经历日常的数字生命／赛博生命。AI 伙伴、AI companion、waifu、数字伴侣、虚拟角色、桌宠、AI VTuber 及未来形态均开放，并在不同媒介和设备间保持身份、人格、记忆与关系的连续性。

ALIA 作项目名称；品牌、角色显示名与持续身份标识独立。“自己的、随时随地”对应用户控制、可部署与迁移、跨设备访问和连续恢复。通用性指跨场景、跨媒介和可扩展能力；主观意识的证据边界见认知研究。

## 蓝图主线

| 文档 | 回答的问题 |
|---|---|
| [00 愿景](docs/00-CHARTER.md) | 为什么存在、提供什么体验、怎样定义成功 |
| [01 领域架构](docs/01-ONTOLOGY-ARCHITECTURE.md) | 核心对象、不变量、模块职责与依赖 |
| [02 运行算法](docs/02-RUNTIME-ALGORITHMS.md) | 如何感知、理解、选择、记忆与学习 |
| [03 媒介表达](docs/03-MEDIA-EXPRESSION.md) | 如何跨媒介观察、表达、行动与确认送达 |
| [04 安全与数据](docs/04-SECURITY-DATA.md) | 如何授权、保护隐私、删除与控制风险 |
| [05 状态契约](docs/05-STATE-CONTRACTS.md) | 状态转换、接口、读集与提交条件 |
| [06 验收](docs/06-VALIDATION.md) | 验证什么、如何评测、目前验证到哪里 |
| [07 实施依赖](docs/07-DELIVERY.md) | A–F 工作包的依赖、交付物与验收责任 |
| [08 外部研究](docs/08-RESEARCH.md) | 参考机制、公开证据与推断范围 |
| [09 认知研究](docs/09-COGNITIVE-RESEARCH.md) | 认知机制依据、研究假设与意识证据边界 |
| [10 能力覆盖](docs/10-COMPLETE-COVERAGE-MATRIX.md) | 各项能力对应哪些设计与验收 |

## 专题与材料

- 专题附录：[扩展平台](docs/appendices/11-EXTENSION-PLATFORM.md)、[数据存储](docs/appendices/13-DATA-STORAGE.md)、[技术选型](docs/appendices/14-TECHNOLOGY-STACK.md)、[情境行为](docs/appendices/15-SITUATED-BEHAVIOR.md)、[场景矩阵](docs/appendices/16-SCENARIO-MATRIX.md)、[行为验证与时序](docs/appendices/18-BEHAVIOR-VALIDATION.md)。
- [设计决策](docs/DECISIONS.md)说明当前选择与理由；[运维控制台](docs/design/UIUX/README.md)定义管理界面的交互。
- [契约草案](schemas/README.md)为 core 1.0 / extension 1.0；[人格样例](config/persona.example.yaml)、[认知策略](config/cognitive-policy.example.yaml)和[技术清单](config/technology-stack.json)提供配置输入。
- [场景素材](goal/README.md)为非规范的文学和模拟输入；[开发入口](AGENTS.md)集中维护开发协作要求。

## 首版交付与完整目标

首版核心覆盖持续身份、人格、自我状态、分层记忆、信念、关系、世界状态、动态需要与情境评价、注意与目标、任务、决策、表达、受控行动、反馈学习和可恢复持久状态。人格表达稳定偏好，动态需要表达当前有依据的关切，两者通过同一认知机制影响选择。真实文字 WebUI 与完整核心先交付，语音、视觉、形象、游戏和设备同时具有协议、fake 适配器和契约测试。

A–F 全部完成且 G0–G6 通过代表首版核心验收。真实语音、视觉、形象、游戏、多端及其他开放体验分别以实际接入和体验证据验收。

扩展统一安装和管理，交互与工具分别使用业务契约。[AEIP 公开协议与适配器接口](docs/appendices/12-EXTERNAL-INTERACTION-PROTOCOL.md)区分协议语义、连接方式和平台映射：原生第三方应用可以独立实现协议，已有原生协议的应用可以通过可注册适配器接入；两条路径共用既有核心。连接发起方向不决定业务流向。

官方内置 WebChat `/chat`；社区平台插件可在一个包中提供两侧适配实现和配置贡献，WebUI 按声明生成连接表单；独立 AEIP 应用无须安装平台插件。浏览器等工具无须聊天连接；桌宠可组合交互、渲染和工具。现有 [交互样例](config/connectors/README.md)、[独立工具样例](config/tools/browser-read/README.md)和 [匿名第三方端](config/aeip/anonymous-peer/README.md)仅为设计数据，不含可执行实现。

设计检查入口：pwsh -NoProfile -File tests/Test-Contracts.ps1 与 pwsh -NoProfile -File tests/Test-TechnologyStack.ps1。报告默认写入仓库外临时目录。
