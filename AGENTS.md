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
dart run flutter_launcher_icons   # 更换应用图标源图（assets/icon/）后重新生成各平台图标
```

## 目录结构

```
lib/
├── main.dart                       # 入口：ProviderScope + MaterialApp（接入 HoiTheme，支持高对比/柔和与深浅色主题切换）
├── theme/app_theme.dart            # 全局视觉设计系统：高对比/柔和深浅色 ThemeData、themePreferenceProvider、类别/餐次图标与色彩语义、HoiPill
├── domain/
│   ├── workout_timeline.dart       # 自然周运动时间线条带切分（跨日裁切）与重叠泳道（lane）分配
│   └── rules/                      # 周期目标领域层：metric.dart（指标注册表）、rule_ast.dart（规则 AST 与编解码）、rule_evaluator.dart（评估器）
├── database/
│   ├── database.dart               # drift 表定义、迁移、共享静态 API（database.g.dart 为生成文件，勿手改）
│   └── daos/                       # 按饮食、训练、动作、模板、规则、每日状态、每日主观状态拆分的 DAO extension
├── providers/app_providers.dart    # riverpod providers（databaseProvider / selectedDateProvider / 可注入时钟与按分钟 tick / 各 StreamProvider 与 *ForDateProvider family）
├── screens/home_screen.dart        # 首页（组装者）：顶部操作栏（动作/目标/方案/主题切换）、周条+每日状态卡、进行中训练、开始/补记/单项入口、今日方案、当日记录、饮食摘要、周进度入口；无 FAB
├── screens/workout_screen.dart     # 进行中训练页（组装者）：顶部紧凑总用时行 + 暂停训练/继续训练/结束训练；组级小秒表计时只存内存、全场至多一组在计时；放弃训练/删除动作收进 ⋮ 菜单且有确认；进度卡与动作卡实现拆在 widgets/
├── screens/log_workout_screen.dart # 补记、记录单项运动（singleExercise）与编辑已完成训练（均在本地草稿 _drafts 暂存，组可点按编辑，保存时单事务原子写入；支持关联/取消方案并自动对齐计划组）
├── screens/week_progress_screen.dart # 周进度页（只读，支持独立翻周）：页面持有 _weekStart（上一周/下一周/回到本周），展示日期格 + 状态点图例 + 运动时段 + 周期目标；翻周与查看不改动全局选中日期
├── screens/exercises_screen.dart   # 运动类型（动作目录）管理：新增、编辑（名称/类别/记录方式/负重方式/单双侧计数口径）与归档
├── screens/plans_screen.dart       # 训练模板（运动方案）管理：支持单动作与多动作编排（按持续时长、有效组数及每组次数、距离配置最低/常规量），编辑生成不可变新版本
├── screens/rules_screen.dart       # 周期目标列表、结构化规则编辑器与内置预设激活
└── widgets/                        # 首页/训练卡片、周条与日期格（WeekDayRow/StatusDot/WeekStatusLegend）、运动时段时间线、周进度入口、饮食对话框、动作选择与组录入弹窗、小秒表等组件
test/widget_test.dart               # 首页与各页面 widget 测试（内存数据库 + provider override）
test/database_test.dart             # 训练记录与迁移数据库测试（NativeDatabase.memory()，注入固定 now）
test/set_stopwatch_test.dart        # 组级秒表纯 Dart 测试（注入假时钟）
test/workout_timeline_test.dart     # 时间线条带纯 Dart 测试（跨日裁切与 lane 分配）
test/workout_dialogs_test.dart      # 已记录用时的统一显示口径测试（formatRecordedSeconds）
test/rule_evaluator_test.dart       # 规则 AST 与评估器纯 Dart 测试
```

## 数据库

表：`food_entries`、`favorite_foods`、`exercises`（动作目录，内置项有稳定 `builtinKey`）、`workout_templates`、`template_versions`、`template_exercises`、`template_sets`、`workouts`、`workout_exercises`、`workout_sets`、`rest_marks`、`daily_checkins`（每日睡眠感受、压力与备注）、`rule_sets`（结构化周期目标，预设来源使用 `presetKey`）。`date` 统一经 `AppDatabase.dateOnly()` 归一化，周一为一周起点。当前 `schemaVersion` 为 6：v3→v4 经确认重置发布前开发数据并建立模板/规则模型；v4→v5 增加内置来源键并移除旧 `weekly_exercise_goals`；v5→v6 增加每日状态表。

关键规则：全场至多一场 `inProgress` 训练；补记必须有开始与结束时间，`date` 取开始时间的本地日期；时间条纹表达现实起止跨度，`totalSeconds` 表达有效训练用时，两者不可混用；有效组按动作记录口径（次数/时长/距离）且状态为 `completed` 判断；`totalSeconds` 未知即 null，`session_duration` 返回数据不足而不从动作组推算；训练和模板通过动作 ID 关联，名称只存快照；模板版本不可变，历史训练按版本快照用 `evaluateWorkoutTemplate` 计算，`linkTemplateToWorkout` 按动作 ID（无目录 ID 时回退快照名称）顺序匹配计划动作并分配计划组槽位（`templateSetId`），`clearTemplateLink` 一并清空动作与组的模板槽位关联；整周每日状态 `watchWeekDailyStatus` 按周区间过滤监听并批量预加载计划组与实际组以避免 N+1 查询；周期目标使用 Rule AST，默认激活“每周 3 次且记录 90 分钟”预设，归档后不会自动复活；内置动作幂等写入并可归档。删除训练/动作显式级联，UI 删除前需确认。组级小秒表只存页面内存，全场至多一个组计时；滑动删除撤销会追加新行，不恢复原 sortOrder。

**改表规则**：递增 `schemaVersion` 并在 `AppDatabase` 中补 migration，然后跑 build_runner。常用食物按 name 冲突 upsert（`DoUpdate(target: [favoriteFoods.name])`），新增唯一列冲突时同样需显式指定 target。

## 已知坑

- **widget 测试 pending timer**：drift 取消查询流会调度零时长 Timer，组件树卸载前必须先 `await db.close()`（见 `test/widget_test.dart` 的 `finishTest`）。
- **widget 测试 `db.close()` 挂起（FakeAsync）**：`StreamQueryStore.close()` 会等待零时长 `Timer.run` 完成，测试里 push 过路由时该定时器可能等不到 pump，`await db.close()` 永不返回（表现为整个测试 10 分钟超时）。根治办法：widget 测试用 `DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)` 构造数据库，关闭流同步完成、不走 Timer（见 `test/widget_test.dart` 的 setUp）。
- **ListView 懒加载截断断言**：首页内容超出视口后，离屏 widget 不在树中，`find.text` 会找不到。`pumpHome` 已把测试视口加高（1080x2400）；若视口装不下，先 `tester.scrollUntilVisible` 再断言。
- **flutter_tester 残留**：测试被中断后残留进程可能锁死 `build/native_assets/windows/sqlite3.dll`，导致下次测试失败。执行 `taskkill //F //IM flutter_tester.exe` 后重跑。
- **训练页常驻 Timer 与 pumpAndSettle**：`workout_screen.dart` 有每秒刷新显示的 `Timer.periodic`，widget 测试进入该页后不能再 `pumpAndSettle`（永不 settle），用固定时长 `pump()` 推进；收尾前 `pageBack` 弹出该页让 Timer 随 dispose 取消。
- **Android 工具链**：SDK 在 `D:\Langs\AndroidSDK`（见 `android/local.properties` 的 `sdk.dir`），需 cmdline-tools 并已接受 licenses（`flutter doctor --android-licenses`）。
- **`flutter` 命令在受限沙箱下卡死**：Flutter 工具启动时要在 SDK 自己的 cache 目录（`D:\Q\Scoop\apps\flutter\current\bin\cache\`，在工作区之外）获取 `lockfile` 独占锁；文件沙箱为 workspace-write 时写不进去，表现为 `flutter analyze` / `flutter --version` 长时间无输出（不是分析慢，也不是代码问题）。`dart.exe` 不需要该锁，可直接用 `dart.exe --packages=<flutter_tools>/\.dart_tool/package_config.json <sdk>/bin/cache/flutter_tools.snapshot <args>` 复现同样的 flutter 子命令，或单次提权运行 flutter 命令。

## 约定

- 所有用户可见文本用中文；代码注释保持现有密度（简短说明意图）。
- Git 行尾：`.gitattributes` 锁定 LF（`.bat`/`.cmd` 为 CRLF）。
- 新功能遵循现有模式：drift 查询方法放在 `AppDatabase`，状态放 `providers/`，UI 按 screen/widget 分层。
