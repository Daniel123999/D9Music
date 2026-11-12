# D9Music（原 FuoEvolve9）

仿照 [feeluown/FuoEvolve](https://github.com/feeluown/FuoEvolve) 的 FeelUOwn 音乐播放器，
用 **Objective-C + UIKit + Theos** 从零实现，目标设备 **iPhone 4S / iOS 9.3.6 / armv7**。

原项目是 Kotlin Multiplatform + Compose + SwiftUI，最低 iOS 15 且仅 arm64，无法直接编译到 iOS 9。

## 当前版本

**1.3.0（build 5）** · Bundle ID `com.d9music.app`

- 推荐 / 搜索 / 音乐库 / 我的 四大分区 + 全局迷你播放器
- 多音源：网易云、QQ 音乐、哔哩哔哩，可同时启用、拖动排序优先级、播放失败按顺序自动换源
- 手动 Cookie 登录（不内置网页登录），登录信息本机持久化
- 我的页头像：最后登录音源的账号头像自动同步，也可从相册自定义
- 收藏、本地歌单、当前播放队列、WebDAV 歌单/配置备份与恢复
- 云盘歌曲：浏览 WebDAV 远端歌曲目录，下载到 `Documents/CloudMusic` 并播放
- 夜间模式、横屏播放（针对 4S 的 480×320 做了紧凑布局）

## 下载

- GitHub: https://github.com/Daniel123999/FuoEvolve9/releases
- Gitee: https://gitee.com/jyz2574461147/FuoEvolve9/releases

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

需要 Theos + `iPhoneOS9.3.sdk`。CI 通过 `.github/workflows/build-ios.yml` 在 macos-15 上构建。

## 技术要点

| 项目 | 值 |
|---|---|
| TARGET | `iphone:clang:9.3:9.0` |
| ARCHS | `armv7` |
| 架构校验 | thin armv7，cputype=12 / cpusubtype=9 |
| MinimumOSVersion | 9.0 |
| LDFLAGS | `-Wl,-undefined,dynamic_lookup`（仅用于 9.3 SDK 缺失的 `_memset` 等内建符号） |

详细证据与未验证项见 [PROJECT_REPORT.md](PROJECT_REPORT.md)。
