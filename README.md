# hoi

一个纯本地的饮食 + 运动记录追踪应用。无后端、无账号、无会员，数据全部存在设备本地。

目标平台：Android、Windows。

## 功能

- 按天记录饮食：餐次（早餐/午餐/晚餐/加餐）、食物名、热量
- 按天记录运动：运动名、时长、消耗热量
- 首页汇总：当日总摄入、总消耗、净热量，可切换日期查看历史
- 常用食物收藏：记录时可存为常用，下次一键填入

## 技术栈

- Flutter / Dart
- [drift](https://drift.simonbinder.eu/) + drift_flutter — 本地 SQLite 数据库
- [flutter_riverpod](https://riverpod.dev/) — 状态管理
- intl — 日期格式化

## 数据表

| 表 | 说明 | 字段 |
|---|---|---|
| `food_entries` | 饮食记录 | id, date, meal_type, name, calories |
| `exercise_entries` | 运动记录 | id, date, name, duration_minutes, calories_burned |
| `favorite_foods` | 常用食物 | id, name (唯一), calories |

定义见 `lib/database/database.dart`。

## 目录结构

```
lib/
├── main.dart                    # 入口，ProviderScope + Material 3
├── database/database.dart       # drift 数据库定义
├── providers/app_providers.dart # riverpod providers
├── screens/home_screen.dart     # 首页
└── widgets/add_entry_dialogs.dart # 添加饮食/运动对话框
```

## 开发

```bash
flutter pub get
dart run build_runner build     # 修改数据表后重新生成代码
flutter analyze
flutter test
flutter run -d windows          # 或 -d <android 设备>
```
