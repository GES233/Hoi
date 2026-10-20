# hoi 0.2.0 结构化规则与指标系统施工任务

## 目标

在现有本地 Flutter 应用基础上，把训练方案、训练事实、指标和目标规则拆开，
为后续加入卡路里、距离、动作次数、进阶／退阶加权等指标保留扩展能力。

本轮采用“方案 A”：

- 指标由应用内置注册，不允许执行任意用户代码。
- 规则使用结构化 AST 表达，并以 JSON 持久化。
- 支持 `ALL` / `ANY`、比较运算和日／周周期。
- UI 通过结构化控件编辑规则，不实现文本 DSL、语法高亮或脚本执行。
- 计算结果主要即时生成，不新增统计缓存表。

模型、Harness、现有测试运行方式和 provider override 模式保持不变。
不得引入云端服务、账号、同步协议或外部规则执行引擎。

## 当前进度（2026-10-16）

- Stage 0–4 核心链路已完成，并通过代码生成、静态分析和单元测试 / Widget 测试。
- Stage 5 按计划延后（动作目录的 `RepsConvention` 单侧／双侧口径已接入数据层与动作管理页，指标层加权规则留待后续扩展）。
- 方案管理页（`PlansScreen`）已升级为多动作模板编排器：支持在一个方案中添加 / 移除多个计划动作，支持持续时长、有效组数（含每组目标次数）与距离三种口径，以及可选最低量与常规量。
- 补记与编辑训练（`LogWorkoutScreen`）统一采用本地草稿（`_drafts`）原子保存；空草稿选方案自动预填计划动作，事后关联方案（`linkTemplateToWorkout`）自动按动作 ID / 快照名称匹配计划动作并分配计划组槽位。
- 组录入 / 编辑弹窗已支持次数、持续秒数、距离（米）、外加负重、助力重量、RPE、RIR、组角色与完成 / 跳过状态。
- Rule AST 支持递归嵌套；当前结构化 UI 编辑一层 `ALL`／`ANY` 条件列表。
- 后续增量已落地：
  - v5：内置可复用动作目录与运动类型管理页（`ExercisesScreen`）、“记录单项运动”快捷入口；原“每周 3 次／90 分钟”改为默认激活、可编辑和可归档的周期目标预设。
  - v6：新增 `daily_checkins` 每日主观状态表、自然周运动时间线与支持独立翻周的只读周进度页（`WeekProgressScreen`），以及支持高对比度与深浅色切换的 `HoiTheme` 视觉系统。

## 施工原则

1. 先稳定训练事实，再接入规则计算。
2. 指标只通过稳定的领域 API 读取事实，不直接依赖 UI 或具体 Drift 查询细节。
3. 动作身份使用 `exerciseId`，显示名称只作为快照和展示文本。
4. 模板／方案版本一旦被训练使用，不再原地修改。
5. 规则、指标和评估策略都要有版本语义，历史结果不能因后续改公式而悄悄变化。
6. 每个阶段独立可运行、可测试；不一次性重写整个项目。

## 明确不做

- 不实现文本 DSL 或任意表达式执行。
- 不执行用户提供的 Dart、SQL、脚本或动态代码。
- 不在本轮实现复杂目标推荐、AI 训练建议或云端同步。
- 不实现统计缓存、后台任务或跨设备同步。
- 不把训练方案完成度和周目标累计混成一个 `status`。
- 不为了新指标删除或覆盖已有训练事实。

## 目标数据边界

### 训练事实

保留并逐步扩展：

```text
exercises
workout_templates
template_versions
template_exercises
template_sets
workouts
workout_pauses       可先延后，现有 pausedAt/pausedSeconds 可作为过渡
workout_exercises
workout_sets
```

动作记录至少应支持：

```text
exercise_id?
exercise_name_snapshot
tracking_type_snapshot
load_convention_snapshot
reps_convention_snapshot
template_exercise_id?
```

组记录为后续指标预留：

```text
template_set_id?
set_role
set_status
reps?
duration_seconds?
distance_meters?
external_load_kg?
assistance_kg?
rpe?
rir?
```

