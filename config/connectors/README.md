# 通用交互与自描述连接样例

这些是首版设计数据，不含可执行适配器、真实认证、凭据或平台连接。`example:` 入口/二维码及其摘要是合成占位，不能安装或运行；manifest.descriptor_ref 和业务 contract_ref 的摘要则对应本仓库实际 JSON 文件字节。没有真实运行或 UI 验收。

| 示例包 | 连接定义 / 样例实例 | 用途 |
|---|---|---|
| [内置 WebChat](webchat/manifest.json) | [定义](webchat/connector.json)、[实例](webchat/instance.json) | 官方随产品交付的宿主内服务端适配；浏览器为 `/chat` 端点，不强制启动外部插件进程 |
| [匿名接入 A](anonymous-form/manifest.json) | [定义](anonymous-form/connector.json)、[实例](anonymous-form/instance.json) | 服务地址/账号标签自动表单，独立 token 凭据槽，无自定义前端 |
| [匿名接入 B](anonymous-setup/manifest.json) | [定义](anonymous-setup/connector.json)、[实例](anonymous-setup/instance.json)、[认证快照](anonymous-setup/setup.json) | 自动表单加通用二维码步骤；已加载管理服务可在账号未连接时认证 |
| [匿名角色客户端 C](anonymous-avatar/README.md) | [定义](anonymous-avatar/connector.json)、[实例](anonymous-avatar/instance.json)、外侧 C7 合成协议 | 展示 ALIA 不预知外侧协议的双向桥接；可选动作能力与共享连接表达贡献分别声明 |

这些契约仅用于平台交互。连接可为网络、本地 IPC 或宿主内接入；配置页的位置不决定适配器执行位置。对照见 [独立浏览器工具](../tools/browser-read/README.md)：工具具有自己的服务契约和能力投影，无须聊天连接。同一包可组合两类贡献，但不得混用业务输入输出。

匿名 A 的 [第二实例](anonymous-form/instance-2.json)使用同一安装和定义、独立实例 ID 与账号配置；两个样例都没有真实凭据或已运行连接。多账号隔离仍需未来实际验证。

实例初始为 disabled/disconnected/unavailable；WebChat 的 not_required 仅表示没有外部平台凭据槽，不豁免 WebUI 用户认证。B 的认证快照是独立的“管理服务已启用、流程进行中”夹具，并非已执行 instance.json 到 setup.json 的转换。`https://*.invalid` 不连接外部平台。

上述 disabled 是未运行的样例快照，不要求产品用户另行安装或手动启用 WebChat 插件。正式部署的初始化流程应在用户完成必要配置后，通过相同的宿主检查启用内置服务；浏览器在线与聊天权限再决定端点可用性。

一个包提供 manifest、connector.json 和未来适配实现即可声明连接类型；普通配置 UI 由宿主生成，不需另装“客户端插件”。特殊配置面板通过 ConnectorDefinition.panel 引用包内资源和 allowed_operations 应用操作白名单；不能直调适配器服务方法。本组样例无需自定义面板代码。基础状态/断开操作由宿主提供，不依赖特殊面板。

## 契约关联与验证

四个包共同引用 [管理服务](../../schemas/services/connector-management.contract.json) 与 [交互服务](../../schemas/services/interaction.contract.json)；B 另引用 [认证服务](../../schemas/services/connector-setup.contract.json)。多个提供者可实现同一契约，宿主按安装、实例和准确提供者绑定，不能按 contract_id 随机挑选。契约版本/摘要与包版本独立。

配置先按 ConnectorDefinition.configuration_schema 在服务端验证，再执行获准的 validate/test/connect；密钥只通过声明的槽写入 CredentialStore。ui_hints 的 path 指向普通配置属性，不改变验证规则。每个实例独立保存配置、凭据引用与修订；连接切换/重连生成新 connection_generation，旧输出/认证回调拒绝。

服务中的 input/output_schema、payload_schema 各是独立 JSON Schema 根。input 的 content_parts 与 core Event 相同；receipt 包含原 core DeliveryReceipt，避免两套交付状态。定义中的配置 Schema 和认证步骤中的输入 Schema还需元验证、资源限制及运行时二次校验；服务外壳通过不意味着内嵌数据合法。

静态检查入口为 `pwsh -NoProfile -File tests/Test-Contracts.ps1`，覆盖实例/定义/认证形状、配置正反例、业务输入输出及摘要关联；[场景](../../tests/scenarios.yaml)中的 connector_* 与 webchat_* 是未来运行验收。连接、浏览器表单、真实二维码和发送结果不能由这些 JSON 样例证明。
