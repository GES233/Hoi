import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/app_providers.dart';

const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

/// 周条标题的日期格式：「yyyy年M月d日 周X」
String formatWeekDate(DateTime date) =>
    '${DateFormat('yyyy年M月d日').format(date)} ${_weekdays[date.weekday - 1]}';

/// 周条：一行同时承担「选日期」与「看本周落实」。
/// 左右箭头或横向滑动按周切换；点击日期文本弹 DatePicker；
/// 未来日期不可选，也不允许切到本周之后
class WeekStrip extends ConsumerWidget {
  const WeekStrip({super.key, required this.date});

  final DateTime date;

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final today = AppDatabase.dateOnly(ref.read(appClockProvider)());
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
    final today = AppDatabase.dateOnly(ref.watch(appClockProvider)());
    final weekStart = AppDatabase.weekStart(date);
    final isToday = date == today;
    // 不允许切到本周之后
    final canGoNext = !weekStart
        .add(const Duration(days: 7))
        .isAfter(AppDatabase.weekStart(today));
    final notifier = ref.read(selectedDateProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

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
                borderRadius: BorderRadius.circular(10),
                onTap: () => _pickDate(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          formatWeekDate(date),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!isToday)
              TextButton.icon(
                icon: const Icon(Icons.today_rounded, size: 15),
                onPressed: notifier.goToday,
                label: const Text('回到今天'),
              ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: '下一周',
              visualDensity: VisualDensity.compact,
              onPressed: canGoNext ? () => notifier.shift(7) : null,
            ),
          ],
        ),
        const SizedBox(height: 4),
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
          child: WeekDayRow(date: date, onSelectDay: notifier.select),
        ),
      ],
    );
  }
}

/// 一周七天的日期格（周条与周进度页共用）。
/// [onSelectDay] 为空时只作展示，点按不改变全局选中日期。
class WeekDayRow extends ConsumerWidget {
  const WeekDayRow({
    super.key,
    required this.date,
    this.onSelectDay,
    this.followSelectedDate = true,
  });

  final DateTime date;
  final ValueChanged<DateTime>? onSelectDay;
  final bool followSelectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesAsync = followSelectedDate
        ? ref.watch(weekDailyStatusProvider)
        : ref.watch(weekDailyStatusForDateProvider(date));
    final statuses = statusesAsync.value ?? {};
    final today = AppDatabase.dateOnly(ref.watch(appClockProvider)());
    final weekStart = AppDatabase.weekStart(date);

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          _dayCell(
            context,
            weekStart.add(Duration(days: i)),
            statuses[weekStart.add(Duration(days: i))] ?? DailyStatus.none,
            today,
          ),
      ],
    );
  }

  /// 单日格子：圆润胶囊容器 + 星期标签 + 日期数字（选中为实心圆、今天加下划线）+ 状态点
  Widget _dayCell(
    BuildContext context,
    DateTime day,
    DailyStatus status,
    DateTime today,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = followSelectedDate && day == date;
    final isToday = day == today;
    final isFuture = day.isAfter(today);
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    final onSelectDay = this.onSelectDay;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              onSelectDay == null || isFuture ? null : () => onSelectDay(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primaryContainer.withValues(alpha: 0.45)
                  : isToday
                  ? scheme.surfaceContainerHighest.withValues(alpha: 0.45)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: scheme.primary.withValues(alpha: 0.35),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              children: [
                Text(
                  _weekdayLabels[day.weekday - 1],
                  style: labelStyle?.copyWith(
                    color: isSelected
                        ? scheme.primary
                        : isFuture
                        ? scheme.outline
                        : scheme.onSurfaceVariant,
                    fontWeight:
                        isSelected || isToday ? FontWeight.w700 : null,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? scheme.primary : null,
                  ),
                  child: Center(
                    child: Container(
                      decoration: isToday && !isSelected
                          ? BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: scheme.primary,
                                  width: 2,
                                ),
                              ),
                            )
                          : null,
                      child: Text(
                        '${day.day}',
                        style: labelStyle?.copyWith(
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isFuture
                              ? scheme.outline
                              : isSelected
                              ? scheme.onPrimary
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 14,
                  child: Center(child: StatusDot(status: status)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 日期格与图例共用的状态点：无记录（空心灰）/ 有记录未达最低（浅绿描边）/
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

/// 日期格状态点的图例，放在周进度页；按产品要求，未达标不表达为失败。
class WeekStatusLegend extends StatelessWidget {
  const WeekStatusLegend({super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 6,
    children: [
      _item(context, DailyStatus.none, '无记录'),
      _item(context, DailyStatus.recorded, '有记录'),
      _item(context, DailyStatus.minDone, '最低达标'),
      _item(context, DailyStatus.regularDone, '常规达标'),
      _item(context, DailyStatus.rest, '休息'),
    ],
  );

  static Widget _item(BuildContext context, DailyStatus status, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Center(child: StatusDot(status: status)),
          ),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
