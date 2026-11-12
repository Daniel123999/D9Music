# FuoEvolve9 — iOS 9 / iPhone 4S 移植项目报告

## 1. 项目定位

仿照 [feeluown/FuoEvolve](https://github.com/feeluown/FuoEvolve) 的 FeelUOwn 音乐播放器，
用 Objective-C + UIKit + Theos 从零实现一个可在 iPhone 4S / iOS 9.3.6 / armv7 上运行的版本。

原项目为 Kotlin Multiplatform + Compose + SwiftUI，最低 iOS 15、仅 arm64，
无法直接构建为 iOS 9 armv7 产物（Kotlin/Native 已不支持 iOS 9 与 armv7），因此采用重写而非移植。

## 2. 目标基线

```text
设备/切片：iPhone 4S，armv7（cputype=12, cpusubtype=9）
最低系统：iOS 9.0
SDK：iPhoneOS9.3.sdk
TARGET：iphone:clang:9.3:9.0
ARCHS：armv7
构建：Theos（GitHub Actions macos-15）
分发：未签名 IPA（越狱 + AppSync Unified）
```

## 3. 已实现功能

| 模块 | 状态 |
|---|---|
| 底部 Tab 导航（推荐/搜索/音乐库/我的）+ 全局迷你播放器 | 已完成（代码） |
| FuoEvolve 风格卡片式 UI（渐变主色、圆角卡片、代码绘制矢量图标） | 已完成（代码） |
| 音源切换与手动 Cookie 登录（粘贴 Cookie，非内置网页登录） | 已完成（代码） |
| 网易云搜索/播放地址/歌词/歌单/推荐歌单/新歌/新碟/排行榜/歌单广场 API | 已完成（代码） |
| 哔哩哔哩搜索/播放地址 API | 已完成（代码） |
| AVPlayer 播放、上一首/下一首、进度拖动、后台控制 | 已完成（代码） |
| 播放失败自动切换其他音源 | 已完成（代码） |
| 本地音乐扫描（MPMediaLibrary） | 已完成（代码） |
| 本地歌单 CRUD 与持久化 | 已完成（代码） |
| 播放界面（封面/进度/歌词同步） | 已完成（代码） |

未做：QQ 音乐完整 API、YouTube Music、下载、听歌识曲、视频播放、收藏/云盘完整逻辑。

> 注意：上表“已完成”指源码已写入并通过静态检查/接口验证，**1.2.0 这批改动尚未经过一次真实编译**（见第 6 节）。

## 4. 本轮（1.2.0 / build 4）改动要点

### 4.1 “搜索出结果但点击不播放”根因与修复

| 根因 | 修复 |
|---|---|
| 网易云 CDN 播放地址是 **明文 `http://`**，iOS 9 ATS 默认拦截，AVPlayer 静默失败 | `Info.plist` 增加 `NSAppTransportSecurity`，`NSAllowsArbitraryLoads=true` 并对 music.163.com / 126.net / bilibili.com / qq.com 加 `NSExceptionAllowsInsecureHTTPLoads` |
| 搜索结果里 `playUrl` 为空时 `playTrack:` 直接返回，界面无反应 | `FEPlayerManager playTrack:` 在 `playUrl` 为空时先向音源请求真实播放地址再播放，失败时置为错误态并提示 |
| 网易云 `/api/song/enhance/player/url` 对部分歌曲返回 `url:null`（VIP/版权） | 先按 320000 请求，失败退到 128000，再退到 `song/media/outer/url`，仍失败则自动切换其他音源 |
| 播放单元失败无监听，只在控制台报错 | `AVPlayerItem` KVO `status` + `AVPlayerItemFailedToPlayToEndTimeNotification` 统一走失败处理与重试 |

### 4.2 UI 重写

- 新增 `ios/UI`：`FETheme`（主色 `#6C5CE7` / 粉色 `#FF6B9D` 渐变、圆角卡片、Toast）、
  `FEIconView`（纯代码绘制矢量图标，不依赖 SF Symbols/图片资源）、`FEImageView`（异步封面加载 + 占位）、
  `FEComponents`（模块卡片、分组标题、歌曲 Cell）、`FEMiniPlayerView`、`FERootTabBarController`、
  `FETrackListViewController`、`FEPlaylistGridViewController`。
- 推荐页改为「渐变 Hero 卡 + 大图标快捷入口 + 歌单横滑 + 新歌列表」，不再是一列纯文字入口。

### 4.3 接口回归修复（2026-11-10 实测）

| 接口 | 修复前 | 修复后 |
|---|---|---|
| 推荐歌单 | `music.163.com/personalized` → `code=404` | `api/personalized/playlist?limit=12` → `code=200`，6/6 条 |
| 新歌速递 | `music.163.com/personalized/newsong` → `code=404` | `api/personalized/newsong?limit=12` → `code=200` |
| 新碟上架 | `api/album/newest` → `code=400` | `api/album/new?area=ALL&limit=12` → `code=200`；曲目改从 `album.songs` 解析 |
| 歌单详情 | — | `api/playlist/detail?id=` → `code=200`，40~300 首 |

接口实测证据（Windows 主机 + 普通 HTTP 请求，**非 armv7 运行时**）：

```text
搜索   POST /api/search/get/web                code=200  songs=3 (周杰伦)
播放   POST /api/song/enhance/player/url       免费曲 5257138 br=320000 code=200 url=http://m7xx.music.126.net/...mp3
       GET 该 url                             200 audio/mpeg, 读取 64 字节成功
       VIP 曲 186016                          url=null, code=404；outer/url 302 → http://music.163.com/404
推荐   api/personalized/playlist?limit=6       code=200 count=6
新歌   api/personalized/newsong?limit=6        code=200 count=6
新碟   api/album/new?area=ALL&limit=6          code=200 count=6
歌单   api/playlist/detail?id=7224567337       code=200 tracks=40
B 站   x/web-interface/search/type             code=0 results=3
       x/player/playurl?fnval=16               code=0 durl=1 https://upos-sz-*.bilivideo.com/*.mp4
       GET durl（带/不带 Referer）             200 video/mp4
```

结论：**免费歌曲可用，VIP/版权歌曲服务端返回空地址**——这类歌曲只能靠自动切换音源，属音源能力限制而非播放器缺陷。

## 5. 构建与验证证据

### 5.1 包级验证（`inspect_ipa.py --expect-arch armv7`）

仅对 **1.0.0 build 2** 有效：

```text
IPA: artifacts/verified-ipas/FuoEvolve9-v1.0.0-build2-armv7.ipa
size=52293 sha256=B935646ED8482E4BD18D0429342BCC6987A869351671B014E59DFA1DE421CA46
bundle=com.feeluown.fuoevolve9 version=1.0.0 build=2 minOS=9.0
architectures=armv7 (cpu=12, subtype=9)
RESULT: OK
```

### 5.2 发布

| 平台 | Release | 附件 | 公开下载校验 |
|---|---|---|---|
| GitHub | v1.0.0 (id 438835569) | `FuoEvolve9.ipa` 52293 B | **通过**，下载 SHA256 与 build 2 一致 |
| Gitee | v1.0.0 (id 1290189) | `FuoEvolve9.ipa` | 附件已上传；本机请求被 Gitee WAF 403，**未完成公开下载校验** |

- 下载地址
  - GitHub: https://github.com/Daniel123999/FuoEvolve9/releases/download/v1.0.0/FuoEvolve9.ipa
  - Gitee: https://gitee.com/jyz2574461147/FuoEvolve9/releases/download/v1.0.0/FuoEvolve9.ipa

### 5.3 当前构建阻塞

- GitHub Actions：API 返回 `403 已禁止`（含 `/rate_limit`），token/账号被限制，无法触发工作流。
- Gitee：无 CI。
- 本机 Windows：无 macOS / Theos / ldid，**无法产出 IPA**。

## 6. 未验证事项（必须明确）

1. **1.2.0 这批改动（ios/UI 全部代码 + 播放器/Provider 重写）尚未经过一次真实编译**，可能存在编译错误。
2. **未在 iPhone 4S 真机安装/启动** —— 真机启动、渲染、播放、稳定性均未验证。
3. Gitee 公开下载未从本机成功获取（403）。
4. VIP/版权歌曲仍无法播放（服务端 `url:null`），仅能自动切换音源兜底。

## 7. 下一步最小动作

1. 恢复可用的构建通道（GitHub Actions 或任意 macOS + Theos），编译 1.2.0 → `inspect_ipa.py --expect-arch armv7` → 归档到 `artifacts/verified-ipas`。
2. 在 4S 上安装，实测：搜索 → 点击播放、推荐页各模块、播放失败自动换源、Cookie 登录。
3. 补齐 QQ 音乐 API；再考虑收藏、云盘、下载与本地文件导入。
