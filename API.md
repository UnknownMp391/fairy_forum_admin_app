# 论坛管理后台 API 文档

> **版本**: v1.0  
> **生成时间**: 2026-08-14  
> **基础地址**: `http://localhost:8080`  
> **数据格式**: JSON  
> **编码**: UTF-8

---

## 目录

- [1. 概述](#1-概述)
- [2. 认证机制](#2-认证机制)
- [3. 认证接口](#3-认证接口)
- [4. 管理员管理](#4-管理员管理)
- [5. 用户管理](#5-用户管理)
- [6. 帖子管理](#6-帖子管理)
- [7. 评论管理](#7-评论管理)
- [8. 举报管理](#8-举报管理)
- [9. 反馈管理](#9-反馈管理)
- [10. 论坛账号](#10-论坛账号)
- [11. 回收站](#11-回收站)
- [12. 头像代理](#12-头像代理)
- [13. 统计数据](#13-统计数据)
- [14. 健康检查](#14-健康检查)
- [15. 错误码汇总](#15-错误码汇总)
- [16. 数据模型参考](#16-数据模型参考)

---

## 1. 概述

### 1.1 架构简介

论坛管理后台采用 React + Go 的 Monorepo 架构，后端使用标准库 `net/http`（Go 1.22+ method+pattern 路由），双数据库分离：

- **MongoDB** — 管理数据（管理员、Token、回收站、反馈、论坛账号绑定）
- **PostgreSQL** — 业务数据（用户、帖子、评论、举报）

### 1.2 路由统计

| 模块 | 接口数 | 认证 |
|------|--------|------|
| 认证 | 3 | 部分公开 |
| 管理员管理 | 7 | ✅ 全保护 |
| 用户管理 | 15 | ✅ 全保护 |
| 帖子管理 | 8 | ✅ 全保护 |
| 评论管理 | 3 | ✅ 全保护 |
| 举报管理 | 4 | ✅ 全保护 |
| 反馈管理 | 7 | ✅ 全保护 |
| 论坛账号 | 3 | ✅ 全保护 |
| 回收站 | 10 | ✅ 全保护 |
| 头像代理 | 3 | 部分公开 |
| 统计数据 | 1 | ✅ 全保护 |
| 健康检查 | 1 | ❌ 公开 |
| **合计** | **65** | — |

### 1.3 CORS

所有路由均配置 CORS：

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

OPTIONS 预检请求直接返回 204。

---

## 2. 认证机制

### 2.1 Bearer Token

除公开路由外，所有 `/api/*` 请求需在 Header 中携带 Token：

```
Authorization: Bearer <token>
```

### 2.2 Token 生命周期

| 属性 | 值 |
|------|-----|
| 生成方式 | `crypto/rand` 32 字节 → hex 编码（64 位） |
| 有效期 | 默认 7 天（`TOKEN_EXPIRY` 环境变量，Go duration 格式） |
| 存储 | MongoDB `tokens` 集合 |
| 过期策略 | 应用层主动删除 + TTL 索引双保险（`expireAfterSeconds: 0`） |

### 2.3 登录限流

`POST /auth` 路由额外包裹 `RateLimitMiddleware`：

- **阈值**: 同一 IP 连续失败 3 次 → 锁定 1 小时
- **IP 提取**: 仅当 `RemoteAddr` 属于受信代理 CIDR（`TRUSTED_PROXIES` 配置）时才信任 `X-Forwarded-For` / `X-Real-IP`，否则直接用 TCP 对端地址
- **响应**: 锁定期间返回 `429`，携带 `retryAfterSeconds` 字段

### 2.4 统一响应格式

**成功响应**:

```json
{ "ok": true, "data": { ... } }
```

**错误响应**:

```json
{ "ok": false, "error": "<error_code>", "message": "<描述>" }
```

---

## 3. 认证接口

### 3.1 登录

```
POST /auth
```

**中间件**: `CORS` + `RateLimitMiddleware`  
**认证**: ❌ 无需认证

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `adminId` | string | ✅ | 管理员 ID |
| `key` | string | ✅ | 密钥 |

**成功响应** (`200`):

```json
{
  "ok": true,
  "token": "a1b2c3d4e5f6...",
  "role": "superadmin",
  "expiresAt": "2026-08-21T19:30:00+08:00"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `token` | string | 64 位 hex 会话 token |
| `role` | string | `admin` / `superadmin` |
| `expiresAt` | string | ISO8601 过期时间 |

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `invalid request body` |
| 400 | `bad_request` | `adminId and key are required` |
| 429 | `rate_limited` | `登录失败次数过多，请 1 小时后重试` |
| 401 | `invalid_credentials` | `管理员 ID 或密钥错误` |
| 500 | `internal_error` | `服务器内部错误` / `创建 token 失败` |

---

### 3.2 登出

```
POST /auth/logout
```

**认证**: ✅ Bearer Token

**请求**: 无 body，依赖 `Authorization` 头。

**成功响应** (`200`):

```json
{ "ok": true, "message": "logged out" }
```

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 401 | `unauthorized` | `missing authorization header` |
| 401 | `unauthorized` | `invalid authorization format` |
| 401 | `unauthorized` | `invalid or expired token` |

---

### 3.3 获取当前管理员信息

```
GET /auth/me
```

**认证**: ✅ Bearer Token

**请求**: 无参数。

**成功响应** (`200`):

```json
{
  "ok": true,
  "adminId": "admin001",
  "role": "superadmin"
}
```

---

## 4. 管理员管理

> 所有接口均需 Bearer Token 认证。角色操作（创建/删除/改角色/重置密钥）仅限 `superadmin`。

### 4.1 列出所有管理员

```
GET /api/admins
```

**权限**: 任意已认证管理员  
**排序**: 按 `created_at` 降序

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": [
    {
      "admin_id": "admin001",
      "role": "superadmin",
      "created_at": "2026-07-01T00:00:00+08:00",
      "last_login_time": "2026-08-14T19:00:00+08:00"
    }
  ]
}
```

---

### 4.2 创建管理员

```
POST /api/admins
```

**权限**: 仅 `superadmin`

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `admin_id` | string | ✅ | 新管理员 ID |
| `key` | string | ✅ | 密钥 |
| `role` | string | ❌ | `admin`（默认）/ `superadmin` |

**成功响应** (`200`): `{ "ok": true }`

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 403 | `forbidden` | `仅超级管理员可执行此操作` |
| 400 | `bad_request` | `请求格式错误` |
| 400 | `bad_request` | `管理员 ID 和密钥不能为空` |
| 400 | `bad_request` | `无效的角色` |
| 409 | `admin_id_taken` | `管理员 ID 已被使用` |

---

### 4.3 删除管理员

```
DELETE /api/admins/{id}
```

**权限**: 仅 `superadmin`  
**路径参数**: `id` — 目标管理员 ID

**限制**: ❌ 禁止删除自己；删除后同时吊销该管理员全部 Token。

**成功响应** (`200`): `{ "ok": true }`

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `缺少管理员 ID` |
| 403 | `forbidden` | `仅超级管理员可执行此操作` |
| 403 | `cannot_delete_self` | `不能删除自己的账号` |
| 404 | `not_found` | `管理员不存在` |

---

### 4.4 更新管理员角色

```
PUT /api/admins/{id}/role
```

**权限**: 仅 `superadmin`

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `role` | string | ✅ | `admin` / `superadmin` |

**限制**: ❌ 禁止降级自己；变更后吊销该管理员全部 Token（强制重新登录）。

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 403 | `forbidden` | `仅超级管理员可执行此操作` |
| 400 | `bad_request` | `缺少管理员 ID` |
| 400 | `bad_request` | `请求格式错误` |
| 400 | `bad_request` | `无效的角色` |
| 403 | `cannot_downgrade_self` | `不能降级自己的角色` |
| 404 | `not_found` | `管理员不存在` |

---

### 4.5 重置管理员密钥

```
PUT /api/admins/{id}/key
```

**权限**: 仅 `superadmin`

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `key` | string | ✅ | 新密钥 |

**注意**: 重置密钥不会吊销现有 Token，被重置者仍可用旧 Token 直到过期。

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `缺少管理员 ID` |
| 400 | `bad_request` | `密钥不能为空` |
| 403 | `forbidden` | `仅超级管理员可执行此操作` |
| 404 | `not_found` | `管理员不存在` |

---

### 4.6 批量删除管理员

```
POST /api/admins/batch-delete
```

**权限**: 仅 `superadmin`

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `admin_ids` | string[] | ✅ | 管理员 ID 列表（≤200） |

**成功响应** (`200`):

```json
{ "ok": true, "data": { "failed": [{ "id": "admin002", "message": "..." }] } }
```

**限制**: ❌ 禁止删除自己；删除后同时吊销目标管理员全部 Token。

---

### 4.7 批量更新管理员角色

```
POST /api/admins/batch-role
```

**权限**: 仅 `superadmin`

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `admin_ids` | string[] | ✅ | 管理员 ID 列表（≤200） |
| `role` | string | ✅ | `admin` / `superadmin` |

**成功响应** (`200`):

```json
{ "ok": true, "data": { "failed": [{ "id": "admin002", "message": "..." }] } }
```

> ⚠️ 禁止降级自己；变更后吊销目标管理员全部 Token。

---

## 5. 用户管理

> 所有接口均需 Bearer Token 认证。

### 5.1 用户列表 / 精确查询

```
GET /api/users
```

**Query 参数**:

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `key` | string | ❌ | — | 精确查询字段名（需配合 `value`） |
| `value` | string | ❌ | — | 精确查询值（仅传 `key` 不传 `value` 返回 400） |
| `page` | int | ❌ | 1 | 页码 |
| `size` | int | ❌ | 20 | 每页条数（超过 100 时回退为默认值 20） |

**排序**: 按 `created_at` 降序（`NULLS LAST`）

**允许的 `key`**: `name`, `email`, `avatar`, `gender`, `age`, `intro`, `vip`, `password`, `is_banned`

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": {
    "users": [
      {
        "id": "42",
        "name": "幽悠",
        "email": "339202808@qq.com",
        "avatar": "avatars/42.png",
        "gender": "男",
        "age": 17,
        "intro": "悠悠望望",
        "vip": 0,
        "is_banned": 0,
        "last_login": "2026-08-14T10:00:00+08:00",
        "created_at": "2025-07-01T00:00:00+08:00"
      }
    ],
    "total": 100,
    "page": 1,
    "size": 20
  }
}
```

> ⚠️ `password` 字段使用 `json:"-"` 标签，不会出现在响应中。

---

### 5.2 模糊搜索用户

```
GET /api/users/search
```

**Query 参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `q` | string | ✅ | 搜索关键词 |

**搜索范围**: `id ILIKE` / `name ILIKE` / `email ILIKE`（最多返回 50 条）

**成功响应** (`200`):

```json
{ "ok": true, "data": [{ "id": "...", "name": "...", "email": "..." }] }
```

---

### 5.3 更新用户字段

```
PUT /api/users/{id}
```

**路径参数**: `id` — 用户 ID

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `key` | string | ✅ | 字段名 |
| `value` | string | ✅ | 新值 |

**允许的字段**: `name`, `email`, `avatar`, `gender`, `age`, `intro`, `vip`, `password`, `is_banned`

> ⚠️ 该接口可修改 `password` 和 `is_banned`，**无二次认证、无确认词**。

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `无效的请求体` |
| 400 | `bad_request` | `缺少 key 字段` |
| 400 | `bad_request` | `不允许的更新字段` |
| 400 | `bad_request` | `用户不存在` |

---

### 5.4 封禁用户

```
PUT /api/users/{id}/ban
```

**路径参数**: `id` — 用户 ID  
**请求体**: 无

> ⚠️ 仅认证即可封禁，无二次认证、无确认词。

**成功响应** (`200`): `{ "ok": true }`

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `缺少用户 ID` |
| 400 | `bad_request` | `用户不存在` |

---

### 5.5 解封用户

```
PUT /api/users/{id}/unban
```

**路径参数**: `id` — 用户 ID  
**请求体**: 无

> ⚠️ 同封禁，无二次认证。

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `缺少用户 ID` |
| 400 | `bad_request` | `用户不存在` |

---

### 5.6 用户统计

```
GET /api/users/{id}/stats
```

**成功响应** (`200`):

```json
{ "ok": true, "data": { "post_count": 10, "comment_count": 50 } }
```

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `缺少用户 ID` |

---

### 5.7 用户评论列表

```
GET /api/users/{id}/comments
```

**Query 参数**: `page`（默认 1）、`size`（默认 20）

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `缺少用户 ID` |

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": {
    "comments": [
      {
        "comment_id": "uuid",
        "content": "评论内容",
        "post_id": "1",
        "post_title": "帖子标题",
        "post_category": "综合",
        "likes": 5,
        "created_at": "2026-08-14T10:00:00+08:00"
      }
    ],
    "total": 50,
    "page": 1,
    "size": 20
  }
}
```

---

### 5.8 用户帖子列表

```
GET /api/users/{id}/posts
```

**Query 参数**: `page`（默认 1）、`size`（默认 20）

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `缺少用户 ID` |

**成功响应**: 同帖子列表结构 `{ posts: Post[], total, page, size }`

---

### 5.9 按域名扫描头像

```
GET /api/users/avatar-scan
```

**Query 参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `domain` | string | ✅ | 要扫描的头像域名 |

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `缺少 domain 参数` |

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": {
    "total": 5,
    "users": [
      { "id": "42", "name": "幽悠", "avatar": "https://old-cdn.com/42.png" }
    ]
  }
}
```

---

### 5.10 按域名替换头像 ⚠️ 高危

```
POST /api/users/avatar-replace
```

**校验链**: Token → `admin_id` 匹配 → `VerifyCredentials` 二次验密 → `confirm == "true-ouo"`

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `domain` | string | ✅ | 目标域名 |
| `avatars` | string[] | ✅ | 替换头像池 |
| `admin_id` | string | ✅ | 必须等于当前认证 admin |
| `admin_key` | string | ✅ | 二次验密 |
| `confirm` | string | ✅ | 必须为 `"true-ouo"` |

**成功响应** (`200`):

```json
{ "ok": true, "data": { "replaced": 5 } }
```

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `无效的请求体` |
| 400 | `bad_request` | `缺少 domain 字段` |
| 400 | `bad_request` | `头像列表不能为空` |
| 403 | `forbidden` | `管理员身份验证失败` |
| 403 | `forbidden` | `请提供管理员密钥` |
| 403 | `forbidden` | `管理员密钥错误` |
| 403 | `forbidden` | `未完成确认` |

> 替换逻辑：事务内遍历匹配用户，从 `avatars` 池中**随机**选取一个替换。

---

### 5.11 恢复头像 ⚠️ 高危

```
POST /api/users/avatar-restore
```

**校验链**: 同 5.10

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `items` | array | ✅ | 恢复项列表 |
| `admin_id` | string | ✅ | 必须等于当前认证 admin |
| `admin_key` | string | ✅ | 二次验密 |
| `confirm` | string | ✅ | 必须为 `"true-ouo"` |

**`items[]` 子项**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string | 用户 ID |
| `name` | string | 用户名 |
| `avatar` | string | 恢复目标头像 |

**成功响应** (`200`):

```json
{ "ok": true, "data": { "restored": 3, "skipped": 2, "total": 5 } }
```

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `无效的请求体` |
| 400 | `bad_request` | `恢复项列表不能为空` |
| 403 | `forbidden` | `管理员身份验证失败` |
| 403 | `forbidden` | `请提供管理员密钥` |
| 403 | `forbidden` | `管理员密钥错误` |
| 403 | `forbidden` | `未完成确认` |

> 严格校验 `id` + `name` 匹配才恢复，不匹配计入 `skipped`。

---

### 5.12 删除用户 ⚠️ 最高危

```
DELETE /api/users/{id}
```

**校验链（5 重）**: Token → `admin_id` 匹配 → `VerifyCredentials` → `confirm_step1 == "true-ouo"` → `confirm_step2 == "true-ouo"` → `user_name`/`user_email` 与数据库严格比对

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `reason` | string | ❌ | 删除原因，默认 `"用户删除联动"` |
| `user_name` | string | ✅ | 数据库中的用户名（严格比对） |
| `user_email` | string | ✅ | 数据库中的邮箱（严格比对） |
| `confirm_step1` | string | ✅ | `"true-ouo"` |
| `confirm_step2` | string | ✅ | `"true-ouo"` |
| `admin_id` | string | ✅ | 必须等于当前认证 admin |
| `admin_key` | string | ✅ | 二次验密 |

**联动删除流程**:
1. 查用户信息构建快照
2. 删除用户所有帖子（联动删除评论到回收站）
3. 删除用户在他人帖子下的评论
4. 写 MongoDB `trash_users` 回收站
5. 解绑 `forum_accounts`
6. 从 PostgreSQL `DELETE FROM users`

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `缺少用户 ID` |
| 400 | `bad_request` | `无效的请求体` |
| 403 | `forbidden` | `管理员身份验证失败` |
| 403 | `forbidden` | `请提供管理员密钥` |
| 403 | `forbidden` | `管理员密钥错误` |
| 403 | `forbidden` | `未完成第一步确认` |
| 403 | `forbidden` | `未完成第二步确认` |
| 403 | `forbidden` | `用户名验证失败` |
| 403 | `forbidden` | `邮箱验证失败` |
| 404 | `not_found` | `用户不存在` |

---

### 5.13 批量封禁

```
POST /api/users/batch-ban
```

**请求体**: `{ "user_ids": ["id1", "id2"] }`  
**上限**: 200 条/次  
**二次认证**: ❌ 无

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `无效的请求体` |
| 400 | `bad_request` | `ID 列表不能为空` |
| 400 | `bad_request` | `单次最多操作 200 条` |

---

### 5.14 批量解封

```
POST /api/users/batch-unban
```

**请求体**: `{ "user_ids": ["id1", "id2"] }`  
**上限**: 200 条/次

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `无效的请求体` |
| 400 | `bad_request` | `ID 列表不能为空` |
| 400 | `bad_request` | `单次最多操作 200 条` |

---

### 5.15 批量删除

```
POST /api/users/batch-delete
```

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `user_ids` | string[] | ✅ | 用户 ID 列表（≤200） |
| `reason` | string | ❌ | 删除原因 |
| `admin_id` | string | ✅ | 必须等于当前认证 admin |
| `admin_key` | string | ✅ | 二次验密 |
| `confirm` | string | ✅ | `"true-ouo"` |

> ⚠️ 批量删除缺少用户身份核验（不校验 user_name/user_email），可能误删。

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `无效的请求体` |
| 400 | `bad_request` | `ID 列表不能为空` |
| 400 | `bad_request` | `单次最多操作 200 条` |
| 403 | `forbidden` | `管理员身份验证失败` |
| 403 | `forbidden` | `请提供管理员密钥` |
| 403 | `forbidden` | `管理员密钥错误` |
| 403 | `forbidden` | `未完成确认` |

---

## 6. 帖子管理

> 所有接口均需 Bearer Token 认证。

### 6.1 帖子列表

```
GET /api/posts
```

**Query 参数**:

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `page` | int | ❌ | 1 | 页码 |
| `size` | int | ❌ | 20 | 每页条数（超过 100 时回退为默认值 20） |
| `category` | string | ❌ | — | 分类筛选 |
| `q` | string | ❌ | — | 搜索（匹配 id / title ILIKE / content ILIKE） |

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": {
    "posts": [
      {
        "id": "1",
        "user_id": "42",
        "title": "帖子标题",
        "content": "帖子内容",
        "category": "综合",
        "likes": 10,
        "views": 100,
        "status": 1,
        "user_name": "幽悠",
        "user_avatar": "avatars/42.png",
        "created_at": "2026-08-14T10:00:00+08:00",
        "updated_at": "2026-08-14T10:00:00+08:00"
      }
    ],
    "total": 50,
    "page": 1,
    "size": 20
  }
}
```

---

### 6.2 搜索帖子

```
GET /api/posts/search
```

**Query 参数**: `q`（**必填**）、`page`、`size`

**错误码**: `400 bad_request` — `缺少 q 参数`

---

### 6.3 帖子详情

```
GET /api/posts/{id}
```

**路径参数**: `id` — 帖子 ID

**错误码**: `404 not_found` — `帖子不存在`

---

### 6.4 删除帖子

```
PUT /api/posts/{id}/delete
```

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `reason` | string | ❌ | 删除原因，默认 `"管理员手动删除"` |

**删除流程**: 帖子 → MongoDB `trash_posts` → 评论 → MongoDB `trash_comments` → PG 删除评论 → PG 删除帖子。

---

### 6.5 批量删除帖子

```
POST /api/posts/batch-delete
```

**请求体**: `{ "post_ids": ["id1"], "reason": "批量删除原因" }`  
**上限**: 200 条/次

**成功响应** (`200`):

```json
{ "ok": true, "data": { "failed": [{ "id": "id1", "message": "..." }] } }
```

> `failed` 为空数组表示全部成功。单项失败不中断整体。

---

### 6.6 帖子评论列表

```
GET /api/posts/{id}/comments
```

**路径参数**: `id` — 帖子 ID

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": [
    {
      "id": "uuid",
      "content": "评论内容",
      "user_name": "幽悠",
      "user_id": "42",
      "user_avatar": "avatars/42.png",
      "likes": 5,
      "status": 1,
      "created_at": "2026-08-14T10:00:00+08:00"
    }
  ]
}
```

> ⚠️ `parent_id` 无回复时字段被 `omitempty` 省略（非 `null`）；`post_id` 由路径参数可知，响应中不包含。

---

### 6.7 创建评论 🔗 需绑定论坛账号

```
POST /api/posts/{id}/comments
```

**前置条件**: 必须已绑定论坛账号（`forum_accounts` 集合有记录），否则返回 `403 no_forum_account`。

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `content` | string | ✅ | 评论内容（trim 后非空，≤1000 字） |
| `parent_id` | string | ❌ | 被回复评论 ID（必须属于同一帖子） |

**成功响应** (`201`):

```json
{
  "ok": true,
  "data": {
    "id": "uuid",
    "content": "评论内容",
    "user_name": "幽悠",
    "user_id": "42",
    "user_avatar": "avatars/42.png",
    "likes": 0,
    "status": 1,
    "created_at": "2026-08-14T10:00:00+08:00"
  }
}
```

> ⚠️ `parent_id` 无回复时字段被 `omitempty` 省略（非 `null`）；`post_id` 由路径参数可知，响应中不包含。

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 401 | `unauthorized` | `未认证` |
| 400 | `bad_request` | `评论内容不能为空` / `评论内容不能超过1000字` |
| 400 | `bad_request` | `被回复的评论不存在` / `被回复的评论不属于该帖子` |
| 403 | `no_forum_account` | `请先关联论坛账号` |

---

### 6.8 举报帖子 🔗 需绑定论坛账号

```
POST /api/posts/{id}/report
```

**前置条件**: 必须已绑定论坛账号。举报以绑定的论坛用户身份发起（`reporter_id` = 论坛用户 ID）。

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `reason` | string | ✅ | 举报原因 |
| `detail` | string | ❌ | 补充说明 |

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `no_forum_account` | `请先关联论坛账号` |
| 404 | `not_found` | `帖子不存在` |

> ⚠️ `post_reports.id` 通过 `COALESCE(MAX(id), 0) + 1` 手动自增，无 sequence，并发场景可能冲突。

---

## 7. 评论管理

### 7.1 删除评论

```
PUT /api/comments/{id}/delete
```

**请求体**: `{ "reason": "违规评论" }`（可选）

---

### 7.2 批量删除评论

```
POST /api/comments/batch-delete
```

**请求体**: `{ "comment_ids": ["c1"], "reason": "批量删除原因" }`  
**上限**: 200 条/次

---

### 7.3 评论管理列表

```
GET /api/comments
```

**Query 参数**: `page`、`size`、`q`（搜索 content ILIKE 或 user_name ILIKE）、`post_id`

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "content": "评论内容",
        "user_name": "幽悠",
        "user_id": "42",
        "user_avatar": "avatars/42.png",
        "likes": 5,
        "parent_id": null,
        "post_id": "1",
        "status": 1,
        "created_at": "2026-08-14T10:00:00+08:00",
        "post_title": "帖子标题",
        "post_category": "综合"
      }
    ],
    "total": 50,
    "page": 1,
    "size": 20
  }
}
```

---

## 8. 举报管理

### 8.1 举报列表

```
GET /api/reports
```

**Query 参数**: `status`（0=待处理, 1=已处理；非法值将被静默忽略，返回全量数据）、`page`、`size`

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": {
    "reports": [
      {
        "id": "1",
        "post_id": "1",
        "post_title": "帖子标题",
        "reporter_id": "42",
        "reporter_name": "幽悠",
        "reason": "垃圾广告",
        "detail": "包含违法链接",
        "status": 0,
        "created_at": "2026-08-14T10:00:00+08:00"
      }
    ],
    "total": 10,
    "page": 1,
    "size": 20
  }
}
```

---

### 8.2 处理举报

```
PUT /api/reports/{id}/resolve
```

**路径参数**: `id` — 举报 ID（整数）  
**请求体**: 无  
**行为**: 幂等，重复处理不报错。执行 `UPDATE post_reports SET status = '1'`。

---

### 8.3 举报联动删帖

```
POST /api/reports/{id}/delete-post
```

**联动逻辑**:
1. 查举报单 → 取 `post_id` 和 `reason`
2. 调用 `DeletePost` 将帖子移入回收站（删除原因 = `"举报处理：{reason}"`）
3. 帖子下所有评论同步移入回收站
4. 将举报标记为 `status = 1`（已处理）

---

### 8.4 批量处理举报

```
POST /api/reports/batch-resolve
```

**请求体**: `{ "report_ids": [1, 2, 3] }`  
**上限**: 200 条/次

**成功响应** (`200`):

```json
{ "ok": true, "data": { "failed": [{ "id": "5", "message": "举报不存在" }] } }
```

---

## 9. 反馈管理

### 9.1 创建反馈

```
POST /api/feedback
```

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | string | ✅ | 反馈类型 |
| `title` | string | ✅ | 标题 |
| `content` | string | ✅ | 内容 |

**有效 `type` 值** (16 种): `bug`, `feature`, `ux`, `performance`, `security`, `documentation`, `design`, `accessibility`, `dependency`, `refactor`, `question`, `other`, `enhancement`, `compatibility`, `crash`, `regression`

**成功响应** (`201`):

```json
{
  "ok": true,
  "data": {
    "id": "507f1f77bcf86cd799439011",
    "type": "bug",
    "title": "标题",
    "content": "内容",
    "attachmentIds": [],
    "reporterId": "admin001",
    "status": "pending",
    "handlerId": "",
    "statusHistory": [
      {
        "fromStatus": "",
        "toStatus": "pending",
        "handlerId": "admin001",
        "note": "创建反馈",
        "createdAt": "2026-08-14T19:30:00+08:00"
      }
    ],
    "createdAt": "2026-08-14T19:30:00+08:00",
    "updatedAt": "2026-08-14T19:30:00+08:00"
  }
}
```

---

### 9.2 反馈列表

```
GET /api/feedback
```

**Query 参数**: `status`（传 `"all"` 或空表示不过滤）、`page`、`size`

**排序**: 按 `created_at` 降序

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": {
    "items": [ /* Feedback 对象数组 */ ],
    "total": 42,
    "page": 1,
    "size": 20
  }
}
```

---

### 9.3 单条反馈详情

```
GET /api/feedback/{id}
```

**路径参数**: `id` — MongoDB ObjectID（hex）

**错误码**: `404 not_found` — `反馈不存在`

---

### 9.4 更新反馈状态

```
PUT /api/feedback/{id}/status
```

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `status` | string | ✅ | 新状态 |
| `note` | string | ❌ | 处理备注 |

**有效 `status` 值** (10 种): `pending`, `processing`, `done`, `closed`, `rejected`, `reopened`, `in_verification`, `cannot_reproduce`, `duplicate`, `on_hold`

**状态流转**: 无状态机约束，任意有效状态之间可直接跳转。每次变更追加 `StatusChange` 到 `status_history` 数组。

**错误码**: `400` — `状态未变更` / `无效的状态值`

> ⚠️ 反馈模块的业务校验错误（无效类型、空标题、空内容、状态未变更等）使用 `writeJSONError` 返回，HTTP 状态码为 **200** 而非 400。前端需通过 `ok: false` 和 `message` 字段判断错误。

---

### 9.5 上传附件

```
POST /api/feedback/{id}/attachments
```

**请求体**: `multipart/form-data`，字段名 `file`，最大 **10MB**

**存储**: MongoDB GridFS

**成功响应** (`200`):

```json
{
  "ok": true,
  "attachmentId": "507f1f77bcf86cd799439011",
  "filename": "screenshot.png"
}
```

---

### 9.6 状态变更日志

```
GET /api/feedback/changelog
```

**Query 参数**: `handler_id`、`to_status`（按反馈当前状态筛选）、`feedback_id`、`start_time`（RFC3339）、`end_time`（RFC3339）

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": [
    {
      "feedbackId": "507f...",
      "feedbackTitle": "标题",
      "feedbackContent": "内容",
      "type": "bug",
      "fromStatus": "pending",
      "toStatus": "processing",
      "handlerId": "admin001",
      "note": "开始排查",
      "createdAt": "2026-08-14T19:30:00+08:00"
    }
  ]
}
```

---

### 9.7 批量更新反馈状态

```
POST /api/feedback/batch-status
```

**请求体**: `{ "ids": ["507f..."], "status": "done", "note": "已修复" }`  
**上限**: 200 条/次

> 每条反馈独立调用 `UpdateFeedbackStatus`，每条都会触发邮件通知。

---

## 10. 论坛账号

### 10.1 绑定论坛账号

```
POST /api/forum-account/bind
```

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `name` | string | ✅ | 论坛用户名或邮箱 |
| `password` | string | ✅ | 论坛密码 |

**密码校验**: 支持 Werkzeug 双格式：
- **scrypt**（Werkzeug 3.1+ 默认）: `scrypt:32768:8:1$<salt>$<hex_hash>`
- **pbkdf2:sha256**（旧版）: `pbkdf2:sha256:<iter>$<salt>$<hex_hash>`

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": {
    "forum_user_id": "42",
    "forum_user_name": "幽悠"
  }
}
```

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 401 | `invalid_credentials` | `论坛账号或密码错误` |
| 403 | `account_banned` | `该论坛账号已被封禁，无法关联` |

---

### 10.2 解绑论坛账号

```
DELETE /api/forum-account/unbind
```

**请求体**: 无  
**行为**: 从 MongoDB `forum_accounts` 集合删除绑定记录。

---

### 10.3 查询绑定状态

```
GET /api/forum-account/status
```

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": {
    "bound": true,
    "forum_user_id": "42",
    "forum_user_name": "幽悠",
    "forum_user_avatar": "avatars/42.png"
  }
}
```

> `bound: false` 时为正常返回（非错误），字段值为空字符串。

---

## 11. 回收站

> 三类回收站（posts / comments / users）共享同构的 CRUD 形态。所有接口均需 Bearer Token 认证。

### 11.1 回收站列表（三类通用）

```
GET /api/trash/posts
GET /api/trash/comments
GET /api/trash/users
```

**Query 参数**:

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| `page` | int | ❌ | 1 | 页码 |
| `size` | int | ❌ | 20 | 每页条数（最大 100） |
| `q` | string | ❌ | — | 模糊搜索（posts/comments 按 ID；users 按 ID 或用户名） |
| `deleted_by` | string | ❌ | — | 按删除者 admin ID 筛选 |
| `from` | string | ❌ | — | 删除时间起始（`YYYY-MM-DD`） |
| `to` | string | ❌ | — | 删除时间截止（`YYYY-MM-DD`） |
| `category` | string | ❌ | — | 仅 posts：按分类筛选 |
| `post_id` | string | ❌ | — | 仅 comments：按所属帖子筛选 |

**排序**: 按 `deleted_at` 降序（最新删除在前）

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "_id": "507f...",
        "original_post": { /* Post 对象 */ },
        "delete_reason": "违规内容",
        "deleted_by_admin_id": "admin001",
        "deleted_by_admin_name": "admin001",
        "deleted_at": "2026-08-14T10:00:00+08:00",
        "source_report_id": "1",
        "restored_by_admin_id": null,
        "restored_by_admin_name": null,
        "restored_at": null
      }
    ],
    "total": 10,
    "page": 1,
    "size": 20
  }
}
```

> ⚠️ `source_report_id` 仅 posts/comments 有，users 无此字段。

---

### 11.2 回收站详情（三类通用）

```
GET /api/trash/posts/{id}
GET /api/trash/comments/{id}
GET /api/trash/users/{id}
```

**路径参数**: `id` — MongoDB ObjectID（hex）

**错误码**: `404 not_found` — 文档不存在

---

### 11.3 恢复（三类通用）

```
POST /api/trash/posts/{id}/restore
POST /api/trash/comments/{id}/restore
POST /api/trash/users/{id}/restore
```

**路径参数**: `id` — MongoDB ObjectID  
**请求体**: 无

**幂等恢复机制**:

| 类型 | 幂等策略 | 级联行为 |
|------|----------|----------|
| Post | 先查 `posts` 表是否存在 → 存在则跳过 | 级联恢复该帖子下所有评论 |
| Comment | 先查 `comments` 表是否存在 → 存在则跳过 | 无级联；父帖子不存在时返回错误「请先恢复所属帖子」 |
| User | 先查 `users` 表是否存在 → 存在则跳过 | 级联恢复该用户所有帖子 + 所有评论（错误被跳过） |

---

### 11.4 批量恢复

```
POST /api/trash/batch-restore
```

**请求体**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `ids` | string[] | ✅ | MongoDB ObjectID 列表（最多 200 条，自动去重） |
| `kind` | string | ✅ | `post` / `comment` / `user` |

**成功响应** (`200`):

```json
{ "ok": true, "data": { "failed": [{ "id": "507f...", "message": "..." }] } }
```

---

## 12. 头像代理

> 头像代理模块用于缓存外部头像图片，减少对外部 CDN 的依赖。所有接口均需 Bearer Token 认证（`GET /api/avatar-proxy` 除外）。

### 12.1 获取缓存头像

```
GET /api/avatar-proxy
```

**认证**: ❌ 公开路由（无 AuthMiddleware，但需 CORS）

**Query 参数**:

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `url` | string | ✅ | 原始头像 URL |

**成功响应**: 二进制图片数据（`Content-Type` 根据图片类型自动设置，`Cache-Control: public, max-age=31536000`）

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 400 | `bad_request` | `缺少 url 参数` |
| 502 | `bad_gateway` | 抓取/缓存失败详情 |

---

### 12.2 获取缓存统计

```
GET /api/avatar-proxy/stats
```

**认证**: ✅ Bearer Token

**成功响应** (`200`):

```json
{ "ok": true, "data": { /* 缓存统计信息 */ } }
```

---

### 12.3 清空缓存

```
POST /api/avatar-proxy/clear
```

**认证**: ✅ Bearer Token

**请求体**: 无

**成功响应** (`200`):

```json
{ "ok": true, "message": "缓存已清空" }
```

**错误码**:

| HTTP | error | message |
|------|-------|----------|
| 500 | `internal_error` | 清空失败详情 |

---

## 13. 统计数据

### 13.1 全平台统计

```
GET /api/stats
```

**认证**: ✅ Bearer Token

**成功响应** (`200`):

```json
{
  "ok": true,
  "data": {
    "users": 100,
    "posts": 50,
    "comments": 200,
    "pending_reports": 5,
    "banned_users": 3,
    "deleted_posts": 2,
    "deleted_comments": 10
  }
}
```

| 字段 | 类型 | 数据源 | 说明 |
|------|------|--------|------|
| `users` | int64 | PG `users` | 总用户数 |
| `posts` | int64 | PG `posts` | 总帖子数 |
| `comments` | int64 | PG `comments` | 总评论数 |
| `pending_reports` | int64 | PG `post_reports` | 待处理举报数（`status='0'`） |
| `banned_users` | int64 | PG `users` | 封禁用户数（`is_banned='1'`） |
| `deleted_posts` | int64 | MongoDB `deleted_posts` | 回收站帖子数 |
| `deleted_comments` | int64 | MongoDB `deleted_comments` | 回收站评论数 |

> 使用 `errgroup` 并发 7 个 COUNT 查询（5 PG + 2 Mongo）。

---

## 14. 健康检查

### 13.1 Ping

```
GET /ping
```

**认证**: ❌ 公开路由

**成功响应** (`200`):

```json
{ "ok": true }
```

---

## 15. 错误码汇总

### 15.1 认证错误

| HTTP | error | message | 场景 |
|------|-------|---------|------|
| 401 | `unauthorized` | `missing authorization header` | 缺少 Authorization 头 |
| 401 | `unauthorized` | `invalid authorization format` | 非 Bearer 格式 |
| 401 | `unauthorized` | `invalid or expired token` | Token 无效或过期 |
| 401 | `invalid_credentials` | `管理员 ID 或密钥错误` | 登录凭据错误 |
| 401 | `invalid_credentials` | `论坛账号或密码错误` | 论坛绑定凭据错误 |

### 15.2 权限错误

| HTTP | error | message | 场景 |
|------|-------|---------|------|
| 403 | `forbidden` | `仅超级管理员可执行此操作` | 非 superadmin 执行管理操作 |
| 403 | `cannot_delete_self` | `不能删除自己的账号` | 尝试删除自己 |
| 403 | `cannot_downgrade_self` | `不能降级自己的角色` | 尝试降级自己 |
| 403 | `account_banned` | `该论坛账号已被封禁，无法关联` | 绑定被封禁的论坛账号 |
| 403 | `no_forum_account` | `请先关联论坛账号` | 未绑定论坛账号执行需绑定操作（CreateComment） |
| 400 | `no_forum_account` | `请先关联论坛账号` | 未绑定论坛账号执行需绑定操作（ReportPost） |
| 403 | `forbidden` | `管理员身份验证失败` | 高危操作 admin_id 不匹配 |
| 403 | `forbidden` | `请提供管理员密钥` | 高危操作未提供 admin_key |
| 403 | `forbidden` | `管理员密钥错误` | 高危操作 bcrypt 校验失败 |
| 403 | `forbidden` | `未完成确认` | 高危操作 confirm 不为 `true-ouo` |

### 15.3 请求错误

| HTTP | error | message | 场景 |
|------|-------|---------|------|
| 400 | `bad_request` | `invalid request body` | JSON 解析失败 |
| 400 | `bad_request` | `adminId and key are required` | 登录参数为空 |
| 400 | `bad_request` | `管理员 ID 和密钥不能为空` | 创建管理员参数为空 |
| 400 | `bad_request` | `无效的角色` | role 不是 admin/superadmin |
| 400 | `bad_request` | `请求格式错误` | JSON 解析失败（通用） |
| 400 | `bad_request` | `缺少 q 参数` | 搜索缺少关键词 |
| 400 | `bad_request` | `缺少帖子 ID` | 路径参数为空 |
| 400 | `bad_request` | `缺少举报 ID` | 路径参数为空 |
| 400 | `bad_request` | `无效的举报 ID` | 非整数 |
| 400 | `bad_request` | `缺少反馈 ID` | 路径参数为空 |
| 400 | `bad_request` | `无效的反馈 ID` | 非合法 ObjectID hex |
| 400 | `bad_request` | `无效的反馈类型` | type 不在白名单 |
| 400 | `bad_request` | `标题不能为空` | 反馈标题为空 |
| 400 | `bad_request` | `内容不能为空` | 反馈内容为空 |
| 400 | `bad_request` | `评论内容不能为空` | 评论内容为空 |
| 400 | `bad_request` | `评论内容不能超过1000字` | 评论超长 |
| 400 | `bad_request` | `被回复的评论不存在` | parent_id 无效 |
| 400 | `bad_request` | `被回复的评论不属于该帖子` | parent_id 跨帖子 |
| 400 | `bad_request` | `请选择举报原因` | reason 为空 |
| 400 | `bad_request` | `ID 列表不能为空` | 批量操作空列表 |
| 400 | `bad_request` | `单次最多操作 200 条` | 超过批量上限 |
| 400 | `bad_request` | `status 不能为空` | 批量更新状态为空 |
| 400 | `bad_request` | `文件过大或格式错误` | 附件超过 10MB |
| 400 | `bad_request` | `未找到上传文件` | multipart 无文件 |
| 400 | `bad_request` | `缺少管理员 ID` | 路径参数为空（管理员管理） |
| 400 | `bad_request` | `密钥不能为空` | 重置密钥为空 |
| 400 | `bad_request` | `缺少用户 ID` | 路径参数为空（用户管理） |
| 400 | `bad_request` | `缺少 key 字段` | 更新用户字段缺少 key |
| 400 | `bad_request` | `不允许的更新字段` | 字段名不在白名单 |
| 400 | `bad_request` | `缺少 domain 参数` | 头像扫描缺少域名 |
| 400 | `bad_request` | `缺少 url 参数` | 头像代理缺少 URL |
| 400 | `bad_request` | `头像列表不能为空` | 头像替换池为空 |
| 400 | `bad_request` | `恢复项列表不能为空` | 头像恢复列表为空 |
| 400 | `bad_request` | `未完成第一步确认` | 删除用户 confirm_step1 错误 |
| 400 | `bad_request` | `未完成第二步确认` | 删除用户 confirm_step2 错误 |
| 400 | `bad_request` | `用户名验证失败` | 删除用户 name 不匹配 |
| 400 | `bad_request` | `邮箱验证失败` | 删除用户 email 不匹配 |

### 15.4 资源冲突/不存在

| HTTP | error | message | 场景 |
|------|-------|---------|------|
| 404 | `not_found` | `管理员不存在` | 目标 admin_id 不存在 |
| 404 | `not_found` | `帖子不存在` | 帖子 ID 不存在 |
| 404 | `not_found` | `反馈不存在` | 反馈 ID 不存在 |
| 404 | `not_found` | `用户不存在` | 用户 ID 不存在 |
| 409 | `admin_id_taken` | `管理员 ID 已被使用` | admin_id 重复 |

### 15.5 限流错误

| HTTP | error | message | 场景 |
|------|-------|---------|------|
| 429 | `rate_limited` | `登录失败次数过多，请稍后再试` | 同一 IP 失败 ≥3 次 |

> 429 响应额外携带 `retryAfterSeconds` 字段（int 类型）。

### 15.6 服务器错误

| HTTP | error | message | 场景 |
|------|-------|---------|------|
| 500 | `internal_error` | `err.Error()` | 数据库/内部异常 |
| 502 | `bad_gateway` | 抓取/缓存失败详情 | 头像代理抓取外部图片失败 |

---

## 16. 数据模型参考

### 15.1 User

```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "avatar": "string",
  "gender": "string | null",
  "age": "int",
  "intro": "string | null",
  "vip": "int",
  "is_banned": "int",
  "last_login": "string | null",
  "created_at": "string | null"
}
```

> ⚠️ `gender`、`intro`、`last_login`、`created_at` 为可空指针（`*string`），无值时返回 `null`（非空字符串）。

### 15.2 Post

```json
{
  "id": "string",
  "user_id": "string",
  "title": "string",
  "content": "string",
  "category": "string",
  "likes": "int",
  "views": "int",
  "status": "int",
  "user_name": "string",
  "user_avatar": "string",
  "created_at": "string",
  "updated_at": "string"
}
```

### 15.3 Comment

```json
{
  "id": "string",
  "content": "string",
  "user_name": "string",
  "user_id": "string",
  "user_avatar": "string",
  "likes": "int",
  "parent_id": "string?",
  "post_id": "string?",
  "status": "int",
  "created_at": "string"
}
```

### 15.4 Report

```json
{
  "id": "string",
  "post_id": "string",
  "post_title": "string",
  "reporter_id": "string",
  "reporter_name": "string",
  "reason": "string",
  "detail": "string",
  "status": "int",
  "created_at": "string"
}
```

### 15.5 Feedback

```json
{
  "id": "string",
  "type": "string",
  "title": "string",
  "content": "string",
  "attachmentIds": "string[]",
  "reporterId": "string",
  "status": "string",
  "handlerId": "string",
  "statusHistory": [
    {
      "fromStatus": "string",
      "toStatus": "string",
      "handlerId": "string",
      "note": "string",
      "createdAt": "string"
    }
  ],
  "createdAt": "string",
  "updatedAt": "string"
}
```

### 15.6 AdminInfo

```json
{
  "admin_id": "string",
  "role": "string",
  "created_at": "string",
  "last_login_time": "string?"
}
```

### 15.7 ForumAccountStatus

```json
{
  "bound": "bool",
  "forum_user_id": "string",
  "forum_user_name": "string",
  "forum_user_avatar": "string"
}
```

### 15.8 TrashPost / TrashComment / TrashUser

```json
{
  "_id": "string",
  "original_post": { /* Post */ },
  "original_comment": { /* Comment */ },
  "original_user": { /* User */ },
  "delete_reason": "string",
  "deleted_by_admin_id": "string",
  "deleted_by_admin_name": "string",
  "deleted_at": "string",
  "source_report_id": "string?（仅 posts/comments 有，users 无此字段）",
  "restored_by_admin_id": "string?",
  "restored_by_admin_name": "string?",
  "restored_at": "string?"
}
```

---

## 附录 A: 高危操作校验链对比

| 操作 | Token | 二次验密 | 确认词 | 用户身份核验 |
|------|:-----:|:--------:|:------:|:------------:|
| 封禁/解封 | ✅ | ❌ | ❌ | ❌ |
| 批量封禁/解封 | ✅ | ❌ | ❌ | ❌ |
| 更新用户字段 | ✅ | ❌ | ❌ | ❌ |
| 头像替换/恢复 | ✅ | ✅ | ✅ `true-ouo` | ❌ |
| 单条删除用户 | ✅ | ✅ | ✅ **两步** | ✅ name+email |
| 批量删除用户 | ✅ | ✅ | ✅ `true-ouo` | ❌ |

## 附录 B: 论坛账号绑定依赖

| 接口 | 绑定要求 |
|------|----------|
| `POST /api/posts/{id}/comments` | ✅ 必须绑定 |
| `POST /api/posts/{id}/report` | ✅ 必须绑定 |
| 其他所有接口 | ❌ 不要求 |

## 附录 C: 批量操作通用规则

| 规则 | 值 |
|------|----|
| 单次上限 | 200 条 |
| 请求体大小上限 | 1MB |
| 失败处理 | 单项失败不中断，收集到 `failed` 数组 |
| 去重 | `batch-restore` 自动去重 |

---

> 📝 本文档由 AI 基于 `server/` 源码自动生成，如有疑问请对照源码核实。