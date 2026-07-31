---
name: lit-data-fetcher
description: "单篇论文语料准备。通过 Zotero MCP 提取单篇文献的元数据、批注（优先）、全文缓存（其次）、PDF 附件信息，输出结构化语料供 lit-note-writer 使用。保持原始语言，不做翻译或总结。MANDATORY TRIGGERS: 取料, 拉取文献信息, 获取批注, 获取全文, 单篇语料"
---

# lit-data-fetcher：单篇论文语料准备

从 Zotero 提取一篇论文的完整语料，交给下游写作技能。本环节只做"搬运"，不做任何加工。

## 取料优先级（刻意设计）

1. **批注 annotations**：精读质量的上限由批注密度决定，永远优先
2. **全文 fulltext**：Zotero 索引的全文缓存
3. **PDF 附件**：全文缓存缺失时的兜底（返回附件路径，由调用方决定是否读取）

## 流程

### 1. 确认输入

- `item_key`：Zotero 条目 key（必填）
- 可选：`vault_root`（仅透传，本技能不使用）

### 2. 调用 Zotero MCP

先 list_tools 确认实际工具名（版本差异），常见工具：

| 用途 | 常见工具名 |
| --- | --- |
| 元数据 | `zotero_get_item_metadata` |
| 批注 | `zotero_get_annotations` |
| 全文 | `zotero_get_item_fulltext` |
| 附件 | `zotero_get_attachment_path` / `zotero_get_item_children` |

### 3. 组装语料（结构化输出）

```json
{
  "item_key": "...",
  "metadata": { "title": "", "creators": [], "year": "", "doi": "", "abstract": "", "tags": [], "collections": [], "itemType": "", "url": "" },
  "annotations": [ { "text": "", "page": "", "color": "", "comment": "" } ],
  "fulltext": "... 或 null",
  "attachments": [ { "path": "", "contentType": "" } ],
  "flags": { "fulltext_missing": false, "annotations_empty": true }
}
```

## 约定

- **保持原始语言**：批注、摘要、全文一律原文保留，不翻译、不总结、不截断
- **公式原样**：全文中的公式文本不做任何规范化（乱码风险由写作环节处理）
- **不省略字段**：拿不到的值置 `null` 并给出 flags，禁止编造
- 全文不可得时设置 `fulltext_missing: true`，调用方据此降级处理（如：仅批注+摘要成文，或跳过并标记待补）

## 边界

- 本技能不读 PDF 二进制内容（除返回路径外）；PDF 内文本提取由调用方按需处理
- 本技能不做任何学术判断，所有提炼发生在 lit-note-writer
