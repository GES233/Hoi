# AGENTS.md

## 项目概述

hoi — 纯本地的饮食 + 运动记录追踪应用（Flutter）。无后端、无账号，数据存于设备本地 SQLite。目标平台：Android + Windows。界面与代码注释均为中文。

## 技术栈

- Flutter 3.47 / Dart 3.13，Material 3
- 数据库：drift 2.35 + drift_flutter（`driftDatabase` 构造器，双平台免配置）
- 状态管理：flutter_riverpod 3.x（注意：3.x 已移除 `valueOrNull`，用 `.value ?? []`）
- 日期格式化：intl
- 代码生成：build_runner + drift_dev

## 常用命令

```bash
flutter pub get
dart run build_runner build     # 修改 drift 表定义后必须重新生成 database.g.dart
flutter analyze                 # 提交前需无 error
flutter test                    # widget 测试
flutter run -d windows          # 桌面运行
flutter emulators --launch Medium_Phone && flutter run   # Android 模拟器
```

## 目录结构

```
lib/
├── main.dart                    # 入口：ProviderScope + MaterialApp（绿色主题）
├── database/database.dart       # drift 表定义与查询（database.g.dart 为生成文件，勿手改）
├── providers/app_providers.dart # riverpod providers（databaseProvider / selectedDateProvider / 各 StreamProvider）
├── screens/home_screen.dart     # 首页：日期切换、汇总卡片、饮食/运动分区列表
└── widgets/add_entry_dialogs.dart # 添加饮食/运动对话框
test/widget_test.dart            # 首页 widget 测试（内存数据库 + provider override）
```

## 数据库

表：`food_entries`（饮食）、`exercise_entries`（运动）、`favorite_foods`（常用食物，name UNIQUE）。`date` 列只存日期部分，统一用 `AppDatabase.dateOnly()` 归一化。

**改表规则**：递增 `schemaVersion` 并在 `AppDatabase` 中补 migration，然后跑 build_runner。常用食物按 name 冲突 upsert（`DoUpdate(target: [favoriteFoods.name])`），新增唯一列冲突时同样需显式指定 target。

## 已知坑

- **widget 测试 pending timer**：drift 取消查询流会调度零时长 Timer，组件树卸载前必须先 `await db.close()`（见 `test/widget_test.dart` 的 `finishTest`）。
- **flutter_tester 残留**：测试被中断后残留进程可能锁死 `build/native_assets/windows/sqlite3.dll`，导致下次测试失败。执行 `taskkill //F //IM flutter_tester.exe` 后重跑。
- **Android 工具链**：SDK 在 `D:\Langs\AndroidSDK`（见 `android/local.properties` 的 `sdk.dir`），需 cmdline-tools 并已接受 licenses（`flutter doctor --android-licenses`）。

## 约定

- 所有用户可见文本用中文；代码注释保持现有密度（简短说明意图）。
- Git 行尾：`.gitattributes` 锁定 LF（`.bat`/`.cmd` 为 CRLF）。
- 新功能遵循现有模式：drift 查询方法放在 `AppDatabase`，状态放 `providers/`，UI 按 screen/widget 分层。
