# 参赛申报材料：基于 MoonBit 的高性能 Cron 定时任务计算引擎

## 项目基本信息
- **项目名称**：moonbit-cron
- **所属赛道**：2026 MoonBit 国产基础软件生态开源大赛 Track 1
- **GitHub 仓库**：[https://github.com/lijunjie860/MoonBit-Cron](https://github.com/lijunjie860/MoonBit-Cron)
- **GitLink 仓库**：[https://gitlink.org.cn/lijunjie860/MoonBit-Cron](https://gitlink.org.cn/lijunjie860/MoonBit-Cron)

## 1. 选题背景与高成熟度
在现代基础软件、微服务、以及分布式调度系统中，Cron 引擎是“发动机”。目前 MoonBit 生态仍缺乏能够推算未来执行周期的原生引擎。
我们打造的不仅是一个 Parser，更是一个具备**下一次执行时间预测算法 (`next_trigger`)**的完整计算引擎。这种级别的高成熟度组件可以直接作为各类“云原生调度框架”的底层依赖，极大填补了 MoonBit 生态。

## 2. 核心技术亮点与丰富度
- **核心调度能力 (`next_trigger`)**：手动实现了一套轻量级 MoonBit 日历系统（平闰年、多重跨月进位推演算法），允许在极短时间返回下一次触发点 `expr.next(time)`。
- **完备的边界防御与解析**：不依赖正则，原生分词切片；支持复杂的步长 `/` 和列表 `,` 复合操作。内置强制抛错，确保开发者无法传入无效月份（如 13）和非法的 Cron。
- **协议矫正与高覆盖率**：完美实现了业界通用的“DOM (日) 与 DOW (周) 的 OR 条件触发逻辑”。包含高达 10 余个严密的单体与极限边界（跨年闰月）自动化测试。
- **纯净的零依赖**：通过巧妙的数据结构设计，没有引入任何外部包，体积极致轻量。

## 3. 开源规范与工程质量
- **持续集成 (CI/CD)**：项目接入了 GitHub Actions 工作流，并在 README 挂载了状态徽章，确保任意 Commit 都 100% 通过 `moon test` 与 `moon fmt` 规范检查。
- **双端同步分发**：项目在 GitHub 和 GitLink 同步开源并具备标准 MIT 协议，符合国产生态社区开源建设号召。

## 4. 商业扩展路线
借助 MoonBit 极速编译出 Wasm 的优势：
1. **浏览器离线调度**：无缝将 Cron 引擎嵌入 Web 前端或小程序的离线 Worker 中。
2. **边缘计算节点**：部署在 Serverless 边缘计算网络，实现低于传统语言框架延迟的高频调度网关。
