#!/bin/sh
set -e

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build web --release --wasm --no-web-resources-cdn && cp -rv web_static/* build/web/ && wrangler pages deploy --project-name fairy-forum-admin-app ./build/web/