第一阶段不要求所有字段同时出现在 UI，但新增指标不能依赖无法解释的临时字段。

### 规则定义

第一版可以使用一张表保存结构化表达式：

```text
rule_sets
  id
  name
  period                 day / week
  effective_from_date
  effective_until_date?
  combine_mode           all / any
  expression_json
  evaluation_policy_version
  created_at
```

如果后续需要单独编辑树节点，再将 JSON AST 迁移为 `rule_nodes`；第一版不提前拆表。

## 指标接口

指标必须声明：

```text
metric_id
name
unit
input_scope
aggregation
definition_version
missing_data_policy
```

第一版内置指标：

```text
session_count       已完成训练场次数
session_duration    已完成训练整场用时，单位秒
valid_set_count     有效组数量
reps                有效组次数合计
duration            动作持续时间合计，单位秒
distance            距离合计，单位米
```

后续可加入：

```text
recorded_calories
estimated_calories
weighted_reps
```

`recorded_calories` 与 `estimated_calories` 必须分开。估算指标必须记录估算策略版本，
不能把估算值伪装成用户实际记录值。

## 规则 AST

至少支持以下节点：

```text
ComparisonRule
  metric_id
  filters
  operator: >= / > / = / <= / <
  target

AllRule
  children[]

AnyRule
  children[]
```

指标过滤条件第一版支持：

```text
exercise_id?
category?
set_role?
```

示例：

```json
{
  "type": "all",
  "children": [
    {
      "type": "comparison",
      "metric": "session_count",
      "exerciseId": 1,
      "operator": ">=",
      "target": 3
    },
    {
      "type": "comparison",
      "metric": "duration",
      "exerciseId": 2,
      "operator": ">=",
      "target": 1800
    }
  ]
}
```

评估结果至少有：

```text
passed
partial
failed
insufficient_data
actual
target
unit
reasons
missing_fields
policy_version
```

缺失数据不能未经定义直接当作零。例如要求动作时长而记录没有时长时，
应按指标的 `missing_data_policy` 返回数据不足或明确的零值语义。

## 阶段 0：现状和设计基线

只做检查、设计和测试样例，不修改业务代码。

- [x] 记录现有 `exercise_plans`、`workouts`、`workout_exercises`、`workout_sets` 的差距。
- [x] 确认从单动作方案迁移到模板版本的最小数据模型。
- [x] 确认动作目录建立和旧动作名称回填策略。
- [x] 确认训练方案完成度与周期目标的边界。
- [x] 写出至少 5 个规则 JSON 样例及预期结果。
- [x] 确认 `schemaVersion` 迁移策略；经确认，v4 对发布前开发数据执行一次性重置。

交付：设计说明、字段清单、规则样例、阻塞问题（最多 3 个）。

## 阶段 1：动作身份与训练模型基础

- [x] 新增 `exercises`，支持归档而非删除历史动作。
- [x] 给 `workout_exercises` 增加动作 ID 和记录口径快照。
- [x] 将方案从单动作结构迁移为模板、版本、模板动作、模板组。
- [x] 给实际动作和实际组增加可选的模板关联。
- [x] 保留自由训练和计划外动作。
- [x] 保证已使用模板版本不可被编辑覆盖。
- [x] 更新 Drift 生成代码和数据库迁移。

验收：一个模板版本可以包含多个动作，每个动作可以包含多个计划组；
编辑模板后，历史训练仍按原快照解释。

## 阶段 2：指标注册表与规则评估器

- [x] 定义 `MetricDefinition`、`MetricContext`、`MetricValue` 接口。
- [x] 实现 `session_count`、`session_duration`、`valid_set_count`、`reps`、`duration`、`distance`。
- [x] 定义单位、聚合方式和缺失数据策略。
- [x] 定义 Rule AST 的 Dart 模型和 JSON 编解码。
- [x] 实现 `RuleEvaluator`，支持比较、`ALL`、`ANY`。
- [x] 输出可解释结果，不只返回布尔值。
- [x] 为 evaluator 加纯 Dart 单元测试，不依赖 widget 和真实时间。

