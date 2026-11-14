# 首版契约草案

状态：draft，尚未发布或部署。唯一设计基线为 core 1.0 / extension 1.0 / AEIP 1.0，各自承担不同边界。

| 目录 | 对象 |
|---|---|
| core/ | event、decision、action、capability、expression、memory、authorization、delivery |
| extension/ | manifest、contract、session、binding、message、control、grant；connector-definition、connector-instance、setup-session |
| aeip/ | 独立客户端 message 封套及可注册 adapter 声明；不要求包 manifest |
| services/ | connector-management、connector-setup、interaction；公开 peer-interaction、peer-observation、peer-actions 标准业务服务（*.contract.json） |

[catalog.json](catalog.json) 是草案目录，不是已实现的网关。Schema 使用 JSON Schema 2020-12，自包含局部引用；不设置旧协议、隔离旧稿导入、别名或校验回退。identity_id 是持续身份，internal_agent 是事件来源类别且不证明信任或授权。

## 验证责任

1. Schema 检查形状、必填、枚举、组合、版本和格式。
2. 契约注册验证大小、深度、引用及准确业务 payload；未知契约不得参与活动决策。
3. 领域验证关联、read_set、状态转换、期限、受众、授权真实性及撤销和删除屏障。
4. 数据库存储验证复合归属、约束、事务和隔离，见 [数据设计](../docs/appendices/13-DATA-STORAGE.md)。

服务契约 schema_digest 是分发 JSON 文件原始 UTF-8 字节的 SHA-256；ActionDigest 是完整 ActionProposal 的 RFC 8785 JCS + SHA-256。两者用途与字节定义不同。示例只核验固定样本，不实现通用 JCS 或授权服务。

仓库以 .gitattributes 固定 JSON 的 LF 换行，分发使用 UTF-8 无 BOM；校验仍对实际字节求摘要，不在验证时转换字节。AEIP description 使用 base64 携带准确分发字节，二次验证 ServiceContract、摘要与本地引用限制。公开消息 payload 还须按绑定成员二次验证；形状无法证明方向、归属、能力修订、权限或效果。

[公开协议](../docs/appendices/12-EXTERNAL-INTERACTION-PROTOCOL.md)分别定义 WS 两种连接方向、HTTP/SSE、业务角色、恢复与版本策略。alia.peer.interaction 为外部受限投影，网关注入内部实例和作用域；alia.peer.observation 不要求聊天会话；alia.peer.actions.request 只形成受控动作候选。公开 payload 与内部 alia.interaction 不混用。匿名 Q/Q7 资产见 [样例](../config/aeip/anonymous-peer/README.md)，没有运行 SDK、认证、翻译器或模拟客户端。

manifest 格式、包版本、业务契约版本与协议版本具有独立语义。人格和认知策略是配置样例，不伪称已发布配置协议。草案修订直接同步示例和检查；真实发布后的演进依据实际消费者设计。

catalog.entries 登记格式 Schema 1.0，service_contracts 独立登记业务 SemVer 1.0.0、路径和原始字节摘要。连接贡献引用带摘要的包内 descriptor；连接定义引用服务，配置/认证样例引用定义，形成可核验关联。binding_request/BindingGrant 的 provider_ref 与 resource_ref 限定具体提供者和 connector.instance，Binding 固定同一资源；形状校验不证明引用归属、步骤新鲜度或授权真实性。

ConnectorDefinition/ConnectorInstance/SetupSession 和三个 `alia.connector.*` / `alia.interaction` 标准服务仅适用于平台交互贡献；工具、模型与媒体服务不必实现它们。工具复用 ServiceContract 与 core AgentCapability，见 [浏览器工具](../config/tools/browser-read/README.md)和 tests/contracts/tool-cases.json；包自己的业务契约不成为核心平台枚举。manifest 的开放贡献可组合，不能以同一安装单位推断必须共用交互协议。

configuration_schema 与 SetupSession.step.input_schema 是待元验证的嵌入 Schema；普通配置和步骤输入必须再按它们验证。配置声明的显示提示不运行代码，密钥单独管理。ConnectorInstance 是内部持久快照，UI 只获得脱敏投影，不直接返回 credential_refs 或全部敏感配置。标准交互 input 仍是来源数据，宿主派生 core Event 的 actor/scope/sequence；receipt 复用原 core DeliveryReceipt。

required_features 及 connection_dependents 只声明最小能力和同连接贡献依赖；子集、贡献存在/单一所有者及关联绑定由宿主校验，不由 Schema 自证。依赖连接的自定义服务也须绑定 connector.instance，不能仅对三个标准 ID 做资源检查。degraded 与 ready 均需合法基础连接条件。panel.allowed_operations 指向受限应用命令，不能直接指定 provider bridge_contract 或方法绕过 ConnectorManager。

四个 [自描述接入样例](../config/connectors/README.md)及 tests/contracts/connector-cases.json 用于设计检查。角色客户端 C 的外侧 peer.schema.json 是合成协议夹具，不加入 ALIA 标准服务目录；bridge-cases 仅验证两侧固定样例，不证明翻译器运行。服务成员的 input_schema/output_schema/payload_schema 分别作为独立根解析；不把其中的局部 `$ref` 错误解析到 ServiceContract 外壳。开放服务仍按契约逐次校验，未知业务不通过平台名称分支。

运行 pwsh -NoProfile -File tests/Test-Contracts.ps1。报告默认保存在仓库外临时目录；它验证结构，不证明宿主、授权、生命周期、数据库或真实媒体行为。
