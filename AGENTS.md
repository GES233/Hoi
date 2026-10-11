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
├── providers/app_providers.dart # riverpod providers（databaseProvider / selectedDateProvider / setStopwatchClockProvider / 各 StreamProvider）
├── screens/home_screen.dart     # 首页：日期导航（非今天可回今天）、今日方案卡、开始/补记入口、进行中训练卡、当日运动记录、饮食分区（含添加入口与摄入摘要）、本周概览；无 FAB，入口全在内容流内
├── screens/workout_screen.dart  # 进行中训练页：顶部紧凑总用时行 + 暂停/继续/结束；动作卡含组级小秒表（开始一组/暂停/结束并保存，计时只存内存）、手填添加组
├── screens/log_workout_screen.dart # 补记与编辑已完成训练（补记时动组本地暂存、保存时一次写入；可关联/取消方案）
├── screens/plans_screen.dart       # 最低／常规方案管理：列表 + 新增/编辑/删除对话框
└── widgets/                     # add_entry_dialogs.dart（饮食+周目标对话框）、workout_dialogs.dart（添加动作/组对话框与格式化）、set_stopwatch.dart（组级秒表纯 Dart 类，时钟可注入）
test/widget_test.dart            # 首页 widget 测试（内存数据库 + provider override）
test/database_test.dart          # 训练记录数据库测试（NativeDatabase.memory()，注入固定 now）
test/set_stopwatch_test.dart     # 组级秒表纯 Dart 测试（注入假时钟）
```

## 数据库

表：`food_entries`（饮食）、`workouts`（一次训练，含 status/startedAt/endedAt/pausedAt/pausedSeconds/totalSeconds/feeling 与方案快照列）、`workout_exercises`、`workout_sets`、`exercise_plans`（最低／常规方案，duration 阈值存秒、sets 存组数）、`rest_marks`（按日休息标记，date UNIQUE）、`favorite_foods`（常用食物，name UNIQUE）、`weekly_exercise_goals`（每周运动目标：次数+分钟，全表仅一行，空表时读 `AppDatabase.defaultWeeklyGoals`，更新时空表插入首行）。`date` 列只存日期部分，统一用 `AppDatabase.dateOnly()` 归一化；周查询以周一为起点（`AppDatabase.weekStart()`）。当前 `schemaVersion` 为 3（v1→v2 新增 `weekly_exercise_goals`；v2→v3 删除旧 `exercise_entries` 表并新增训练相关 5 张表，旧数据经确认丢弃）。

关键规则：全场至多一场 `inProgress` 训练（`startWorkout` 幂等）；有效组 = reps>0 或 durationSeconds>0，`finishWorkout` 无有效组抛 StateError；`totalSeconds` 未知即 null，绝不推算；计时方法接受可选 `now` 参数供测试注入；`discardWorkout`/`deleteWorkoutExercise` 显式级联删除子记录（内存库外键不一定开启，勿依赖 sqlite cascade）；达标按训练上的方案快照用 `AppDatabase.evaluateWorkout` 实时计算（只累计同名动作），方案编辑/删除不影响历史判定。组级小秒表（`SetStopwatch`）计时只存页面内存、不落库，应用被杀丢失正在走的一组是既定取舍；全场至多一个组在计时，时钟经 `setStopwatchClockProvider` 注入。

**改表规则**：递增 `schemaVersion` 并在 `AppDatabase` 中补 migration，然后跑 build_runner。常用食物按 name 冲突 upsert（`DoUpdate(target: [favoriteFoods.name])`），新增唯一列冲突时同样需显式指定 target。

## 已知坑

- **widget 测试 pending timer**：drift 取消查询流会调度零时长 Timer，组件树卸载前必须先 `await db.close()`（见 `test/widget_test.dart` 的 `finishTest`）。
- **widget 测试 `db.close()` 挂起（FakeAsync）**：`StreamQueryStore.close()` 会等待零时长 `Timer.run` 完成，测试里 push 过路由时该定时器可能等不到 pump，`await db.close()` 永不返回（表现为整个测试 10 分钟超时）。根治办法：widget 测试用 `DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)` 构造数据库，关闭流同步完成、不走 Timer（见 `test/widget_test.dart` 的 setUp）。
- **ListView 懒加载截断断言**：首页内容超出视口后，离屏 widget 不在树中，`find.text` 会找不到。`pumpHome` 已把测试视口加高（1080x2200）；若视口装不下，先 `tester.scrollUntilVisible` 再断言。
- **flutter_tester 残留**：测试被中断后残留进程可能锁死 `build/native_assets/windows/sqlite3.dll`，导致下次测试失败。执行 `taskkill //F //IM flutter_tester.exe` 后重跑。
- **训练页常驻 Timer 与 pumpAndSettle**：`workout_screen.dart` 有每秒刷新显示的 `Timer.periodic`，widget 测试进入该页后不能再 `pumpAndSettle`（永不 settle），用固定时长 `pump()` 推进；收尾前 `pageBack` 弹出该页让 Timer 随 dispose 取消。
- **Android 工具链**：SDK 在 `D:\Langs\AndroidSDK`（见 `android/local.properties` 的 `sdk.dir`），需 cmdline-tools 并已接受 licenses（`flutter doctor --android-licenses`）。

## 约定

- 所有用户可见文本用中文；代码注释保持现有密度（简短说明意图）。
- Git 行尾：`.gitattributes` 锁定 LF（`.bat`/`.cmd` 为 CRLF）。
- 新功能遵循现有模式：drift 查询方法放在 `AppDatabase`，状态放 `providers/`，UI 按 screen/widget 分层。
