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

## 3. 已实现功能（骨架）

| 模块 | 文件 | 状态 |
|---|---|---|
| 应用入口 / 导航 | `ios/main.m`, `ios/AppDelegate.m` | 已完成，真机构建通过 |
| 入口页 | `ios/RootViewController.m` | 已完成（搜索 / 播放器入口） |
| 搜索页 | `ios/SearchViewController.m` | UI 完成，**结果为占位数据** |
| 播放页 | `ios/PlayerViewController.m` | UI 完成，**仅播放状态切换，未接入音频** |

明确未做：真实音源（网易云/QQ/B站/YT Music）、歌词、下载、登录、本地音乐扫描、听歌识曲。

## 4. 构建与验证证据

### 4.1 GitHub Actions

- 最近成功运行：`run 42579558569`（commit `5d42d6c`），结论 `success`
- Workflow：`.github/workflows/build-ios.yml`，`runs-on: macos-15`
- 修复过的两个真实构建问题：
  1. `runs-on: macos-13` 已下线 → 任务长期 `queued` 无 runner，改为 `macos-15`
  2. iOS 9.3 SDK 的 `libsystem_c.tbd` 未导出 `_memset`（真机 libSystem 有），
     链接失败 → `FuoEvolve9_LDFLAGS = -Wl,-undefined,dynamic_lookup`（仅此已确认缺口）
  3. `make package` 需要 control 文件 → 增加 `ios/control`
  4. IPA 只含二进制、缺 `Info.plist` → 打包脚本强制拷贝并校验

### 4.2 包级验证（`inspect_ipa.py --expect-arch armv7`）

```text
IPA: artifacts/verified-ipas/FuoEvolve9-v1.0.0-build2-armv7.ipa
size=13370 sha256=5C30B4E5C276AD3393CFC54525A42F90B7E786D7413910248442AEF705A87373
bundle=com.feeluown.fuoevolve9 version=1.0.0 build=2 minOS=9.0
architectures=armv7 (cpu=12, subtype=9)
RESULT: OK
```

IPA 内容：`Payload/FuoEvolve9.app/{FuoEvolve9, Info.plist}`，`UIDeviceFamily=[1]`。

### 4.3 发布

| 平台 | Release | 附件 | 公开下载校验 |
|---|---|---|---|
| GitHub | v1.0.0 (id 438835569) | `FuoEvolve9.ipa` 13370 B | **通过**，下载 SHA256 与 build 2 一致 |
| Gitee | v1.0.0 (id 1290189) | `FuoEvolve9.ipa` | 附件已上传；本机网络请求被 Gitee WAF 返回 403，**未完成公开下载校验** |

- 下载地址
  - GitHub: https://github.com/Daniel123999/FuoEvolve9/releases/download/v1.0.0/FuoEvolve9.ipa
  - Gitee: https://gitee.com/jyz2574461147/FuoEvolve9/releases/download/v1.0.0/FuoEvolve9.ipa

## 5. 未验证事项（必须明确）

1. **未在 iPhone 4S 真机安装/启动** —— 当前环境无设备，真机启动、渲染、稳定性均未验证。
2. Gitee 公开下载未从本机成功获取（403），仅确认 Release 与附件存在且名称正确。
3. 应用无自定义图标、无音频会话配置；首屏与页面跳转只做了静态代码审查。

## 6. 下一步最小动作

1. 在 4S 上安装 `FuoEvolve9-v1.0.0-build1-armv7.ipa`（越狱 + AppSync），确认启动与三页跳转。
2. 接入一个可用音源的最小搜索接口（NSURLSession + JSON），替换 `SearchViewController` 占位数据。
3. 用 `AVPlayer` 实现真实播放，并按 iOS 9 要求配置 `AVAudioSession` 与后台音频。
