# feishu-summary-skills

> 把任意内容(网页、PDF、音视频、播客、本地文件)**详细总结 → 自动做成飞书文档 → 把链接发到你的飞书群**。三个可独立、可组合的 Agent Skills,支持 opencode / Claude Code / Codex / Cursor 等客户端。

## 它解决什么问题

你有过这种经历吗:

- 想「把这篇长文总结一下发到群里」,结果要先自己复制粘贴、开飞书、建文档、设权限、复制链接、切到群里粘贴——来回五六个动作;
- 让 Agent 总结,它只给几句话,不够详细,带不出数据、时间戳和争议点;
- 让 Agent 直接发飞书,它又是另一套 skill,两个就各干各的、衔接不上。

这个仓库把整条链路分成**三个职责唯一的 skill**,并按需串起来:

```
来源(URL / 文件 / 音视频)
   │
   ├─ [summary]          只负责「详细总结」,默认不发送            (内容侧)
   │
   └─ [summary-to-feishu]「总结 + 发飞书」一条龙入口,编排下面这个   (编排侧)
         └─ [send-feishu-doc] 只负责「建文档 → 设权限 → 发链接」   (交付侧)
```

- `summary` 、`send-feishu-doc` 互不依赖,可以各自单独用;
- `summary-to-feishu` 是端到端入口,内部委托上面两个,不重复实现;
- 全程只有一条飞书消息、一个文档,不会重复发送。

## 三个 Skill 的区别与用法

| Skill | 职责 | 触发词 | 适合场景 |
|---|---|---|---|
| `summary` | 按 10 段固定契约输出详细总结 | 总结、摘要、提炼、这篇讲什么、这个视频讲什么、转录 | 只要总结,不要发飞书 |
| `send-feishu-doc` | 把任意 Markdown 变成飞书文档并发送链接 | 做成飞书文档发我、发飞书文档、send as Feishu doc | 发报表、纪要、笔记等**已有内容** |
| `summary-to-feishu` | 详细总结 + 发飞书 一条龙 | 总结并发飞书、总结并发送、总结发到群里、详细总结发飞书 | 端到端:**总结+发送** |

## 特性

- **详细可复现的总结**:内置 10 段输出契约(一句话结论/概述/背景/核心要点/证据与反方/争议/作者结论/行动建议/评价/元信息),用 `--prompt-file` 固定模板 + `--length long` 产出,不是临场发挥。
- **来源全覆盖**:网页、PDF、本地文件、YouTube/视频、播客,支持登录态页面、时间戳、音视频转写。
- **安全第一**:涉密/付费/需登录来源的飞书文档默认私有或仅本组织可读,绝不默认公开;公开来源才设为「任何人可读」为他人方便打开你的总结。
- **隐私隔离**:你的 chat_id、群名、profile 等都放在本机 `config.json`,**永不入库**;仓库里只有 `config.example.json`(占位符版)。
- **跨平台**: macOS / Linux / Windows 都有对应配置路径与脚本(`setup.sh` / `setup.ps1`)。

## 目录结构

```
feishu-summary-skills/
├── README.md
├── LICENSE                  MIT
├── config.example.json      配置模板(复制后改成你自己的)
├── install.sh               把三个 skill 装进你的 Agent 客户端
└── skills/
    ├── summary/             总结 skill(SKILL.md + 10 段模板 + agent 描述)
    ├── send-feishu-doc/     飞书交付 skill
    └── summary-to-feishu/   端到端编排 skill
└── scripts/
    ├── setup.sh              交互式生成 config.json(macOS/Linux)
    ├── setup.ps1             Windows 版
    ├── check-setup.sh        环境/权限/发送演练体检
    └── check-setup.ps1       Windows 版体检
```

## 环境要求

