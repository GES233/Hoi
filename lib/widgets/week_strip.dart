import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';

const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

/// 周条标题的日期格式：「yyyy年M月d日 周X」
String formatWeekDate(DateTime date) =>
    '${DateFormat('yyyy年M月d日').format(date)} ${_weekdays[date.weekday - 1]}';

/// 周条：一行同时承担「选日期」与「看本周落实」。
/// 左右箭头或横向滑动按周切换；点击日期文本弹 DatePicker；
/// 未来日期不可选，也不允许切到本周之后
class WeekStrip extends ConsumerWidget {
  const WeekStrip({super.key, required this.date});

  final DateTime date;

  static const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final today = AppDatabase.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: date.isAfter(today) ? today : date,
      firstDate: DateTime(2020),
      lastDate: today,
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).select(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(weekDailyStatusProvider).value ?? {};
    final today = AppDatabase.dateOnly(DateTime.now());
    final weekStart = AppDatabase.weekStart(date);
    final isToday = date == today;
    // 不允许切到本周之后
    final canGoNext = !weekStart
        .add(const Duration(days: 7))
        .isAfter(AppDatabase.weekStart(today));
    final notifier = ref.read(selectedDateProvider.notifier);

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: '上一周',
              visualDensity: VisualDensity.compact,
              onPressed: () => notifier.shift(-7),
            ),
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(context, ref),
                child: Center(
                  child: Text(
                    formatWeekDate(date),
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (!isToday)
              TextButton(
                onPressed: notifier.goToday,
                child: const Text('回到今天'),
              ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: '下一周',
              visualDensity: VisualDensity.compact,
              onPressed: canGoNext ? () => notifier.shift(7) : null,
            ),
          ],
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -150) {
              if (canGoNext) notifier.shift(7);
            } else if (v > 150) {
              notifier.shift(-7);
            }
          },
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                _dayCell(
                  context,
                  ref,
                  weekStart.add(Duration(days: i)),
                  statuses[weekStart.add(Duration(days: i))] ??
                      DailyStatus.none,
                  today,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 单日格子：星期标签 + 日期数字（选中为实心圆、今天加下划线）+ 状态点
  Widget _dayCell(BuildContext context, WidgetRef ref, DateTime day,
      DailyStatus status, DateTime today) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = day == date;
    final isToday = day == today;
    final isFuture = day.isAfter(today);
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return Expanded(
      child: InkWell(
        onTap: isFuture
            ? null
            : () => ref.read(selectedDateProvider.notifier).select(day),
        child: Column(
          children: [
            Text(_weekdayLabels[day.weekday - 1], style: labelStyle),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? scheme.primary : null,
              ),
              child: Center(
                child: Container(
                  decoration: isToday && !isSelected
                      ? BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: scheme.primary, width: 2),
                          ),
                        )
                      : null,
                  child: Text(
                    '${day.day}',
                    style: labelStyle?.copyWith(
                      color: isFuture
                          ? scheme.outline
                          : isSelected
                              ? scheme.onPrimary
                              : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 14,
              child: Center(child: StatusDot(status: status)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 周条与图例共用的状态点：无记录（空心灰）/ 有记录未达最低（浅绿描边）/
/// 最低达标（实心绿）/ 常规达标（实心绿 + 外圈）/ 休息（小月亮）。
/// 不使用红色或叉号，未达标不表达为失败
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.status});

  final DailyStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case DailyStatus.rest:
        return Icon(Icons.bedtime_outlined, size: 12, color: scheme.secondary);
      case DailyStatus.minDone:
        return _circle(color: scheme.primary);
      case DailyStatus.regularDone:
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary, width: 1.5),
          ),
          child: Center(child: _circle(size: 8, color: scheme.primary)),
        );
      case DailyStatus.recorded:
        return _circle(border: scheme.primary);
      case DailyStatus.noPlan:
      case DailyStatus.none:
        return _circle(border: scheme.outlineVariant);
    }
  }

  static Widget _circle({double size = 10, Color? color, Color? border}) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: border != null ? Border.all(color: border, width: 1.5) : null,
        ),
      );
}
