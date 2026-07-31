---
name: lit-collection-manager
description: "Zotero 文献批处理调度。读取 Zotero 分类中的条目，比对 _ProcessLog_ 进度记录，筛出未处理文献，串行调度 lit-data-fetcher 与 lit-note-writer 完成精读，每篇完成立即记账。MANDATORY TRIGGERS: 精读, 批处理, 批量读文献, 处理 Zotero 分类, 还有哪些没读, 断点续跑"
---

# lit-collection-manager：Zotero 文献批处理调度

将 Zotero 某个分类（collection）中的论文批量转成 Obsidian 精读笔记。负责调度，不负责具体取料与写作（那属于 lit-data-fetcher 与 lit-note-writer）。

## 适用场景

- "精读 Zotero 里 to-read 分类的论文"
- "把最近收藏的文献全部生成精读笔记"
- 处理中断后恢复：根据进度日志自动跳过已完成条目

## 流程

### 1. 确认参数

优先使用显式参数，缺省时按顺序取环境变量 / 上次会话值：

| 参数 | 说明 |
| --- | --- |
| `collection` | Zotero 分类名或 key |
| `vault_root` | Obsidian vault 根目录（安装时按本机路径配置，见 README） |
| `log_path` | 进度日志路径，默认 `<vault_root>/_ProcessLog_进度记录.md` |

### 2. 读取待处理清单

1. 通过 Zotero MCP 获取分类列表，找到目标 collection（工具名以实际 list_tools 结果为准，常见：`zotero_get_collections` / `zotero_get_collection_items`）
2. 获取该分类全部条目，记录每条的 item key、标题、条目类型（journalArticle / preprint / book 等）

### 3. 比对进度日志

读取 `_ProcessLog_进度记录.md`（不存在则视为空，首次运行时创建表头）：

```markdown
| 时间 | item key | 标题 | 状态 | 说明 |
| --- | --- | --- | --- | --- |
```

状态取值：`done`（已生成笔记）/ `skip`（跳过）/ `failed`（失败，记录原因）。

筛出状态非 `done` 且非 `skip` 的条目为待处理队列。

### 4. 串行执行

对每个待处理条目，按顺序执行且**只执行一个后再进入下一个**：

1. 调 lit-data-fetcher 取料（传 item key + vault_root）
2. 调 lit-note-writer 生成笔记（传语料 + vault_root）
3. 成功 → 追加进度日志一行 `done`，写入笔记路径
4. 失败 → 追加 `failed` + 失败原因，继续下一篇（不中断整个批次）

### 5. 收尾汇报

输出本轮处理汇总：

- 本次处理 n 篇：成功 x / 失败 y / 跳过 z
- 生成笔记清单（路径列表）
- 剩余未处理条目数

## 约定

- **串行执行**：绝不并行处理多篇，避免进度日志写入竞争与上下文混乱
- **断点续跑**：进度日志是唯一真相来源，任何中断后重跑都从日志恢复
- **立即记账**：每篇完成即刻追加日志，禁止攒到最后统一写
- **跳过不报错**：非文献条目（attachment / note）直接记 `skip` 并继续
- 单篇失败不影响批次，但要在最终汇报中突出显示

## 边界

- 本技能不读取 PDF 内容、不生成笔记正文，只做调度与记账
- 进度日志格式不得随意变更；字段含义变化需更新本文件
