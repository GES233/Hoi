# 结构化规则与指标系统：阶段 0 设计基线

状态：已确认，可进入阶段 1

基于：`TASK.md`，当前数据库 `schemaVersion = 3`

范围：只做现状审计、模型设计和测试规划，不修改业务代码或数据库。

## 1. 现状差距

| 现有对象 | 已有能力 | 与目标模型的差距 |
| --- | --- | --- |
| `exercise_plans` | 单动作；动作名称和分类；`duration` / `sets`；最低、常规双阈值 | 动作靠名称而不是 ID；不能包含多个动作或计划组；原地更新且物理删除；没有版本、归档和口径快照 |
| `workouts` | 训练生命周期、暂停累计、可空总时长；保存旧方案名称、动作、指标和双阈值快照 | 只能关联单动作方案；没有 `template_version_id`；没有模板版本名称快照；方案评估没有策略版本 |
| `workout_exercises` | 归属训练、名称、分类、备注、排序 | 没有动作目录 ID、模板动作 ID；没有 tracking/load/reps 口径快照；当前评估仍按名称匹配 |
| `workout_sets` | 次数、持续秒数、重量、备注、排序 | 没有模板组 ID、组角色、完成/跳过状态、距离、外部负重与辅助重量区分、RPE/RIR；现有“有效组”只认 `reps > 0` 或 `duration_seconds > 0`，无法计入距离组 |

现有训练生命周期可以保留。`startWorkout` 已保证应用层幂等，暂停和未知总时长也有明确语义。现有方案快照能抵抗方案后续编辑或删除，但只适用于按动作名称累计的旧双阈值模型。

## 2. 已确定的边界

### 2.1 训练事实

- `workouts.status` 只表示训练生命周期（进行中、已完成），不承载模板完成度或周期目标结果。
- 结束训练只要求至少一个有效且未跳过的实际组；是否达到模板计划或周期目标不阻止结束。
- 原始训练记录只由训练编辑流程修改。规则编辑、指标版本变化和模板编辑不得回写训练事实。
- 训练引用精确的 `template_version_id`。模板产生新版本后，旧训练仍引用旧版本。
- 实际动作和实际组允许不关联模板，以保留自由训练、计划外动作和额外组。
- 模板可以定义可选最低量。最低量是单次训练的最小承诺，不是日/周累计目标；未达最低仍允许保存训练。

### 2.2 两种进度

| 概念 | 计算范围 | 输入 | 输出 | 是否跨训练 |
| --- | --- | --- | --- | --- |
| 模板完成度 | 单次训练 | 精确模板版本、计划动作/组、该训练的实际动作/组 | 计划组、实际组、跳过组、额外组的差异 | 否 |
| 周期目标 | 某日或某周 | 已完成训练事实、内置指标、Rule AST、评估策略版本 | `GoalProgressDto` 或等效结构化结果 | 是 |

现有 `weekly_exercise_goals` 在阶段 1、2 暂时保留，只为保证首页功能连续；其旧值不迁移为 RuleSet。阶段 3 接入 RuleSet 后再移除这个兼容入口。

## 3. 阶段 1 最小数据模型

数据库中的枚举值建议保存为稳定英文文本。Dart 枚举声明顺序不能成为持久化协议。

### 3.1 动作目录 `exercises`

| 字段 | 类型 | 约束/语义 |
| --- | --- | --- |
| `id` | integer | 主键 |
| `name` | text | 当前显示名；允许以后改名 |
| `category` | text | `cardio` / `resistance` / `core` / `functional` |
| `tracking_type` | text | `reps` / `duration` / `distance` |
| `load_convention` | text | `none` / `external` / `assistance` / `bodyweight` |
| `reps_convention` | text | `total` / `per_side` |
| `archived_at` | datetime? | 归档后不出现在新建选择器中，但不可级联删除历史 |
| `created_at` | datetime | 创建时间 |

不对 `name` 单列加唯一约束。迁移匹配只用于回填，运行时身份始终使用 `id`。

### 3.2 模板与不可变版本