| 依赖 | 用途 | 说明 |
|---|---|---|
| Node.js 18+ | 运行 lark-cli | [nodejs.org](https://nodejs.org) |
| `lark-cli`(⚠ 必需) | 创建飞书文档/设权限/发消息 | `npm install -g @larksuite/cli` |
| `summarize`(仅当用 summary / summary-to-feishu) | 抓取与总结 | `npm install --global @steipete/summarize`(要求 Node 24+,或 `brew install steipete/tap/summarize`) |
| `jq`(仅 macOS/Linux 脚本) | 解析 JSON | macOS: `brew install jq`, Debian: `apt install jq`, Windows 用 PowerShell 版脚本无需 jq |

> 不用 `summary`、只用 `send-feishu-doc` 的用户,可以不装 `summarize`。

---

## 快速开始(三步)

> ⚠ 全程先把真实配置与密钥留在本机,不要提交到任何仓库。

### 第 1 步:克隆并安装 skill

```bash
git clone https://github.com/ai-evolution-lab/feishu-summary-skills.git && cd feishu-summary-skills
./install.sh                     # 默认装到 opencode: ~/.config/opencode/skills
./install.sh --all               # 同时装 claude/codex/agents
```

PowerShell(Windows):

```powershell
.\install.sh --all               # 用 Git Bash 执行;或手动把 skills\ 下三个文件夹复制到你的客户端 skills 目录
```

### 第 2 步:安装依赖 + 授权(网络需要能访问飞书开放平台)

```bash
npm install -g @larksuite/cli
lark-cli auth login        # 弹出设备码/二维码,用手机飞书扫码授权
```

授权会**在开放平台配置好应用后**才有管理浏览器权限,顺序见下文「首次使用前的飞书准备工作」。

### 第 3 步:生成配置文件

方式 A(推荐,交互式):

```bash
./scripts/setup.sh
```

方式 B(手动,最直观):复制模板,粘贴进系统路径,把 `xxxxxxxx` 换成你自己的值(见下节):

```bash
cp config.example.json ~/.config/feishu-skills/config.json
```

检查: `./scripts/check-setup.sh`

---

## 配置文件 `config.json` 全说明

> 提醒:`config.json` 只包含「群 ID、profile 名」这类**半公开标识**,不含任何密钥。真正的访问令牌由 `lark-cli auth login` 保存在 lark-cli 自己管理的私有存储里,不会写入本文件,更不会入库。
>
> 请务必在 `.gitignore` 中保留 `config.json` 排除项,并**不要把真实 `config.json` 重命名后上传**。

### 文件路径(记住这个位置)

| 平台 | `config.json` 位置 | 打开方式 |
|---|---|---|
| macOS | `~/.config/feishu-skills/config.json` | `vi ~/.config/feishu-skills/config.json` 或 Finder「前往文件夹」输入 `~/.config/feishu-skills` |
| Linux | `~/.config/feishu-skills/config.json` | 同上,`$HOME/.config/feishu-skills/config.json` |
| Windows | `%USERPROFILE%\.config\feishu-skills\config.json` | 资源管理器地址栏输入 `%USERPROFILE%\.config\feishu-skills` 回车 |

macOS/Linux 打开/编辑示例:

```bash
mkdir -p ~/.config/feishu-skills
cp config.example.json ~/.config/feishu-skills/config.json
code ~/.config/feishu-skills/config.json      # 或用 vim/nano
```

Windows(命令提示符 / PowerShell)示例:

```powershell
mkdir "$env:USERPROFILE\.config\feishu-skills"   # 不存在时创建
# 复制 config.example.json 到这个目录,然后用记事本/VS Code 打开编辑
notepad "$env:USERPROFILE\.config\feishu-skills\config.json"
```

### 字段说明

```jsonc
{
  "chat_id": "oc_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",  // 必填。接收文档链接的飞书群 ID(oc_ 开头)
  "chat_name": "我的文档接收群",                        // 可选。群名,仅供人读,不会按名字去解析
  "sender_identity": "bot",                             // 发送消息身份: bot(推荐,用应用机器人) | user(用你自己)
  "profile": "my-feishu-profile",                        // 可选。lark-cli 的 profile 名;不填则用当前默认
  "lark_cli_path": "",                                  // 可选。lark-cli 不在 PATH 时手动指定,如 Windows
                                                        //   示例: "C:\\Users\\你的名字\\AppData\\Roaming\\npm\\lark-cli.cmd"
  "message_format": "link"                              // 群消息内容: link(只发标题+链接) | link_with_excerpt(附2-3句摘要)
}
```

- **JSON 转义注意(Windows)**:路径里的反斜杠要在 JSON 里写成双反斜杠 `\\`。
- **chat_id 怎么拿**:在飞书建个群 → 把应用机器人拉进群 → 运行 `lark-cli im +chats-list --as user --format json | jq -r '.data.items[] | .name+" -> "+.chat_id'` 找到对应群的 `oc_...`。
- **profile 怎么查**:运行 `lark-cli profile list`。没有特殊需要直接留空。

### 首次使用前的飞书准备工作(一次性)

1. 打开 [飞书开放平台](https://open.feishu.cn) →「创建企业自建应用」,记下 App ID。
2. 应用里开启「机器人」能力(若 `sender_identity` 用 `bot`)。
3. 权限管理打开以下 scope(只开用得到的):
   - `docx:document:create`(创建文档)
   - `docs:permission.setting:write_only`(设置文档权限,可选读的加 `docs:permission.setting:read`)
   - `im:message` / `im:message:send_as_bot`(发送消息,涉及飞书开放版本以控制台为准)
4. 启用应用版本 → 发布版本(测试环境选「发布」,生产需要发布到可用版本)。
5. 重新执行 `lark-cli auth login` 让新 scope 生效。
6. 在飞书里创建目标群,把机器人加入群成员。

## 使用示例

端到端(总结 + 发飞书):

> 「总结这篇文章并发到群:https://example.com/article」

只总结不发送:

> 「总结一下 https://example.com/article」

只发已有内容:

> 「把下面这段纪要做成飞书文档发到群:……」

## 常见问题

| 报错/现象 | 原因 | 处理 |
|---|---|---|
| 发送返回 `232011` | 应用机器人不是目标群成员 | 把机器人加进群,或 `lark-cli im chat.members create --as user --chat-id <id> --member-id-type app_id` |
| `-200004` / scope 不足 | 应用权限未开通或未重新授权 | 开放平台加 scope → 重新发布 → 重新 `lark-cli auth login` |
| 找不到配置文件 | 路径没对上 | 按上表核对路径;Windows 注意是 `%USERPROFILE%`,不是 `C:\` 根 |
| skill 在客户端里不出现 | 安装错目录 | `./install.sh --all`;opencode 用 `~/.config/opencode/skills` |
| Windows 提示 lark-cli 不是命令 | 未全局安装或 PATH 未刷新 | `npm install -g @larksuite/cli` 后重开终端 |
| 文档链接别人打不开/能编辑 | 权限设置不同于预期 | 公开来源默认任何人可读;**绝不设任何人可编辑**(`anyone_editable`)除非明确要求 |

## 隐私与安全

- `config.json`、`.env`、密钥文件永远在本机,并被 `.gitignore` 排除;**仓库里没有任何真实 ID / 群名 / profile / 密钥**,`config.example.json` 全部用 `xxxx` 占位。
- 涉密/付费/需登录来源的总结,默认文档**私有或仅本组织可读**,不会自动公开到外网。
- 不申请多余的 scope,只按 CLI 提示的最小 scope 授权;`lark-cli` 的令牌由它自己加密保管。

## License

[MIT](LICENSE) © ai-evolution-lab