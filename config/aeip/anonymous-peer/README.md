# 匿名第三方端 Q：设计数据

这里没有网关、SDK、适配器或客户端运行代码。`hello.json` 使用明确无效的示例凭据；manifest 的 entrypoint 是未实现标记，不能安装运行。

- Q-native 仅实现 [AEIP](../../../docs/appendices/12-EXTERNAL-INTERACTION-PROTOCOL.md) 和公开业务契约，不需要 manifest。
- Q-bridge 保留合成 Q7 原生协议，由适配器转换文本输入/输出、观察、交付和计数器动作。Q7 不是任何真实平台的协议。
- `adapter.json` 定义宿主注册时的映射与 SPI 责任；`manifest.json` 展示开放的 protocol-adapter 贡献。独立桥接使用相同映射语义和 standalone 位置，不安装此 manifest。
- `counter.contract.json` 是未来模拟端提供的精确服务，increment 应在真实运行测试中保存计数及幂等结果；samples 是可丢观测流。当前文件仅是契约。
- `q7.schema.json` 只覆盖四类成对映射帧，其他映射责任为待实现声明，不宣称 Q7 翻译器完整。

固定样例、正反例和传输模式定义见 [AEIP 测试资产](../../../tests/contracts/aeip-cases.json)。结构通过不证明认证、请求关联、权限、回执真实性、翻译或恢复已实现。适配器安装与独立原生接入是两条路径，不把本目录清单变成所有外部应用的强制安装要求。