`workout_templates`

| 字段 | 类型 | 约束/语义 |
| --- | --- | --- |
| `id` | integer | 主键 |
| `current_version_number` | integer | 当前展示版本号；更新时与新版本同一事务提交 |
| `archived_at` | datetime? | 归档而非物理删除 |
| `created_at` | datetime | 创建时间 |

`template_versions`

| 字段 | 类型 | 约束/语义 |
| --- | --- | --- |
| `id` | integer | 主键，训练直接引用此 ID |
| `template_id` | integer | 引用 `workout_templates.id`，不级联删除 |
| `version_number` | integer | 与 `template_id` 组成唯一键 |
| `name` | text | 版本内名称，保证历史展示稳定 |
| `note` | text? | 版本内说明 |
| `created_at` | datetime | 创建时间 |

`template_exercises`

| 字段 | 类型 | 约束/语义 |
| --- | --- | --- |
| `id` | integer | 主键 |
| `template_version_id` | integer | 引用不可变版本 |
| `exercise_id` | integer | 引用动作目录，不级联删除 |
| `exercise_name_snapshot` | text | 版本创建时的名称 |
| `category_snapshot` | text | 版本创建时的分类 |
| `tracking_type_snapshot` | text | 版本创建时的记录口径 |
| `load_convention_snapshot` | text | 版本创建时的负重口径 |
| `reps_convention_snapshot` | text | 版本创建时的次数口径 |
| `note` | text? | 动作说明 |
| `sort_order` | integer | 版本内排序；与版本组成唯一键 |

`template_sets`

| 字段 | 类型 | 约束/语义 |
| --- | --- | --- |
| `id` | integer | 主键 |
| `template_exercise_id` | integer | 引用模板动作 |
| `set_role` | text | 首版至少支持 `work`，为 `warmup` 等预留 |
| `reps` | integer? | 计划次数 |
| `minimum_reps` | integer? | 可选最低次数；空表示该组不属于最低量 |
| `duration_seconds` | integer? | 计划时长，单位秒 |
| `minimum_duration_seconds` | integer? | 可选最低时长，单位秒 |
| `distance_meters` | real? | 计划距离，单位米 |
| `minimum_distance_meters` | real? | 可选最低距离，单位米 |
| `external_load_kg` | real? | 外部负重 |
| `assistance_kg` | real? | 辅助重量 |
| `rpe` | real? | 计划 RPE |
| `rir` | real? | 计划 RIR |
| `sort_order` | integer | 动作内排序；与模板动作组成唯一键 |

模板不迁移旧方案的最低/常规数值，但新模板允许显式配置最低量。常规字段描述完整计划；同一组的 `minimum_*` 描述最低目标，全为空表示最低版本可以跳过该组。例如三组深蹲只给第一组填写 `minimum_reps`，即可表达“最低一组、常规三组”；一组跑步可同时表达“最低 600 秒、常规 1800 秒”。第一版不支持“多个动作任选一个”这类模板内 `ANY` 规则。

### 3.3 实际训练增量字段

`workouts` 新增：

- `template_version_id?`
- `template_name_snapshot?`
- `template_evaluation_policy_version?`

旧 `plan_*` 快照列不进入新 schema；不存在需要继续解释的正式 v3 训练数据。

`workout_exercises` 新增或重命名为：

- `exercise_id?`
- `exercise_name_snapshot`（现有 `name` 的语义化名称）
- `category_snapshot`（现有 `category` 的语义化名称）
- `tracking_type_snapshot`
- `load_convention_snapshot`
- `reps_convention_snapshot`
- `template_exercise_id?`

`exercise_id` 保持可空，以支持显式的临时动作；从动作目录选择或从模板生成的动作必须写 ID。

`workout_sets` 新增或重命名为：

- `template_set_id?`
- `set_role`，新组默认 `work`
- `set_status`，新组默认 `completed`；首版支持 `completed` / `skipped`
- `distance_meters?`
- `external_load_kg?`（替代现有 `weight_kg`）
- `assistance_kg?`
- `rpe?`
- `rir?`

