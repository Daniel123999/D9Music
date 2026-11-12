# D9Music（原 FuoEvolve9）— iOS 9 / iPhone 4S 项目报告

## 1. 项目定位

仿照 [feeluown/FuoEvolve](https://github.com/feeluown/FuoEvolve) 的 FeelUOwn 音乐播放器，
用 Objective-C + UIKit + Theos 从零实现一个可在 iPhone 4S / iOS 9.3.6 / armv7 上运行的版本。

原项目为 Kotlin Multiplatform + Compose + SwiftUI，最低 iOS 15、仅 arm64，
无法直接构建为 iOS 9 armv7 产物（Kotlin/Native 已不支持 iOS 9 与 armv7），因此采用重写而非移植。

## 2. 目标基线

```text
应用名：D9Music
Bundle ID：com.d9music.app
版本：1.3.1 (build 6)
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
| 多音源：同时启用、拖动排序优先级、按优先级自动换源 | 已完成（代码） |
| 网易云搜索/播放地址/歌词/歌单/推荐歌单/新歌/新碟/排行榜/歌单广场 API | 已完成（代码） |
| QQ 音乐搜索/播放地址/歌词/歌单/账号资料 API + Cookie 登录 | 已完成（代码） |
| 哔哩哔哩搜索/播放地址/账号资料 API | 已完成（代码） |
| 我的页头像同步（最后登录音源）+ 相册自定义头像 | 已完成（代码） |
| 夜间模式（深色配色 + 全界面重建） | 已完成（代码） |
| 横屏播放（480×320 紧凑布局、按钮完整可见） | 已完成（代码） |
| WebDAV 云盘浏览（PROPFIND 列目录）+ 下载播放 | 已完成（代码） |
| AVPlayer 播放、上一首/下一首、进度拖动、后台控制 | 已完成（代码） |
| 播放失败自动切换其他音源 | 已完成（代码） |
| 本地音乐扫描（MPMediaLibrary） | 已完成（代码） |
| 本地歌单 CRUD 与持久化 | 已完成（代码） |
| 播放界面（封面/进度/歌词同步） | 已完成（代码） |
| 收藏（登录网易云走 `like`，未登录存本地“我喜欢”歌单） | 已完成（代码） |
| WebDAV 同步（歌单/配置备份恢复，设置页含连接测试） | 已完成（代码） |
| 当前播放列表页（查看/删除/清空队列）、歌单重命名/删除 | 已完成（代码） |
| 应用图标（紫粉渐变 + 白色音符，11 个尺寸已进包） | 已完成（包内验证） |
| 应用内更新（Gitee/GitHub Release 检查 + 下载 IPA + 直接安装重启） | 已完成（代码 + Release） |
| 歌曲缓存（开关 / 上限 / 一键清理 / 复播命中本地） | 已完成（代码） |
| 播放记忆（歌曲 + 队列 + 进度，启动后续播） | 已完成（代码） |
| 优先音质（标准 / 高清 / 无损，网易云 + QQ 支持降级） | 已完成（代码） |
| 多音源并行搜索（按来源分组、带封面） | 已完成（代码） |
| 推荐页按登录音源分区（网易云 / QQ） | 已完成（代码） |
| 播放页左右滑动切换封面 / 全屏歌词 | 已完成（代码） |

未做：YouTube Music、下载（离线曲库）、听歌识曲、视频播放、云盘上传完整逻辑。

> 注意：上表“已完成”指源码已写入、通过静态检查，并已由 GitHub Actions（macos-15 + Theos）成功交叉编译为 armv7 IPA；
> **尚未在 iPhone 4S 真机上安装运行**（见第 6 节）。

## 4. 本轮改动要点（1.3.0 → 1.3.1）

### 4.0 设置、主题与横屏

| 问题 | 修复 |
|---|---|
| 设置页「关于」分组被底部迷你播放器遮挡 | 表格底部 `contentInset = 120`，所有分组可完整滚动显示 |
| 保存配置混在列表里 | 移到导航栏右上角 `保存`，与返回按钮同风格 |
| WebDAV 配置长期展开、占满屏幕 | 默认折叠为一行「WebDAV 云同步」，点开展开；再点「收起」 |
| 「从云端恢复配置」观感像开关 | 改为居中加粗按钮样式，点击弹二次确认 |
| 无夜间模式 | 新增 `FESettings` + `FETheme` 深色配色（背景 `#0F1016`、卡片 `#1B1D27`），切换后重建界面 |
| 播放页固定竖屏布局在 4S 上越界 | 按 320×480 / 480×320 两套布局重排，封面自适应，控件完整可见，支持旋转 |

### 4.1 多音源与 QQ 音乐

- `FEProviderManager` 保存 `providerOrder`（优先级）与 `enabledProviderIds`（可多选）。
- 音源页按钮改为 **使用 / 使用中** 开关；拖动行即调整优先级；点按行登录或设为首选。
- 播放失败时按启用顺序依次换源（最多 2 次）。
- `FEQQProvider` 完整实现：Cookie 持久化、`uin` 解析、搜索、歌单列表/详情、歌词、vcard 资料、vkey 播放。

### 4.2 头像与云盘

- 新增 `FESettings.lastLoginProviderId`，登录成功时记录；「我的」页按「自定义头像 → 最后登录音源 → 首个已登录音源」取图。
- 头像支持相册自定义（裁剪为正方形，存 `Documents/d9_avatar.jpg`）。
- 新增 `FECloudViewController`：WebDAV PROPFIND 列目录、文件夹下钻、音频文件下载到 `Documents/CloudMusic` 并直接播放。
- 配置备份改为 plist + 歌单归档，恢复时真正写回本地歌单。

### 4.3 品牌重命名

- `CFBundleDisplayName` / `CFBundleExecutable` / `CFBundleName` = `D9Music`，`CFBundleIdentifier` = `com.d9music.app`。
- Makefile、control、CI workflow、`make_ipa.sh`、WebDAV 默认路径统一为 `D9Music` / `/D9Music/`。

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

### 4.4 1.3.1 新增

| 能力 | 实现 |
|---|---|
| 应用内更新 | `FEAppUpdater`：Gitee（jyz → Daniel）→ GitHub，优先 Release API（Gitee 取 20 条自选最高版本，GitHub `/releases/latest`），失败回落解析 release 页面；下载 IPA 带进度；安装依次尝试 `ipainstaller` → `MobileInstallation` → `LSApplicationWorkspace`；成功后清理安装包并自动重启。`FEUpdateUI` 提供设置入口、自动检查开关、安装确认与结果提示 |
| 歌曲缓存 | `FECacheManager` 缓存到 `Library/Caches/D9Music`，按 providerId + trackId + 音质命名；缓存开关、上限（100MB/200MB/500MB/1GB）、超限按修改时间淘汰、占用统计与一键清理；播放前若命中缓存直接用本地文件 |
| 播放记忆 | `FEPlayerManager` 在不同时机（播放中每 5 秒、暂停、切后台、退出）保存歌曲/队列/索引/进度；启动恢复但**不自动播放**，点迷你播放器或播放页的播放键从上次进度继续（恢复时清空过期播放地址并重新解析） |
| 优先音质 | 设置与播放页都可切换标准/高清/无损；网易云按 `br` 999000 → 320000 → 128000 链式请求并降级，QQ 用 vkey `filename` 数组一次请求多档位，取第一个可用 purl |
| 播放页布局 | 收藏 / 上一首 / 播放 / 下一首 / 列表合并为一行，修复 320×480 下两个按钮被挤出屏幕；左右滑动切换封面与全屏歌词（歌词可滚动并自动定位当前句） |
| 多音源搜索 | 并发搜索所有「使用中」音源，按音源分组显示结果数量与封面，点任意结果从该音源列表起播 |
| 推荐分区 | 推荐页按已登录音源生成独立分区（网易云 / QQ），都登录则两块；QQ 新增推荐歌单与热歌/新歌榜接口；未登录时用网易云公开推荐兜底 |

## 5. 构建与验证证据

### 5.1 包级验证

**当前版本 1.3.1 build 6**（GitHub Actions run `43242463347`，commit `426d6b7`）：

```text
IPA: artifacts/verified-ipas/D9Music-v1.3.1-build6-armv7.ipa
size=237316 sha256=B848D5CD9C11EB16AAD927B0A8B24A81AEA787A6C2E7E27C593D352428DC3D2F
bundle=com.d9music.app version=1.3.1 build=6 minOS=9.0
architectures=armv7 (cpu=12, subtype=9)
Mach-O magic=0xfeedface
bundle 内含图标 PNG=11（Icon / Icon@2x / Icon-60 / Icon-60@2x / Icon-60@3x /
  Icon-Small / Icon-Small@2x / Icon-Small@3x / Icon-Small-40 / Icon-Small-40@2x / Icon-Small-40@3x）
Release 附件 D9Music.ipa 下载 SHA256 一致
RESULT: OK
```

历史版本 1.2.0 build 4（上一版，仅供对照）：

```text
IPA: artifacts/verified-ipas/FuoEvolve9-v1.2.0-build4-armv7.ipa
size=166815 sha256=2F514E2C1B7650594FF92CD858AC6491D9884713D668093AA0C2A5006D5E4E5A
bundle=com.feeluown.fuoevolve9 version=1.2.0 build=4 minOS=9.0
architectures=armv7 (cpu=12, subtype=9)
Mach-O magic=0xfeedface
NSAppTransportSecurity.NSAllowsArbitraryLoads=true
RESULT: OK
```

### 5.2 发布

| 平台 | Release | 附件 | 公开下载校验 |
|---|---|---|---|
| GitHub | v1.3.1 | `D9Music.ipa` 237316 B | **通过**，下载 SHA256 = `B848D5CD…` 与本地构建一致 |
| Gitee | v1.3.1 (id 1302647) | `D9Music.ipa` 237316 B | 已上传；本机请求被 Gitee WAF 403，**未完成公开下载校验** |
| GitHub | v1.0.0 (id 438835569) | `FuoEvolve9.ipa` 52293 B | 历史版本，已校验 |
| Gitee | v1.0.0 (id 1290189) | `FuoEvolve9.ipa` | 历史版本，未完成公开下载校验 |

- 下载地址
  - GitHub: https://github.com/Daniel123999/FuoEvolve9/releases/download/v1.3.1/D9Music.ipa
  - Gitee: https://gitee.com/jyz2574461147/FuoEvolve9/releases/download/v1.3.1/D9Music.ipa

### 5.3 构建通道（2026-11-12 打通）

| 项 | 内容 |
|---|---|
| 代码托管 | GitHub `Daniel123999/FuoEvolve9`（主）+ Gitee `jyz2574461147/FuoEvolve9`（镜像） |
| CI | GitHub Actions，`runs-on: macos-15`，Theos + `iPhoneOS9.3.sdk`，`TARGET=iphone:clang:9.3:9.0` |
| 本次成功（1.3.1） | run `43242463347`，commit `426d6b7`，产物 `D9Music-ipa` 233250 B（解包后 IPA 237316 B） |
| 产物归档 | `artifacts/verified-ipas/D9Music-v1.3.1-build6-armv7.ipa`、`local-ipas/D9Music-latest-armv7.ipa` |
| 上一次成功（1.3.0） | run `43234133270`，commit `0968460`，`D9Music-v1.3.0-build5-armv7.ipa` |

构建过程中真实遇到并修复的两个问题：

1. **编译错误（run `43136319416` 前的 `43135842283`）**：
   `FEPlaylistListViewController.m` 在合并 `alertView:clickedButtonAtIndex:` 时丢失了
   `UITableViewDataSource` 必需方法，`-Werror,-Wprotocol` 直接报错。
   已补回 data source/delegate 与左滑「重命名/删除」动作，本地以 `-Werror` 全量复检 35 个 `.m` 通过。
2. **包内缺图标（run `43136319416` 产物）**：`ios/Makefile` 未把 `ios/icons/*.png` 拷进 bundle，
   `CFBundleIcons` 引用的 11 个 PNG 全部缺失。已加 `_RESOURCE_DIRS = icons` 修复（重命名为 D9Music 后仍保留）。

> 注：另一账号 `giabana-cd40b232` 的 hosted runner 始终无法分配（
> “The job was not acquired by Runner of type hosted”），该仓库已停用，构建统一走 `Daniel123999` 账号。


## 6. 未验证事项（必须明确）

1. **1.3.1 build 6 已成功编译**（armv7、包含图标），但**从未在 iPhone 4S 真机上安装/启动** ——
   启动崩溃、应用内更新安装流程、缓存命中去重、播放记忆续播、音质切换、滑动歌词、多音源搜索与分区推荐均未经过运行时验证。
2. 构建机为 GitHub Actions 的 macOS runner（clang + Theos），与本机 `-Werror` 静态检查（40 个 `.m`）一致，但静态检查不能替代真机运行。
3. Gitee 公开下载未从本机成功获取（403），仅 GitHub 侧下载校验通过。
4. VIP/版权歌曲仍无法播放（服务端 `url:null`），仅能自动切换音源兜底；无损音质同样受账号权限限制。

## 7. 下一步最小动作

1. 把 `local-ipas/D9Music-latest-armv7.ipa` 装到已越狱 + AppSync Unified 的 4S 上，
   实测：启动 → 搜索（多音源）→ 播放/缓存/记忆续播 → 音质切换 → 滑动歌词 → 设置中各开关 → 云盘下载 → 检查更新。
2. 依据真机表现修 bug，再走一次 CI 出包并用应用内更新验证覆盖安装。
3. 视需要补齐云盘上传；再把仓库名从 `FuoEvolve9` 改为 `D9Music`。