验收：同一组训练事实可以被不同 RuleSet 评估；改变 UI 不影响评估结果。

## 阶段 3：RuleSet 持久化与编辑 UI

- [x] 新增 `rule_sets` 表及 Drift 查询方法。
- [x] 支持创建、编辑、归档 RuleSet。
- [x] 支持选择周期：每日／每周。
- [x] 支持选择指标、动作过滤、比较运算和目标值。
- [x] 支持 `ALL`／`ANY` 组合。
- [x] 对不完整规则显示校验错误，不保存不可评估规则。
- [x] 不加入文本 DSL 输入框。

验收：用户可以在 UI 中创建“每周 3 次训练 AND 每周跑步 1800 秒”，
重启应用后规则仍能恢复并正确评估。

## 阶段 4：训练页和首页接入

- [x] 训练页使用模板版本生成多个动作和计划组。
- [x] 进度卡改为显示结构化评估结果，不再假设单动作双阈值。
- [x] 动作卡可显示计划组、实际组和额外组的差异。
- [x] 首页使用 `GoalProgressDto` 或等效组合对象显示目标进度。
- [x] 保留现有开始、补记、暂停、结束、删除和撤销能力。
- [x] 不让周目标计算替代单次训练的计划完成度。

验收：计划内多个动作、计划外动作、额外组、跳过组均能在页面上区分；
编辑实际记录后，相关结果自动刷新。

## 阶段 5：后续指标扩展（本轮可延后）

- [ ] `recorded_calories`：仅统计用户实际填写或导入的热量。
- [ ] `estimated_calories`：明确估算输入、来源和策略版本。
- [ ] `weighted_reps`：按 `set_role`、进阶／退阶等级、单双侧或其他明确字段加权。
- [x] 增加动作单侧／双侧次数口径（`RepsConvention` 已落库并接入 `ExercisesScreen` 管理与训练快照）。
- [ ] 为新指标补充缺失数据和单位测试。

不允许为了支持这些指标而把原始事实改写成派生结果。

## 测试清单

### 数据库与业务

- [x] 多动作、多组只计一次训练场次。
- [x] 规则按动作 ID 过滤，不按显示名称猜测身份。
- [x] 有效组、跳过组、零次组的指标结果正确。
- [x] 时长单位统一为秒，距离单位统一为米。
- [x] `ALL` 与 `ANY` 的组合结果正确。
- [x] 数据缺失返回 `insufficient_data` 或既定零值语义。
- [x] 模板编辑不改变历史训练快照。
- [x] 规则编辑不改变原始训练事实。
- [ ] 指标定义版本改变时，历史结果可按旧策略重现。（当前已持久化 `metricVersion` 并拒绝未知版本；尚未注册两个指标实现版本进行回放测试。）
- [x] 删除或归档动作不会删除训练历史。

### Widget

- [x] RuleSet 创建和编辑表单可用。
- [x] 不完整规则显示校验错误。
- [x] 多动作训练进度不截断或错位。
- [x] 计划完成度与周期目标进度分开显示。
- [x] 现有饮食入口、开始训练、补记入口仍可用。

沿用现有内存数据库、provider override、可控时钟和 widget 测试收尾约定。
不能使用 `pumpAndSettle` 等待带常驻计时器的训练页。

## 工程约定

- 数据库查询放 AppDatabase。
- 状态放 providers/。
- UI 按 screen/widget 分层。
- 不把所有新增界面堆进一个超大文件。
- 延续现有中文注释风格。
- 修改 drift 表后运行代码生成。
- Riverpod 按当前版本 API 编写。
- 加载、空数据与错误状态分开处理。
- 不通过吞异常或统一返回空列表掩盖错误。
- 不引入不必要依赖。
- 不顺手修改无关文件。

## 每阶段交付格式

1. 已实现内容。
2. 改动文件。
3. 实际执行的代码生成、分析和测试命令及结果。
4. 未实现内容、限制和环境问题。
5. 手动验证步骤。

未实际执行的命令不得声称通过。数据库清空、破坏性迁移和历史数据删除必须先确认。
