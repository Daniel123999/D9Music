#!/bin/bash
set -e

APP_NAME="FuoEvolve9"
WORK_DIR="$(pwd)"
THEOS_DIR="$WORK_DIR/.theos"

APP_DIR="$THEOS_DIR/obj/$APP_NAME.app"
if [ ! -d "$APP_DIR" ]; then
    echo "App not found at $APP_DIR"
    exit 1
fi

rm -rf Payload
mkdir -p Payload
cp -R "$APP_DIR" Payload/
if [ -f "Resources/Info.plist" ]; then
    cp "Resources/Info.plist" Payload/$APP_NAME.app/Info.plist
fi
zip -r "$APP_NAME.ipa" Payload
rm -rf Payload
echo "Created $APP_NAME.ipa"
