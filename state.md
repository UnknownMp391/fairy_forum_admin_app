# 项目交接说明（state.md）

> 写给接手的人。覆盖：系统架构、目录、关键约定、踩过的坑、如何运行、已知缺口。
> 最后更新：2026-08-17。

---

## 0. 一句话概述

**妖精论坛管理控制台** = Flutter 前端（`fairy_forum_admin_app`）+ 自研 Go 代理后端（`yjlt-admin-api-over-ouo`）→ 转发到**旧上游**（`i-am-yj-admin.youhuge.site/go-api`，React+Go 老后端）。前端只对代理说话，代理负责自有 JWT 认证、缓存、BYOK、语义统一。

```
Flutter App ── Bearer(JWT) ──> Go 代理(yjlt-admin-api-over-ouo, :8080)
                                 │ 自有认证: PG admins + argon2id + JWT
                                 │ 实体缓存: valkey + PG ouo_tokens
                                 ▼
                           旧上游(ouo) go-api
```

## 1. 三个代码库 / 文档的位置

| 东西 | 路径 |
|---|---|
| Flutter App | `~/Projects/fairy_forum_admin_app/` |
| Go 代理后端 | `~/Projects/deepseek-harness-workspace/yjlt-admin-api-over-ouo/` |
| **新后端接口文档（权威，经常更新）** | 后端目录下 `api.md`（923 行） |
| **客户端对接注意事项（必读，踩坑/最新变更）** | 后端目录下 `client-notes.md` |
| 旧上游契约（上游 API.md） | `~/tmp/API.md`（= 仓库根 `API.md`，1981 行，**别改**） |

> ⚠️ 后端 `api.md` 与 `routes/*.go` 由原作者高频更新（本会话期间从 831 行涨到 923 行）。改前端前**先重读 api.md + client-notes.md**，可能已变。

## 2. 后端（Go 代理）要点

- 框架：`github.com/UnknownMp391/serve`（v0.2.0）+ betterwr/bettermux/betterdep（都在 go mod cache）。
- **自有认证**：`POST /auth/login`（adminId+password）→ argon2id 校验 → JWT(HS256, 默认 24h)。账号存 PG `admins` 表，**不自动 seed**，用 `cmd/adminctl` 管理。
- **密码哈希**：argon2id；存量 bcrypt 登录通过后自动迁移（`auth/store.go`）。
- **两套管理员**（设计核心，见 api.md 第 4 节）：
  - `/api/admins` = **本地登录账号**（我们的 admins 表；增删/改角色/重置密码/BYOK 仅 superadmin，`cannot_delete_self`/`cannot_downgrade_self`）。
  - `/upstream/admins` = **远程（上游）管理员**（原来客户端直连的那套，代理过去）。
- **合成端点**（上游没有单条 GET，代理拼出来）：
  - `GET /api/users/{id}`（实体缓存 → search 匹配 id → 按 email 精确查询回填 → 404）
  - `GET /api/admins/{id}`、`GET /api/comments/post/{postId}/{commentId}`、`GET /api/comments/cache/{id}`、`GET /api/reports/...`（缓存类）
- **实体缓存架构**（api.md 17）：valkey `yjlt_admin_api:entity:{kind}:{id}`（60s）+ 列表聚合 `aggregateOrFetch`；写操作删精确实体键；封禁镜像 `ban:{id}` 供 PATCH is_banned 变更检测。
- **BYOK**：管理员自带上游凭据（`ups_id`/`ups_token`），PATCH `/api/admins/{id}` 管理（空串清除、缺省保留）；valkey `byok:{id}` 标记，id+token 都齐全才缓存。**BYOK 与本地登录完全无关**（只管用谁的钥匙调上游）。
- **响应规范**：成功 = 状态码 + 裸数据；分页 `{items,total,page,size}`；批量 `207 {status:{id:bool}}`；错误 `{error,message}`。
- **端口 8080**。环境变量见 api.md 18 / `debug.sh`。

