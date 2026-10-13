# 结构化规则与指标系统：阶段 1 交付记录

状态：已完成

## 1. 已实现内容

- 新增可归档动作目录 `exercises`，动作身份使用稳定 `id`。
- 新增 `workout_templates`、`template_versions`、`template_exercises`、`template_sets`。
- 模板编辑通过新增不可变版本完成，训练直接引用精确版本。
- 模板动作与训练动作保存名称、分类、记录类型、负重和次数口径快照。
- 计划组和实际组支持次数、时长、距离、外部负重、辅助重量、RPE、RIR、组角色与完成状态。
- 实际动作、实际组的模板关联均可空，保留自由训练、计划外动作和额外组。
- 从模板开始训练时复制动作快照；新增实际组时按顺序关联尚未使用的计划组。
- 支持每个计划组配置可选最低量；全部最低字段为空时，该组不属于最低完成要求。
- 模板完成度按计划组关联计算，并在训练上保存 `template_evaluation_policy_version = 1`。
- 方案管理 UI 暂以单动作快捷编辑器接入新模型；修改方案会创建新版本，删除入口改为归档。
- 首页、开始训练、训练页实时进度、结束反馈和补记关联均已切换到模板版本 API。
- `schemaVersion` 升至 4；经确认，v3 升级执行一次全表开发数据重置。

重置范围：饮食、常用食物、每周目标、训练及子记录、旧方案、休息标记。全新安装直接创建 v4；已完成 v4 升级后再次打开不会重复重置。

## 2. 改动文件

- `lib/database/database.dart`
- `lib/database/database.g.dart`
- `lib/providers/app_providers.dart`
- `lib/screens/plans_screen.dart`
- `lib/screens/log_workout_screen.dart`
- `lib/screens/workout_screen.dart`
- `lib/widgets/home_cards.dart`
- `lib/widgets/home_workout_cards.dart`
- `lib/widgets/workout_cards.dart`
- `lib/widgets/workout_dialogs.dart`
- `test/database_test.dart`
- `test/widget_test.dart`
- `docs/phase-0-structured-rules-baseline.md`

## 3. 已执行命令

```text
dart run build_runner build
结果：成功，生成 Drift 代码，无生成警告。

flutter analyze
结果：No issues found。

flutter test
结果：36 项测试全部通过。
```

数据库测试覆盖多动作/多组模板、自动计划组关联、可选最低量、跳过和零值组、计划外事实、不可变版本、归档保留历史、评估策略版本，以及 v3→v4 重置只执行一次。

## 4. 未实现内容与限制

- 多动作模板的数据层已完成；完整的多动作可视化编辑器属于阶段 4。当前方案页只创建和编辑单动作的时长或有效组数快捷模板。
- 把一场已经自由录入的训练事后关联到模板时，只保存模板版本元数据，不按动作名称猜测模板动作或计划组。其自由动作和组继续作为计划外事实，因此不会自动补成模板进度。
- 训练页尚未展示计划组、实际组、跳过组和额外组的逐项对照；该 UI 属于阶段 4。
- 指标注册表、Rule AST、规则评估器和 RuleSet 持久化尚未开始，分别属于阶段 2 和阶段 3。

## 5. 手动验证步骤

1. 打开“方案”，新建一个“俯卧撑”有效组数方案，最低量填 1，常规量填 3。
2. 从首页开始运动并选择该方案，确认训练页自动出现“俯卧撑”。
3. 记录 1 组，确认最低计划组完成并出现一次反馈；继续记录到 3 组，确认常规完成。
4. 返回方案页编辑名称或阈值，确认列表版本号增加为 v2。
5. 查看此前训练，确认仍显示开始训练时的模板名称快照并按 v1 解释。
6. 归档方案，确认新训练选择器不再显示它，历史训练仍保留。
