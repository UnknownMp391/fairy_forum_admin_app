#!/bin/sh
# 发版前递增 buildNumber：读取 pubspec.yaml 的 version（如 1.0.0+1），
# buildNumber +1（1.0.0+1 -> 1.0.0+2）后写回 pubspec.yaml。
# 之后由 release_publish.sh 跑 build_runner 重新生成 lib/version.g.dart。
set -e
cd "$(dirname "$0")"

VERSION=$(sed -nE 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?).*/\1/p' pubspec.yaml | head -1)
if [ -z "$VERSION" ]; then
  echo "ERROR: 无法从 pubspec.yaml 解析 version（需形如 x.y.z 或 x.y.z+build）" >&2
  exit 1
fi

BASE="${VERSION%%+*}"
BUILD="${VERSION##*+}"
if [ "$BUILD" = "$VERSION" ]; then
  NEW="${VERSION}+1"          # 无 buildNumber：追加 +1
else
  NEW="${BASE}+$((BUILD + 1))" # 有 buildNumber：+1
fi

# 便携 sed（macOS/Linux 通用）：先写 .bak 再删除
sed -i.bak -E "s/^(version:[[:space:]]*).*/\1${NEW}/" pubspec.yaml
rm -f pubspec.yaml.bak

echo "bumped version: ${VERSION} -> ${NEW}"
