# FuoEvolve9

仿照 [feeluown/FuoEvolve](https://github.com/feeluown/FuoEvolve) 的 FeelUOwn 音乐播放器，
为 **iPhone 4S / iOS 9.3.6 / armv7** 用 Objective-C + UIKit + Theos 重写。

原项目是 Kotlin Multiplatform + Compose + SwiftUI，最低 iOS 15 且仅 arm64，无法直接编译到 iOS 9。

## 当前状态

首个骨架版本 v1.0.0（build 1）：入口页、搜索页、播放页可用，搜索结果为占位数据，
播放页仅 UI 状态切换，尚未接入真实音源与音频播放。

详细证据与未验证项见 [PROJECT_REPORT.md](PROJECT_REPORT.md)。

## 下载

- GitHub: https://github.com/Daniel123999/FuoEvolve9/releases
- Gitee: https://gitee.com/jyz2574461147/FuoEvolve9/releases

## 安装

未签名 IPA，需要：

1. 越狱的 iOS 9 设备（iPhone 4S 等 armv7 机型）
2. AppSync Unified
3. 用 Filza / AltStore / ssh 安装 IPA

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

## 许可

GPL-3.0，与原项目一致。
