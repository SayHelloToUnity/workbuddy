# WorkBuddy 会话迁移包

- 生成时间：2026-11-23T14:29:29+08:00
- 来源机器：MEUCAN / win32
- 来源账号：`540ddffa-6bca-4ab9-b1be-802e2dda443b`
- 会话数：13，文件数：250

## 前置条件（新机器）

1. 安装 **Git**；
2. 安装 **Python 3.8+**（`python --version` 能输出版本号即可）；
3. 安装 WorkBuddy 并**登录同一账号、至少启动一次**——脚本需要 `~/.workbuddy/workbuddy.db` 已存在才能写入；
4. 若用 SSH 地址克隆，需把新机器的公钥加到 GitHub（也可改用 HTTPS 地址 + Token）。

## 目标机还原

本目录内已附带 `wbmigrate.py`，在**本目录下**打开终端执行即可。

1. **完全退出 WorkBuddy**（含托盘常驻进程），否则写入后侧边栏可能仍显示旧状态。
2. 先预览（不会写盘）：

   ```bash
   python wbmigrate.py import . --dry-run
   ```

3. 确认无误后落盘（脚本会自动备份 workbuddy.db）：

   ```bash
   python wbmigrate.py import . --apply
   ```

4. 若两台机器**用户名不同**，必须做路径重映射，否则侧边栏看不到这些会话：

   ```bash
   python wbmigrate.py import . --apply \
     --map-cwd "C:/Users/老用户名=C:/Users/新用户名"
   ```

5. 若两台机器**登录的是不同 WorkBuddy 账号**，加 `--reassign-user`，否则会话归属他人不可见。
6. 重启 WorkBuddy，侧边栏应出现对应文件夹分组与会话。

## 包里都有什么

| 路径 | 内容 |
|---|---|
| `projects/<路径编码>/<会话id>.jsonl` | 对话正文（消息、工具调用、结果） |
| `projects/<路径编码>/<会话id>/` | 该会话的 tool-results / 子智能体记录 |
| `db/sessions.json` | 侧边栏所需的会话元数据（标题、时间、所属文件夹） |
| `db/spaces.json` / `workspaces.json` | 项目分组与最近打开记录 |
| `db/session_usage.json` | 上下文用量统计 |
| `index/` | 产物索引、变更索引、文件历史 |
| `workspace/` | 仅当导出时加了 `--with-files` 才有 |

`workbuddy.db` 本身**不在**包里——它是 SQLite 二进制且带 -wal/-shm，不适合 git 版本化。
还原时由脚本按目标机的真实表结构插入，因此对版本差异更宽容。

## 日常增量同步（在源机执行）

固定目录 + `--replace` 只保留一份最新快照，git 只记录差异，不会每次新增一个 16MB 的整包：

```bash
python wbmigrate.py export --all -o <仓库父目录> --dir-name snapshot --replace
python wbmigrate.py git <仓库父目录>/snapshot
```
