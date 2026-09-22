#!/bin/sh
# Render 启动脚本。配置一律来自 Render 环境变量，本文件只负责套用它们再起 gateway，
# 免得 build/start 命令散落在 dashboard 里没人看得见。
set -eu

# 仓库自带的 venv（build 阶段 uv sync 装的）。自己拼 PATH，start command 就不用写一长串。
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PATH="$ROOT/.venv/bin:$PATH"
export PATH

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
export HERMES_HOME
mkdir -p "$HERMES_HOME"

# 模型：Provider / Model 两个 env 说了算，没设就不动 config。
# 任何 [OI] 兼容端点都行——provider=custom 时 Hermes 按 base_url 的 host 找
# <VENDOR>_API_KEY（如 cavoti.com → CAVOTI_API_KEY），不读 CUSTOM_API_KEY。
if [ -n "${Provider:-}" ]; then hermes config set model.provider "$Provider"; fi
if [ -n "${Model:-}" ]; then hermes config set model.default "$Model"; fi

# 工具集瘦身：API server 默认工具集塞了 50+ 个工具的 schema，全进每次请求体，
# Groq 免费档直接 413。这里只留写代码沙盒要用的：终端/进程/文件 + 技能 + 代码执行。
# 想恢复全量：把 Toolsets env 设为 all，或删掉这段。
if [ -n "${Toolsets:-}" ]; then
    hermes config set platform_toolsets.api_server "$Toolsets"
fi

# 写代码人格：coding posture 默认只在交互式平台（cli/tui/desktop）激活，
# api_server 平台会被判成 general。这台服务就是 Lin 的写代码沙盒，强制启用。
hermes config set agent.coding_context on

# Ponytail 技能族（写代码的懒人规矩）：~/.hermes 在免费实例上会被清空，
# 所以技能随仓库走，每次启动软链到 Hermes 的技能目录。
for _skill in "$ROOT"/skills/ponytail-suite/*/; do
    [ -d "$_skill" ] || continue
    ln -sfn "$_skill" "$HERMES_HOME/skills/$(basename "$_skill")" 2>/dev/null || true
done

# 免费实例保活：每 10 分钟打一次自己的公网 URL，让 Render 判成"有入站流量"→ 不睡，
# $HERMES_HOME 里的 session/记忆才留得住。
# 必须是公网地址：Render 的入站流量判定在它的代理层，打 localhost 不算。
# 不要改用 /robots.txt —— Render 明确不为该路径唤醒服务。
if [ -n "${HERMES_PUBLIC_URL:-}" ]; then
    (
        while :; do
            sleep 600
            "$ROOT/.venv/bin/python" -c \
                "import urllib.request; urllib.request.urlopen('${HERMES_PUBLIC_URL}/v1/models', timeout=30)" \
                >/dev/null 2>&1 || true
        done
    ) &
fi

exec hermes gateway run --no-supervise
