#!/bin/sh
# 发版：Web(wasm) 部署 CF Pages + APK 三 ABI + 上传 Sentry 调试符号/源码映射
#
# 前置要求（已就绪）：
#   - 认证：项目根 sentry.properties 里的 auth_token（.gitignore 已排除），
#     或环境变量 SENTRY_AUTH_TOKEN；二者有其一即可
#   - sentry-cli：已安装（如 pnpm add -g @sentry/cli，当前 3.6.2）；
#     插件通过 --sentry-define=bin_path 复用，避免其慢速下载（版本校验只警告）
set -e

export API_BASEURL="https://fairyforumadminapp-api.unknownmp.dpdns.org/"

if [ -z "$SENTRY_AUTH_TOKEN" ] && ! grep -q '^auth_token=' sentry.properties 2>/dev/null; then
  echo "ERROR: 缺少 Sentry 认证：设置环境变量 SENTRY_AUTH_TOKEN 或项目根 sentry.properties 的 auth_token。" >&2
  echo "创建: https://sentry.io/settings/account/api-auth-token/ （勾选 project:write）" >&2
  exit 1
fi

SENTRY_CLI="${SENTRY_CLI:-$(command -v sentry-cli)}"
if [ -z "$SENTRY_CLI" ]; then
  echo "ERROR: 未找到 sentry-cli，请先安装（npm i -g @sentry/cli）或设置 SENTRY_CLI 指向二进制。" >&2
  exit 1
fi
echo "使用 sentry-cli: $SENTRY_CLI"

# 1. 递增 buildNumber（version +1 写回 pubspec，lib/version.g.dart 由下面 build_runner 重新生成）
./bumpbuild.sh

flutter pub get

dart run build_runner build

# Web：--source-maps 产出 main.dart.js.map（sentry_dart_plugin 上传用）
flutter build web --dart-define=API_BASEURL=$API_BASEURL --release --wasm --source-maps --no-web-resources-cdn \
  && cp -rv web_static/* build/web/ \
  && wrangler pages deploy --project-name fairy-forum-admin-app ./build/web/

# APK：--split-debug-info 产出 *.symbols 调试符号（sentry_dart_plugin 上传用）
flutter build apk --dart-define=API_BASEURL=$API_BASEURL --release --split-per-abi --split-debug-info=build/symbols

# 上传调试符号 + 源码映射到 Sentry：
# release = 来自 lib/version.g.dart 的 appRelease（name@version+buildNumber，与 main.dart 的 options.release 一致）
dart run sentry_dart_plugin --sentry-define=bin_path=$SENTRY_CLI
