# D9Music（原 FuoEvolve9）

仿照 [feeluown/FuoEvolve](https://github.com/feeluown/FuoEvolve) 的 FeelUOwn 音乐播放器，
用 **Objective-C + UIKit + Theos** 从零实现，目标设备 **iPhone 4S / iOS 9.3.6 / armv7**。

原项目是 Kotlin Multiplatform + Compose + SwiftUI，最低 iOS 15 且仅 arm64，无法直接编译到 iOS 9。

## 当前版本

**1.3.4（build 9）** · Bundle ID `com.d9music.app`

- 推荐 / 搜索 / 音乐库 / 我的 四大分区 + 全局迷你播放器
- 多音源：网易云、QQ 音乐、哔哩哔哩，可同时启用、拖动排序优先级、播放失败按顺序自动换源
- 多音源搜索：歌曲 / 歌单 / 专辑 / 歌手四类结果跨音源合并，按匹配度排序（含封面），优先推荐原唱版本、翻唱/伴奏靠后
- 推荐页按登录音源分区：登录网易云显示网易云推荐，登录 QQ 显示 QQ 推荐，都登录则分开显示
- 手动 Cookie 登录（不内置网页登录），登录信息本机持久化
- 我的页头像：最后登录音源的账号头像自动同步，也可从相册自定义
- 收藏、本地歌单、当前播放队列（支持单曲删除）、WebDAV 歌单/配置备份与恢复
- 云盘歌曲：浏览 WebDAV 远端歌曲目录，下载到 `Documents/CloudMusic` 并播放
- 播放记忆：记住上次退出的歌曲与进度，点播放继续
- 优先音质：标准 / 高清 / 无损，音源支持时优先使用，设置与播放页均可切换
- 歌曲缓存：可开关、可设上限（100MB / 200MB / 500MB / 1GB）、可一键清理
- 播放页左右滑动切换封面与全屏歌词（逐行渲染、当前行加粗高亮并跟随进度滚动，无半透明底板）
- 横屏固定为旋转黑胶 + 右侧多行歌词，退出播放页自动回到竖屏
- 应用内更新：Gitee / GitHub Release 检查、下载 IPA 并直接安装重启，可设置自动检查
- 底部迷你播放器支持播放/切歌/关闭（切歌按钮与播放键同色，关闭即停止播放并隐藏）
- 夜间模式、横屏播放（针对 4S 的 480×320 做了紧凑布局）
- 针对 iPhone 4S 的性能优化：封面缩图缓存、图片并发限制、阴影路径化、去掉列表动画

## 下载

- GitHub: https://github.com/Daniel123999/D9Music/releases
- Gitee: https://gitee.com/jyz2574461147/D9Music/releases

## 安装

未签名 IPA，需要：

1. 已越狱的 iOS 9 设备（iPhone 4S 等 armv7 机型）
2. AppSync Unified
3. 用 Filza / ipainstaller / ssh 安装 IPA

## 构建

```bash
cd ios
make clean
make TARGET=iphone:clang:9.3:9.0 ARCHS=armv7
./make_ipa.sh
```

需要 Theos + `iPhoneOS9.3.sdk`。CI 目前以 `.github/workflows/build-ios-linux.yml` 为主（ubuntu-latest + Theos + 预编译 iOS 工具链，`FINALPACKAGE=1`）；`.github/workflows/build-ios.yml` 为 macOS runner 备用通道。

## 技术要点

| 项目 | 值 |
|---|---|
| TARGET | `iphone:clang:9.3:9.0` |
| ARCHS | `armv7` |
| 架构校验 | thin armv7，cputype=12 / cpusubtype=9 |
| MinimumOSVersion | 9.0 |
| LDFLAGS | `-Wl,-undefined,dynamic_lookup`（仅用于 9.3 SDK 缺失的 `_memset` 等内建符号） |

详细证据与未验证项见 [PROJECT_REPORT.md](PROJECT_REPORT.md)。
