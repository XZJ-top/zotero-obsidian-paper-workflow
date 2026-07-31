# lit-workflow 安装准备脚本（Windows / PowerShell）
# 用途：
#   1. 检查/安装 zotero-mcp-server（Zotero MCP server，本地模式）
#   2. 可选：初始化 Obsidian vault（模板、索引页、进度日志）
# 用法：
#   .\setup.ps1                          # 只检查环境
#   .\setup.ps1 -InstallMcp              # 检查并安装 zotero-mcp-server
#   .\setup.ps1 -VaultRoot "D:\MyVault"  # 检查 + 初始化 vault
#   .\setup.ps1 -InstallMcp -VaultRoot "D:\MyVault"
param(
  [switch]$InstallMcp,
  [string]$VaultRoot = ""
)

$ErrorActionPreference = "Continue"
Write-Host "==== lit-workflow setup ====" -ForegroundColor Cyan

# ---------- 1. zotero-mcp-server ----------
Write-Host "`n[1/3] Zotero MCP server" -ForegroundColor Yellow
$zoteroMcp = Get-Command zotero-mcp -ErrorAction SilentlyContinue
if ($zoteroMcp) {
  Write-Host "  OK: zotero-mcp 已安装 -> $($zoteroMcp.Source)" -ForegroundColor Green
} else {
  Write-Host "  未找到 zotero-mcp 命令" -ForegroundColor Red
  if ($InstallMcp) {
    Write-Host "  尝试安装 zotero-mcp-server ..."
    $uv = Get-Command uv -ErrorAction SilentlyContinue
    if ($uv) {
      uv tool install "zotero-mcp-server[all]"
    } else {
      Write-Host "  未找到 uv，改用 pip 安装（需 Python 3.10+）..."
      python -m pip install "zotero-mcp-server[all]"
    }
    if (Get-Command zotero-mcp -ErrorAction SilentlyContinue) {
      Write-Host "  安装成功" -ForegroundColor Green
    } else {
      Write-Host "  安装失败：请手动执行 pip install 'zotero-mcp-server[all]' 或 uv tool install 'zotero-mcp-server[all]'" -ForegroundColor Red
    }
  } else {
    Write-Host "  跳过安装（加 -InstallMcp 参数可自动安装）" -ForegroundColor DarkGray
  }
}

# ---------- 2. Zotero 本地 API 检查 ----------
Write-Host "`n[2/3] Zotero 本地 API" -ForegroundColor Yellow
$conn = Get-NetTCPConnection -State Listen -LocalPort 23119 -ErrorAction SilentlyContinue
if ($conn) {
  Write-Host "  OK: Zotero 本地 API 端口 23119 正在监听" -ForegroundColor Green
} else {
  Write-Host "  端口 23119 未监听。请确认：" -ForegroundColor Red
  Write-Host "    - Zotero 桌面版正在运行" -ForegroundColor DarkGray
  Write-Host "    - 设置 > 高级 已勾选 'Allow other applications on this computer to communicate with Zotero'" -ForegroundColor DarkGray
}

# ---------- 3. vault 初始化 ----------
Write-Host "`n[3/3] Obsidian vault 初始化" -ForegroundColor Yellow
if ($VaultRoot) {
  if (Test-Path $VaultRoot) {
    $pack = $PSScriptRoot
    $tplSrc = Join-Path $pack "templates\论文精读模板.md"
    $tplDst = Join-Path $VaultRoot "templates\论文精读模板.md"
    New-Item -ItemType Directory -Force -Path (Split-Path $tplDst) | Out-Null
    Copy-Item -Force $tplSrc $tplDst
    Write-Host "  OK: 模板 -> $tplDst" -ForegroundColor Green

    $files = @{
      "文献索引.md"       = "# 文献索引`n`n> 由索引任务自动维护。`n`n## 全部精读笔记`n`n| 笔记 | 主题 | 方法 | 年份 | zotero_key | 状态 |`n| --- | --- | --- | --- | --- |"
      "研究主题索引.md"   = "# 研究主题索引`n`n> 由索引任务自动维护：按研究主题聚类。`n`n## 主题 → 笔记"
      "研究方法索引.md"   = "# 研究方法索引`n`n> 由索引任务自动维护：按方法聚类。`n`n## 方法 → 笔记"
      "字段补全检查.md"   = "# 字段补全检查`n`n> 由索引任务自动维护。`n`n## 待补强笔记`n`n| 笔记 | 缺失字段 | 原因 | 状态 |`n| --- | --- | --- | --- |"
      "_ProcessLog_进度记录.md" = "# _ProcessLog_ 精读进度记录`n`n> 批处理断点日志，由 lit-collection-manager 维护。`n`n| 时间 | item key | 标题 | 状态 | 说明 |`n| --- | --- | --- | --- | --- |"
    }
    foreach ($name in $files.Keys) {
      $dst = Join-Path $VaultRoot $name
      if (Test-Path $dst) {
        Write-Host "  跳过（已存在）: $name" -ForegroundColor DarkGray
      } else {
        Set-Content -Path $dst -Value $files[$name] -Encoding UTF8
        Write-Host "  创建: $name" -ForegroundColor Green
      }
    }
  } else {
    Write-Host "  vault 路径不存在: $VaultRoot" -ForegroundColor Red
  }
} else {
  Write-Host "  未指定 vault（加 -VaultRoot 'D:\MyVault' 可自动初始化）" -ForegroundColor DarkGray
}

# ---------- 收尾 ----------
Write-Host "`n==== 后续手动步骤 ====" -ForegroundColor Cyan
Write-Host "1. Obsidian：安装社区插件 Local REST API，开启 HTTPS server，复制 API key"
Write-Host "2. HanaAgent：设置 > 连接器，导入 mcp/mcpServers.example.json（填入 API key）"
Write-Host "3. 技能：把 skills/ 下四个技能目录装入技能库并为 Agent 启用"
Write-Host "4. 新会话中开始使用：'精读 Zotero 里 <分类名> 的论文'"
