#!/usr/bin/env bash
# Package a Theos .app as an unsigned IPA.
set -euo pipefail

APP_NAME="${APP_NAME:-FuoEvolve9}"
OUTPUT_IPA_NAME="${OUTPUT_IPA_NAME:-${APP_NAME}.ipa}"
APP_DIR="${APP_NAME}.app"

find_app() {
    local candidate
    for candidate in \
        "${1:-}" \
        ".theos/_/Applications/${APP_DIR}" \
        ".theos/obj/iphoneos/${APP_DIR}" \
        ".theos/obj/${APP_DIR}" \
        ".theos/obj/debug/${APP_DIR}" \
        "${APP_DIR}"; do
        if [ -n "$candidate" ] && [ -d "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    candidate="$(find .theos -type d -name "$APP_DIR" -print -quit 2>/dev/null || true)"
    if [ -n "$candidate" ]; then
        printf '%s\n' "$candidate"
        return 0
    fi
    return 1
}

APP="$(find_app "${1:-}")" || {
    echo "找不到 ${APP_DIR}" >&2
    echo "用法: APP_NAME=<name> $0 [/path/to/${APP_DIR}]" >&2
    exit 1
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/Payload"
cp -R "$APP" "$WORK/Payload/"

# Theos 的 obj 目录只有二进制；IPA 必须自带 Info.plist。
if [ ! -f "$WORK/Payload/$APP_DIR/Info.plist" ]; then
    cp "$(pwd)/Info.plist" "$WORK/Payload/$APP_DIR/Info.plist"
fi
if [ ! -f "$WORK/Payload/$APP_DIR/Info.plist" ]; then
    echo "IPA 缺少 Info.plist" >&2
    exit 1
fi
if [ ! -f "$WORK/Payload/$APP_DIR/$APP_NAME" ]; then
    echo "IPA 缺少可执行文件 $APP_NAME" >&2
    exit 1
fi
chmod +x "$WORK/Payload/$APP_DIR/$APP_NAME"

if command -v ldid >/dev/null 2>&1; then
    BINARY="$WORK/Payload/$APP_DIR/$APP_NAME"
    if [ -f "$BINARY" ]; then
        ENTITLEMENTS="$(pwd)/entitlements.plist"
        if [ -f "$ENTITLEMENTS" ]; then
            ldid -S"$ENTITLEMENTS" "$BINARY"
        else
            ldid -S "$BINARY"
        fi
    fi
fi

OUT="$(pwd)/$OUTPUT_IPA_NAME"
rm -f "$OUT"
(
    cd "$WORK"
    zip -qry "$OUT" Payload
)

echo "已生成: $OUT"
echo "未签名 IPA 的真机安装通常需要越狱与 AppSync Unified。"
