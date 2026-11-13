# 匿名角色客户端 C 的平台交互协议插件

本例对应“第三方开源了一个可交流、可动的 Live2D 客户端，如何接入 ALIA”。客户端的外部协议假设叫 C7，与 ALIA 协议不同；下面的名称、消息和动作能力均为合成设计数据，不属于 Live2D 标准，也不代表已连接任何真实项目。

```text
ALIA 核心 ↔ ALIA 通用交互契约 ↔ 本平台交互协议插件 ↔ C7 ↔ 客户端 C
                                      ↑
                          连接管理器 ← WebUI 配置面板
```

[清单](manifest.json)声明管理/交互服务和角色表达贡献；[连接定义](connector.json)提供地址、外部协议版本、已配对客户端和凭据槽；[实例](instance.json)为未启用、未连接快照。一个插件可创建多个实例，配置页不负责保活。服务端适配代码连接到客户端，不表示客户端已经在线或身份已认证。

外侧按客户端原有协议实现，内侧按 ALIA 契约实现。插件中既有连接/认证/重连代码，也有双向数据转换；只写这份 Schema 或安装配置面板不能建立连接。未知客户端并不要求核心新增 `Live2DMessage` 类型。

| 外侧协议 C7 | ALIA 侧 | 转换责任 |
|---|---|---|
| `user.say` 的 id/room/speaker/body | interaction.input 的 input_id/conversation_ref/actor_ref/content_parts | 字段映射；来源实例/连接代次与接收时间由合法接入上下文关联，speaker 不是可信 Principal |
| `avatar.say` 的 request/room/to/body | interaction.deliver 的 output_delivery_id/endpoint_ref/audience_refs/segments | 已授权表达转成客户端消息；目标和受众不能由模型任意改写 |
| `accepted` | 对应调用受理或待核验状态 | 没有已显示/播放证据，不能转换成 completed DeliveryReceipt |
| 角色动作能力声明 | 可选 avatar.motion 及表达映射贡献 | 还须实现动作表、准确内容契约、语义映射与实际回执；本例未提供可执行动作 wire |

[外侧帧 Schema](peer.schema.json)只约束本例的三种合成消息，不注册成 ALIA 的标准协议。[成对用例](../../../tests/contracts/bridge-cases.json)展示已知文本语义的双向对应；检查只验证两侧形状及固定样例内容，不执行翻译器、认证或发送。

required_features 仅要求文本输入/输出。连接完成但缺少动作能力时，可以呈现文本路径可用、动作不可用；不能宣称完整角色体验。connection_dependents 将表达贡献关联到同一连接所有者，其使用的是交互服务中的合法交付路径，不新开第二条播放路径。若以后加入截屏/文件操作，应作为独立工具贡献、申请对应权限；共享连接只共享传输资源，不共享授权。

客户端协议变成 C8 时，本例配置校验明确拒绝；未来适配器支持 C8 后发布新版本与对应映射，不要求 ALIA 核心预知 C8 字段。模型/动作表变化同样需要撤销旧映射、核验新资源。纯渲染客户端只能承担其实际支持的呈现；客户端自己的 AI 和历史不能与 ALIA 同时决定同一轮回复或覆盖 ALIA 状态。