`reps` 和 `duration_seconds` 保留。有效组定义调整为：`set_status == completed`，并且当前 tracking type 对应的事实值大于零。其他已填写字段不能把缺少核心事实的组变成有效组。

## 4. 动作目录初始化策略

用户已确认当前数据库没有需要保留的正式训练记录，因此不从 v3 动作名称自动回填目录，也不做名称合并：

1. v4 动作目录从空表开始。
2. 用户创建动作时立即分配 ID，并明确选择分类和 tracking type。
3. 模板和训练从第一次写入起按动作 ID 建立关系；名称只保存快照。
4. 同名动作可以共存，不用名称推测身份。
5. 后续动作改名只修改目录；已经产生的模板和训练继续展示各自快照。

## 5. 指标与缺失数据基线

| metric ID | 单位 | 输入范围 | 聚合 | definition version | 首版缺失策略 |
| --- | --- | --- | --- | --- | --- |
| `session_count` | `session` | 已完成训练 | 去重训练 ID 后计数 | 1 | 周期内无训练为明确的 0 |
| `valid_set_count` | `set` | 已完成、未跳过的组 | 计数 | 1 | 无匹配组为 0；身份无法解析且有 ID 过滤时为数据不足 |
| `reps` | `rep` | 有效次数组 | 求和 | 1 | 匹配到组但次数为空为数据不足；无匹配组为 0 |
| `duration` | `second` | 有效时长组 | 求和 | 1 | 匹配到组但时长为空为数据不足；无匹配组为 0 |
| `distance` | `meter` | 有效距离组 | 求和 | 1 | 匹配到组但距离为空为数据不足；无匹配组为 0 |

带 `exercise_id` 过滤时只按 ID 匹配，绝不回退到显示名称。`category` 读取动作记录快照；`set_role` 读取组事实。每个 Comparison 节点持久化 `metricVersion`，RuleSet 另行持久化 `evaluation_policy_version`。

首版状态合成规则：

- Comparison：比较成立为 `passed`；必需字段缺失为 `insufficient_data`；对正向阈值已有大于 0 的进度但未达标为 `partial`；其余为 `failed`。
- `ALL`：任一 `failed` 则 `failed`；否则任一数据不足则 `insufficient_data`；否则任一 `partial` 则 `partial`；否则 `passed`。
- `ANY`：任一 `passed` 则 `passed`；否则任一数据不足则 `insufficient_data`；否则任一 `partial` 则 `partial`；否则 `failed`。

## 6. 规则 JSON 样例与预期结果

统一测试事实：周期为 2026-10-05 至 2026-10-11。共有 3 场已完成训练；动作 `exerciseId=1` 为深蹲，动作 `exerciseId=2` 为跑步。未特别说明时，组均为 `completed/work`。

### 样例 1：多动作仍只计训练场次

```json
{"type":"comparison","metric":"session_count","metricVersion":1,"filters":{},"operator":">=","target":3}
```

事实：3 场训练共含 5 个动作、12 组。

预期：`passed`，`actual=3`，`target=3`，`unit=session`。

### 样例 2：按动作 ID 累计时长

```json
{"type":"comparison","metric":"duration","metricVersion":1,"filters":{"exerciseId":2},"operator":">=","target":1800}
```

事实：跑步组为 600 秒和 1200 秒；另一个同名但 `exerciseId=9` 的动作有 3600 秒。

预期：`passed`，`actual=1800`；ID 9 的事实不计入。

### 样例 3：ALL 中一个子规则只有部分进度

```json
{"type":"all","children":[{"type":"comparison","metric":"session_count","metricVersion":1,"filters":{},"operator":">=","target":3},{"type":"comparison","metric":"duration","metricVersion":1,"filters":{"exerciseId":2},"operator":">=","target":1800}]}
```

事实：训练场次为 3，跑步时长为 1500 秒。

预期：整体 `partial`；两个子结果依次为 `passed(actual=3)`、`partial(actual=1500)`。

