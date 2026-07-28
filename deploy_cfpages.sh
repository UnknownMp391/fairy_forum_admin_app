#!/bin/sh

flutter build web --release --wasm && cp -rv web_static/* build/web/ && wrangler pages deploy --project-name fairy-forum-admin-app ./build/web/
