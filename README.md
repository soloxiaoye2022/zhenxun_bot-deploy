# zhenxun_bot-deploy

真寻 bot 一键部署脚本（Termux / Linux）

对齐官方文档：

- 真寻安装：https://zhenxun-org.github.io/zhenxun_bot/install/zhenxun/
- 真寻 QQ 协议端：https://zhenxun-org.github.io/zhenxun_bot/install/install-qq
- LLBot（原 LLOneBot）：https://github.com/LuckyLilliaDev/LuckyLilliaBot

## 食用方法

此版本可以在服务器、虚拟机以及使用 tmoe 安装的 proot 容器（proot 容器只支持 arm64 架构的 Debian12 和 Ubuntu22.04）部署真寻。菜单为 tmoe 风格的 whiptail/dialog；无 TUI 时自动回退数字菜单。

手机部署真寻交流群: 948192110

## 系统要求

支持的发行版：

- Debian11/12
- Ubuntu20/22/24

其他发行版请自行安装 Python 3.10+。最低要求 Ubuntu20 / Debian11。

真寻官方要求：

- Python >= 3.10（整合包建议 >= 3.11）
- 包管理：`uv`（替代 poetry / pip）
- 默认端口：`8080`
- 默认数据库：Sqlite（`DB_URL = "sqlite:data/db/zhenxun.db"`）
- `data/config.yaml` 需启动一次 Bot 后生成
- 插件已迁出本体，启动后通过插件商店安装

协议端覆盖范围（没有一家能做到 Linux 全架构原生）：

- 本脚本默认：LLBot CLI，官方产物仅 `linux-x64` / `linux-arm64`
- 手机 Termux：走 tmoe/proot 的 Debian12 或 Ubuntu22.04 arm64，再装 LLBot linux-arm64
- NapCat-Installer / napcat-linux-installer 已 404；NapCatQQ 主仓仅 Ending README
- Lagrange.Core V1 OneBot 已 sunset；V2 走 Milky，不是真寻默认的 OneBot 11

## 官方手动流程（脚本内部同样按此执行）

```bash
git clone https://github.com/zhenxun-org/zhenxun_bot.git
cd zhenxun_bot
pip install uv
uv sync
uv run zx
```

LLBot Linux CLI（安装到 `/root/LLBot`）：

```bash
# x64
wget https://github.com/LuckyLilliaDev/LuckyLilliaBot/releases/latest/download/LuckyLillia-CLI-linux-x64.zip
# arm64
wget https://github.com/LuckyLilliaDev/LuckyLilliaBot/releases/latest/download/LuckyLillia-CLI-linux-arm64.zip
unzip LuckyLillia-CLI-linux-*.zip -d /root/LLBot
chmod +x /root/LLBot/start.sh /root/LLBot/llbot
./start.sh
```

反向 WS 地址：`ws://127.0.0.1:8080/onebot/v11/ws`

LLBot WebUI 默认：`http://127.0.0.1:3080`

## 一键脚本

```bash
bash <(curl -s -L https://raw.githubusercontent.com/soloxiaoye2022/zhenxun_bot-deploy/main/install.sh)
```

大陆机器：

```bash
bash <(curl -s -L https://ghfast.top/https://raw.githubusercontent.com/soloxiaoye2022/zhenxun_bot-deploy/main/install.sh)
```

备用脚本：

```bash
bash <(curl -s -L https://gh-proxy.org/https://raw.githubusercontent.com/soloxiaoye2022/zhenxun_bot-deploy/main/install.sh)
```

## GitHub 镜像

脚本首次安装时会测速并自动选择最快的 GitHub 镜像，也支持手动指定或直连。选择结果保存到 `/root/.zhenxun_deploy/proxy.conf`，之后自动复用。删除该文件即可重新测速。

清除已保存的镜像配置：

```bash
rm -f /root/.zhenxun_deploy/proxy.conf
```

tmoe 脚本：

```bash
bash -c "$(curl -L gitee.com/mo2/linux/raw/2/2)"
```

## 更新

**2026/11/18**

- 对齐真寻官方 uv 部署：`git clone zhenxun-org/zhenxun_bot` → `pip install uv` → `uv sync` → `uv run zx`
- 默认端口改为 8080，默认数据库改为 Sqlite
- 协议端改为 LLBot CLI（LuckyLilliaBot，原 LLOneBot）：linux-x64 / linux-arm64 zip + `start.sh`
- NapCat-Installer 已 404，不再作为一键安装入口
- 插件不再随脚本拷贝进本体，启动后走插件商店
- `config.yaml` 仅作历史参考；运行时配置在 `data/config.yaml`
- 菜单改为 tmoe 风格：优先 `whiptail`/`dialog`，无 TUI 时回退 echo/read；`ZX_NO_TUI=1` 强制回退
- 砍掉源码编译 Python / 旧 glibc 路径；Debian <11、Ubuntu <20 直接退出
- 最低要求仍是 Debian11/12、Ubuntu20/22/24，架构仅 linux-x64 / linux-arm64
- TUI 组件缺失时会自动安装，失败则明确提示原因和手动安装命令，不再静默降级
- GitHub 镜像改为测速选优：6 个候选自动测速取最快，也支持手动指定或直连；结果持久化到 `/root/.zhenxun_deploy/proxy.conf`
- 移除失效镜像 `github.moeyy.xyz`、`mirror.ghproxy.com`；新增 `gh-proxy.org`、`ghproxy.cfd`、`gh-proxy.net`、`ghproxy.net`
- 依赖清理：去掉未使用的 `xvfb`，字体按发行版逐个尝试，`libasound2`/`libasound2t64` 自动探测，修正 CentOS 包名

**2024/9/1**

- 弃用 [Mrs4s / go-cqhttp](https://github.com/Mrs4s/go-cqhttp)，更换为 [NapCat](https://github.com/NapNeko/NapCatQQ)