### 样例 4：ANY 有一个子规则通过

```json
{"type":"any","children":[{"type":"comparison","metric":"reps","metricVersion":1,"filters":{"exerciseId":1},"operator":">=","target":50},{"type":"comparison","metric":"duration","metricVersion":1,"filters":{"exerciseId":2},"operator":">=","target":1800}]}
```

事实：深蹲 30 次，跑步 1800 秒。

预期：整体 `passed`；子结果分别为 `partial(actual=30)`、`passed(actual=1800)`。

### 样例 5：缺少必需事实不能当作零

```json
{"type":"comparison","metric":"duration","metricVersion":1,"filters":{"exerciseId":2},"operator":">=","target":600}
```

事实：存在一个跑步实际组，但 `duration_seconds=null`。

预期：`insufficient_data`，`actual=null`，`missing_fields=["duration_seconds"]`，原因指出匹配记录缺少时长。

### 样例 6：跳过组与零次组不是有效组

```json
{"type":"comparison","metric":"valid_set_count","metricVersion":1,"filters":{"exerciseId":1,"setRole":"work"},"operator":">=","target":2}
```

事实：深蹲有一组 `completed/reps=10`、一组 `skipped/reps=10`、一组 `completed/reps=0`。

预期：`partial`，`actual=1`，跳过组和零次组不计入。

### 样例 7：距离单位固定为米

```json
{"type":"comparison","metric":"distance","metricVersion":1,"filters":{"category":"cardio"},"operator":">=","target":5000}
```

事实：两组距离分别为 3200 米、1800 米。

预期：`passed`，`actual=5000`，`unit=meter`；不接受“5”并猜测其单位为千米。

所有结果同时携带 `policy_version=1`、`reasons` 和子结果。`actual` 只在同一单位下聚合。

## 7. schemaVersion 与重置策略

用户已明确授权不保留当前开发数据库。阶段 1 将 schema 从 v3 升到 v4，并执行一次显式的破坏性重置：

1. `schemaVersion` 仍升到 4，使已安装的开发版本能够识别结构变化。
2. `from < 4` 时按外键依赖顺序删除旧表，再用当前 schema 重新创建，不编写旧方案、动作或周目标的数据转换。
3. 重置范围覆盖饮食、收藏、周目标、训练、方案和休息标记；实现前再次在变更说明中明确列出。
4. 全新安装直接通过 `onCreate` 创建 v4，不经过重置分支。
5. 这是发布前的一次性开发决策；开始正式记录后，后续 schema 变更必须恢复增量迁移和历史数据保护。

计划使用的 Drift 工具命令（阶段 1 实施时才执行）：

```bash
dart run drift_dev schema dump lib/database/database.dart drift_schemas/
dart run build_runner build
flutter analyze
flutter test
```

数据库测试至少覆盖：

- 带任意 v3 测试数据的数据库升级后旧数据为空，v4 表可以正常写入。
- v3→v4 重置后的 schema 与全新创建的 v4 schema 一致。
- 第二次打开 v4 数据库不会再次重置数据。
- 动作、模板、版本、模板动作和模板组的外键及唯一约束正确。
- 归档动作或模板不会删除训练事实。

## 8. 阶段 1 实施顺序

1. 新增稳定文本枚举及动作目录、模板四表。
2. 按新模型重建训练事实表，不保留旧 `exercise_plans` 和 `plan_*` 字段。
3. 实现 v3→v4 一次性重置，并验证重置只执行一次。
4. 更新数据库 API，再按现有 screen/widget 分层接入 UI。
5. 生成 Drift 代码，运行数据库测试、全部单元/widget 测试和静态分析。

## 9. 已确认事项

1. 不迁移旧 duration/sets 双阈值；新模板重新提供可选最低量，并与常规计划同时保存在模板版本中。
2. 不从旧动作名称回填目录；新数据从第一次记录起使用动作 ID。
3. 不迁移旧周目标值；`weekly_exercise_goals` 只在 RuleSet 接管首页前临时保留功能。

阶段 1 当前没有阻塞项。
