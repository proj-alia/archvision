# 首版契约草案

状态：draft，尚未发布或部署。唯一设计版本为 core 1.0 / extension 1.0。

| 目录 | 对象 |
|---|---|
| core/ | event、decision、action、capability、expression、memory、authorization、delivery |
| extension/ | manifest、contract、session、binding、message、control、grant |

[catalog.json](catalog.json) 是草案目录，不是已实现的网关。Schema 使用 JSON Schema 2020-12，自包含局部引用；不设置旧协议、隔离旧稿导入、别名或校验回退。identity_id 是持续身份，internal_agent 是事件来源类别且不证明信任或授权。

## 验证责任

1. Schema 检查形状、必填、枚举、组合、版本和格式。
2. 契约注册验证大小、深度、引用及准确业务 payload；未知契约不得参与活动决策。
3. 领域验证关联、read_set、状态转换、期限、受众、授权真实性及撤销和删除屏障。
4. 数据库存储验证复合归属、约束、事务和隔离，见 [数据设计](../docs/appendices/13-DATA-STORAGE.md)。

服务契约 schema_digest 是分发 JSON 文件原始 UTF-8 字节的 SHA-256；ActionDigest 是完整 ActionProposal 的 RFC 8785 JCS + SHA-256。两者用途与字节定义不同。示例只核验固定样本，不实现通用 JCS 或授权服务。

manifest 格式、包版本、业务契约版本与协议版本具有独立语义。人格和认知策略是配置样例，不伪称已发布配置协议。草案修订直接同步示例和检查；真实发布后的演进依据实际消费者设计。

运行 pwsh -NoProfile -File tests/Test-Contracts.ps1。报告默认保存在仓库外临时目录；它验证结构，不证明宿主、授权、生命周期、数据库或真实媒体行为。
