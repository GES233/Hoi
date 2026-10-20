# 结构化规则与指标系统：阶段 2–4 交付记录

状态：核心链路已完成

## 1. 已实现内容

### 阶段 2：指标与评估器

- 新增与 Drift、Riverpod、Widget 解耦的 `MetricContext` 训练事实 DTO。
- 内置注册 `session_count`、`session_duration`、`valid_set_count`、`reps`、`duration`、`distance`；整场用时未知时不从动作组推算。
- 每个指标声明稳定 ID、名称、单位、输入范围、聚合方式、定义版本和缺失数据策略。
- 实现 `ComparisonRule`、`AllRule`、`AnyRule` 及 JSON 编解码。
- 实现带解释结果的 `RuleEvaluator`，输出通过、部分进度、失败、数据不足、实际值、目标、单位、原因、缺失字段和策略版本。
- 动作过滤只使用 `exerciseId`；类别和组角色使用事实快照，不回退到名称匹配。

### 阶段 3：RuleSet 持久化与编辑

- 新增 `rule_sets` 表，保存日/周周期、生效日期、ALL/ANY、AST JSON 和评估策略版本。
- “每周 3 次且记录 90 分钟”改为默认激活的内置 RuleSet 预设；用户可编辑、归档或再次启用。
- 支持创建、编辑、归档、有效期过滤、数据库重开恢复和实时评估。
- 新增结构化编辑页，支持指标、动作、类别、组角色、比较运算、目标值及多条件组合。
- 表单阻止空名称、空目标值、无效数字、错误日期和根组合不一致的规则保存。
- 编辑器不提供 DSL、脚本或任意表达式入口。

### 阶段 4：页面接入

- 首页把单次模板完成度与日/周周期目标分成两个独立区块。
- 周期目标展示达成、进行中、未开始、数据不足及各子指标实际值/目标值。
- 从模板开始训练会生成版本内全部动作，支持多个动作和多个计划组。
- 训练页进度卡按计划组显示最低/常规完成度，不再假设单动作双阈值。
- 动作卡区分计划动作、计划外动作、计划组、额外组、跳过组、未达目标和未记录计划组。
- 组录入支持次数、秒、米、重量、组角色和完成/跳过状态。
- 原有开始、补记、暂停、结束、删除、滑动删除与撤销流程继续保留。

## 2. 改动文件

- `lib/domain/rules/metric.dart`
- `lib/domain/rules/rule_ast.dart`
- `lib/domain/rules/rule_evaluator.dart`
- `lib/database/database.dart`
- `lib/database/database.g.dart`
- `lib/providers/app_providers.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/rules_screen.dart`
- `lib/screens/workout_screen.dart`
- `lib/screens/log_workout_screen.dart`
- `lib/widgets/home_cards.dart`
- `lib/widgets/workout_cards.dart`
- `lib/widgets/workout_dialogs.dart`
- `test/database_test.dart`
- `test/rule_evaluator_test.dart`
- `test/widget_test.dart`

## 3. 已执行命令

```text
dart run build_runner build
结果：成功，Drift 生成完成，无生成警告。

flutter analyze
结果：No issues found。

flutter test
结果：53 项测试全部通过。
```

纯 Dart 规则测试覆盖六个内置指标、动作 ID 过滤、单位、跳过/零值组、缺失数据、比较规则、ALL/ANY 合成和 JSON 往返。数据库与 widget 测试覆盖 RuleSet CRUD、预设激活、v4→v5 迁移、有效期、重开恢复、训练事实不被规则编辑修改、结构化表单校验、多动作训练对照和首页两类进度分区。

## 4. 未实现内容与限制（阶段 2–4 交付时快照）

> **后续更新注记（2026-10-16）**：
> - 方案管理页（`PlansScreen`）已在 `f8d200e` 升级为多动作模板编排器（支持多个计划动作及持续时长 / 有效组数与每组目标次数 / 距离三种口径）。
> - 补记与编辑训练事后关联模板（`linkTemplateToWorkout`）已在 `f8d200e` 支持按动作目录 ID（或无目录 ID 时的快照名称）顺序匹配计划动作并自动绑定计划组槽位（`templateSetId`），补记空草稿下选择方案还会自动预填计划动作。
> - 首页的“周期目标”卡片已在 `6fcda87` / `46d888d` 迁入独立翻周的只读“周进度”页（`WeekProgressScreen`），首页保留紧凑的“周进度”入口。

- 阶段 2–4 交付时，方案管理页仍是单动作模板快捷编辑器：多动作模板的数据模型、开始训练和训练页展示已完成，但面向用户的完整多动作模板编排器尚未实现。
- 规则编辑器首版编辑一层 ALL/ANY 条件列表；AST 模型和评估器可以递归处理嵌套节点，但 UI 尚不编辑嵌套树。
- 已经自由录入的训练事后关联模板时，不按名称猜测动作身份或计划组；这些记录继续作为计划外事实。
- 旧 `weekly_exercise_goals` 兼容入口已在 v5 移除，首页目标统一由 RuleSet 评估和展示。
- Stage 5 的 `recorded_calories`、`estimated_calories`、`weighted_reps` 和进阶/退阶权重明确延后，未伪装为本轮完成。

## 5. 手动验证步骤

1. 在首页打开“目标”，新建每周目标，添加“训练次数不少于 3”和“跑步时长不少于 1800 秒”，选择“全部满足”。
2. 返回首页，确认“今日方案”和“周期目标”为两个独立区块，目标显示当前实际值和目标值。
3. 新增或补记训练，给动作选择正确记录方式，并录入次数、秒或米；确认首页目标自动刷新。
4. 从多动作模板开始训练，确认全部计划动作出现；记录、跳过或追加组后，检查计划组/额外组状态。
5. 编辑 RuleSet 后确认训练记录没有变化；归档 RuleSet 后确认它不再出现在当前目标中。