### 后端已知坑（已修，别回退）
- **Content-Type bug**：`writeData`/`writeErr` 必须先设 `Content-Type: application/json` **再** `WriteStatus`（Go 在 WriteHeader 时就提交默认 text/plain）。`routes/response.go` 已修；若再出现全部响应 text/plain，查这里。
- `debug.sh` 末尾是 `exec go run .`，**不能 source**（会阻塞）。
- 运行中的实例可能是我用 nohup 起的旧代码：改后端后要 `go build -trimpath -o yjlt_admin_api_over_ouo .` 并重启（`pkill -f yjlt_admin_api_over_ouo`），日志在 `/tmp/yjlt_server.log`。

### adminctl（本地账号 CLI）
`go build -o adminctl ./cmd/adminctl` 后使用：`create / list / reset-password / set-byok / clear-byok / delete`。
**⚠️ 密码里有 `!` 等特殊字符必须加单引号**（交互式 bash 会把 `!` 当历史展开，存进去的密码会错；本会话踩过）。

## 3. 前端（Flutter）要点

- 技术栈：Riverpod 3（生成式，autoDispose 默认）+ flutter_hooks + freezed/json_serializable + dio + go_router + cached_network_image。
- **API 层全部走 freezed 模型**（`lib/api/types/*.dart`）：请求体 `XxxRequest.toJson()`、查询 `XxxQuery.toJson()`（可空字段 `includeIfNull: false` 省略）、响应 `Xxx.fromJson`。**改模型后必须** `dart run build_runner build`；生成的 `*.g.dart`/`*.freezed.dart` 已 gitignore。
- `lib/api/client.dart`：传输层 `_get/_put/_post/_patch/_delete` 返回 `dynamic`，每个方法用模型收口；`_requireMap`/`_decodeJsonMap` 兼容后端 text/plain 字符串响应；批量 → `BatchResult`（含 success/failed 计数）。
- `lib/providers/api_client.dart`：**`dioProvider` 里 `ref.keepAlive()` 是必须的**——拦截器闭包在异步完成后还要用 ref（401 清身份）。去掉会报 `Cannot use the Ref of dioProvider after it has been disposed` + `DioException [unknown]: null`。401 → `clearIdentity()`（fire-and-forget）。
- 身份：`lib/providers/identity.dart`（SharedPreferences adminId/token/role），有效性用 `GET /auth/me` 校验。
- 路由 `lib/router.dart`：`authStateListenable` + redirect；未登录拦截 `/management*`、`/settings/local-admins`、`/settings/byok`。
- 页面：
  - 管理页：用户/帖子/评论/举报/回收站/管理员(**远程**=`/upstream/admins`)/反馈/**论坛问题**(bug-reports)/头像管理/论坛账号
  - 设置页：外观 / **本地管理员**（`/settings/local-admins`，= `/api/admins`，密码+角色+BYOK）/ **BYOK 设置**（`/settings/byok`，当前账号自己的 ups_id/ups_token，token 不可回显）/ 退出登录
  - 详情页：用户=`GET /api/users/{id}`；帖子=`GET /api/posts/{id}`+CommentList；评论=`GET /api/comments/post/{postId}/{commentId}`+整帖评论筛回复；论坛问题=`GET /api/bug-reports/{id}`+状态历史(changelog)
- **排版约定（已归一）**：详情页统一 `Center > ConstrainedBox(600) > Padding(horizontal:16) > CustomScrollView > SliverPadding(垂直) > SliverToBoxAdapter`；左右边距只在 CustomScrollView 外包一层，内部不再有 `SliverToBoxAdapter(child: Padding(...))`。
- **加载态统一 `AnimatedLoadSwitch`**（`lib/components/error_ui.dart`）：把 `hasData ? content : hasError ? error : loading` 的**外层 hasData** 换成动画切换（数据态↔非数据态 250ms 淡入淡出）；**内部 `hasError ? error : loading` 保持简单三元**（不动画）。⚠️ 组件用 `dataBuilder`/`nonDataBuilder`（函数）而非 Widget——直接传 `snapshot.data!...` 会在参数构造时急切求值导致空断言崩溃（踩过）。已用于 8 个页面（post/comment 详情、feedback 详情、forum-account、admins/local-admins、byok、overview）。
- **详情页元数据行支持长按复制**（`CopyableWidget(value, copyOnLongPress, withInk)`，参考用户详情页）：post/comment/feedback/bug-reports 详情页的 `_infoRow`/`infoRow` 已接入；**排除**：`数据:` 行、本身带链接的行（作者跳转用户）、有限值行（状态/类型/性别等枚举标签）。feedback/bug-reports 用 `copyable:` 开关，post/comment 用 `copyValue:` 参数。
- **列表副标题统一多行**：全库无 `join(' · ')` 点分隔，每项信息独立一行（用户/帖子/评论/举报/回收站/论坛问题/反馈列表均如此）。
- **下拉全部 M3 `DropdownMenu`**（`initialSelection`/`dropdownMenuEntries`/`onSelected` + `expandedInsets: EdgeInsets.zero`），全库已无 `DropdownButtonFormField`。
- 测试：`test/` 共 46 个（models/identity/labels/router/api/utils）。

### 前端已知坑
- **Base URL 必须用 dart-define 指到代理**：`flutter run -d linux --dart-define=API_BASEURL=http://localhost:8080`。`lib/config.dart` 的默认值**仍是旧上游 `/go-api`**（仅兜底），不设置会打到旧后端 404。
- 头像走 `ApiClient.avatarProxyUrl` → 代理 `/api/avatar-proxy?url=`（公开，纯 302 分派）：**绝对 URL → cacher-proxy**（`http://cacherproxy.unknownmp.dpdns.org/proxy/<编码后的URL>`，字节代理+TTL 缓存+CORS，基址可用后端环境变量 `YJLT_ADMIN_API_AVATAR_CACHE_PROXY_BASE` 覆盖）；**相对路径 → 上游 ouo 的 avatar-proxy**（上游自带字节+一年缓存+CORS；不经 cacher-proxy，因其域名防护层会拦截 avatar-proxy 类代理目标）。
- `dart run` 直接跑含 Flutter import 的脚本会因 FFI 转换崩，验证要走 `flutter test`。

## 4. 本会话已完成的关键迁移（接手者须知）

1. 前端从旧契约（`{ok,data}` 包装、`/auth`+key、动词后缀路由、`users/posts/...` 分页键）全量迁移到新代理契约（裸数据、`/auth/login`+password、动词化、`items`、207 批量、`is_resolved`）。
2. 高危操作（删用户/批量删/头像替换恢复）不再让前端传 `admin_id/admin_key/确认词`——后端代填；批量删用户前端需提供每项 `user_name/user_email`（逐项身份核验由后端做）。
3. 详情页 search hack 清零：用户/评论详情都改用后端合成/组合端点。
4. 管理员体系拆分：现有"管理员"页 = 远程管理员；新增"本地管理员"页（密码/BYOK）；设置页新增 BYOK 配置。
5. 后端修复：响应 Content-Type（application/json）、writeErr 漏网、登录 401 排查（密码被 shell 展开/哈希被外部清空，已重置）。
6. **BYOK 权限分层适配**（client-notes 轮）：无 BYOK 只读（写操作 403 `no_byok`）；拦截器 401 精细化（仅 `unauthorized` 清身份，BYOK 上游 401 不清登录态只提示）；`showErrorSnackBar` 全局识别 `no_byok` → SnackBar 动作变"配置 BYOK"；forum-account 页 no_byok 引导视图。
7. **上游 v1.7.0 功能适配**：反馈白名单收紧（5 type/4 status）、封禁 reason（单条+批量弹原因框）、封禁历史（用户详情区块）、附件下载（反馈详情，dio.download+file_selector）、**论坛问题模块**（列表页无按钮点击进详情、详情页含状态历史/变更状态/删除、client 方法齐备）。
8. **UI 归一化**：加载态 `AnimatedLoadSwitch`（8 页）、详情页元数据长按复制（排除 数据:/链接/有限值）、列表副标题多行化（join(' · ') 清零）。
9. **回收站用户镜像兜底**（修复"用户回收站 error decoding key original_user.gender"）：旧上游 `GET /api/trash/users` 及其详情因 MongoDB `original_user.gender` 字符串无法解码为 int，对任何含此类文档的结果集 500（空结果反而成功）。代理在自有 PG 建 `trash_users` 镜像表：删除用户时（单删/批删）删前快照完整用户；首次列表回退时从上游 `trash/posts` 回填历史被删用户（id/name/avatar/删除信息）；列表/详情在**上游 500 或空结果**时自动回退镜像（`routes/trash_users_mirror.go`）。前端零改动。
10. **批量恢复 kind 归一**（顺带修复）：上游批量恢复要求单数 kind（post/comment/user），代理对外用复数，此前批量恢复所有类型都 400；已在 `upstream.BatchRestoreTrash` 归一。
11. **头像代理 302 分派**：`/api/avatar-proxy` 改为按 URL 形态分派——**绝对 URL → cacher-proxy**（字节代理+TTL 缓存+CORS，恢复"代理字节+缓存"能力）、**相对路径 → 上游 ouo 的 avatar-proxy**（保持原链路，上游自带字节+一年缓存+CORS）。cacher-proxy 域名防护层会拦截 `avatar-proxy?url=` 代理目标，故相对路径不走 cacher-proxy（456 属上游问题，已规避）。
12. **Sentry 捕获错误上报 hook**：页面加载/操作错误（"复制详情"那些）都是 catch 捕获的"已处理"错误，Sentry 默认不收集——新增 `lib/utils/sentry_reporter.dart` 的 `reportError()`，挂到统一入口：`PagedListView.load()`（所有列表页）、`LoadErrorView`+`showErrorSnackBar`（error_ui.dart）、overview 统计页、user 详情封禁历史/帖子、bug-report 状态历史。规则：**指纹去重**（runtimeType+errorCode+message，5 分钟窗口）、**排除 `no_byok`/`invalid_credentials`**（预期业务态）、Sentry 未启用时 no-op；上报带 `ui_context`/`fingerprint` 标签。顺带删除了 main.dart 里那条启动样本异常（TODO 遗留）。
13. **错误 UI 全面统一**（全部"重试+复制详情"化）：新增区块级 `SectionErrorView`（error_ui.dart），把 4 处裸 `Text('xxx失败: ...')`（头像扫描、bug-report 状态历史、用户封禁历史、用户帖子）统一成 错误+重试+复制+Sentry 上报；overview 统计页与 go_router 错误页（router.dart errorBuilder）改用 `LoadErrorView`（原"返回首页"改为统一"重试"）。现在全库错误展示只剩 4 类统一组件：`LoadErrorView`（整页 11 处）/ `SectionErrorView`（区块 4 处）/ `PagedListView`（列表 9 处）/ `showErrorSnackBar`（操作 42 处），无裸错误 Text。
14. **Sentry 调试符号/源码映射上传**（发版时）：`sentry_dart_plugin ^3.4.0` + 项目根 `sentry.properties`（auth_token，已在 .gitignore）+ 已装 sentry-cli（3.6.2，pnpm 全局）。发版流程（`release_publish.sh`）：web 构建加 `--source-maps`（产出 `main.dart.js.map`/`main.dart.wasm.map`）、apk 构建加 `--split-debug-info=build/symbols`（产出 `*.symbols`），最后 `dart run sentry_dart_plugin --sentry-define=bin_path=$SENTRY_CLI` 上传。已实测端到端成功：source maps 上传、release finalize、git commit 关联。注意：插件会因 sentry-cli 版本与期望 2.58.6 不一致打 checksum 警告（无害）。
15. **版本号 build_runner 注入 + 发版自动递增**：`lib/version.g.dart` 由自定义 builder（`lib/builders/version_builder.dart`，build.yaml 注册，输入为 `lib/$lib$` 占位符）从 pubspec.yaml 生成 `appVersion`/`appRelease`（name@version+buildNumber）；`main.dart` 的 `options.release = appRelease` 不再硬编码。`bumpbuild.sh` 读取 pubspec version、buildNumber +1 写回；`release_publish.sh` 开头先跑 bumpbuild 再 build_runner，实现每次发版自动 +1。踩坑记录：① 生成输出需用 `$lib$` 占位符（真实 .dart 输入会与 combining_builder 的 `.g.dart` 输出冲突）；② 占位符 `lib/$lib$` 与 `pubspec.yaml` 必须列入 `targets.$default.sources`；③ Dart RegExp 不支持 `(?m)` 内联标志，要用 `multiLine: true`；④ builder 文件在 lib/ 下 import dev 依赖需 `ignore_for_file: depend_on_referenced_packages`。

## 5. 已知缺口 / 待办（尚未解决）

1. **JWT 无状态，无法吊销**：删除/重置管理员密钥不会让已签发 JWT 失效（默认 24h 内仍可用）。旧后端可吊销 token。要彻底解决需引入版本号/黑名单。
2. `API_BASEURL` 默认值仍是旧上游地址；部署（`deploy_cfpages.sh`，web+wasm）需注入新代理地址。
3. 头像代理是 302 直跳（旧版是代理字节+一年缓存），上游不可达时相对路径头像会断（行为差异，非 bug）。
4. **批量操作 UI 未全覆盖**：仅论坛问题做了批量（处理/删除）；用户封禁/解封、帖子/评论删除等批量接口在 client 层就绪（`batchDelete*`/`batchUpdate*` → `BatchResult`），UI 批量入口可复用。
5. **角色模型未定**（client-notes 4）：除 `/api/admins` 外所有接口不区分 admin/superadmin，只有 BYOK 层门禁。若产品预期"admin=受限审核员"需后端加 `requireSuperadmin`——与后端确认后再动。
6. **无 BYOK 只读**（client-notes 1.4，已适配前端）：无 BYOK 管理员只能 GET，所有管理写操作 403 `no_byok`；前端已做兜底提示 + 论坛账号页引导视图 + 自助 BYOK 入口。前端无法可靠预知"是否配了 BYOK"（后端只回 ups_id 不回 ups_token），因此采用"逐操作捕获 403 no_byok"策略而非隐藏按钮。
7. **实例选择**（client-notes 5）：`:8080`（dev 密钥）与 `:12437`（release_run.sh 密钥）两个实例 JWT 不通用，前端固定连一个；换实例需重新登录。
8. 上游默认凭据 `UnknownMp` 角色是 **admin**（非 superadmin）——上游管理员增删改会透传 403；要用上游 superadmin 能力需 BYOK 配 Kali/Yoyo 等账号（与后端确认账号）。
9. **`POST /upstream/admins/notify-changelog`**：会**真实发邮件**，前端未做入口（谨慎使用，勿误触）。
10. **备注**：`UnknownMp` 本地账号现已配置 BYOK（在本应用设置页配置过）——无 BYOK 的测试需要另建账号验证。
11. **回收站用户恢复受限**（上游解码缺陷未修前）：镜像条目（ID 为 `tu_*`/`hist_*`，非上游 ObjectID）无法通过上游恢复——单条恢复返回 `502 upstream_trash_broken`，批量恢复逐项 false；要真正恢复需上游侧修复 gender 解码及存量数据。另：历史回填条目缺 email/gender/age 等字段（上游 trash_users 文档不可读，只能从 trash_posts 重构）；恢复帖子若其用户已删会因上游 FK 约束失败（上游行为）。
12. **实例重启脚本**：后端仓库 `restart_instances.sh`（dev :8080 + release :12437，同一二进制，两套 JWT 密钥）；改后端后 `go build -trimpath -ldflags="-s -w" -o yjlt_admin_api_over_ouo .` 再跑脚本。⚠️ 不要用 `pkill -f yjlt_admin_api_over_ouo` 清理（会匹配到命令行自身），按 PID kill 或让脚本处理。

## 6. 快速上手

```bash
# 后端
cd ~/Projects/deepseek-harness-workspace/yjlt-admin-api-over-ouo
./debug.sh                       # 或先 go build 再 nohup ./yjlt_admin_api_over_ouo
./adminctl create -id MyAdmin -password 'MyPass!' -role superadmin   # 建本地登录账号

# 前端
cd ~/Projects/fairy_forum_admin_app
flutter pub get
dart run build_runner build      # 改过 freezed 模型后
flutter run -d linux --dart-define=API_BASEURL=http://localhost:8080

# 验证（后端在跑时）
flutter test test/e2e_local_test.dart   # 临时 e2e（需自行写/恢复）
flutter analyze && flutter test
```
