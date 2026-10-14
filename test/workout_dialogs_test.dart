import 'package:flutter_test/flutter_test.dart';

import 'package:hoi/widgets/workout_dialogs.dart';

void main() {
  // 已记录用时的统一口径：0 秒与「没记录」（null）分开处理，
  // 非零但不足一分钟不能显示成 0 分钟。
  group('formatRecordedSeconds', () {
    test('0 秒是 0 分钟', () {
      expect(formatRecordedSeconds(0), '0 分钟');
    });

    test('非零但不足一分钟显示不足 1 分钟', () {
      expect(formatRecordedSeconds(1), '不足 1 分钟');
      expect(formatRecordedSeconds(59), '不足 1 分钟');
    });

    test('整分钟不带小数', () {
      expect(formatRecordedSeconds(60), '1 分钟');
      expect(formatRecordedSeconds(2400), '40 分钟');
      expect(formatRecordedSeconds(3600), '60 分钟');
    });

    test('含零头时保留一位小数，整分钟不受零头影响', () {
      expect(formatRecordedSeconds(90), '1.5 分钟');
      expect(formatRecordedSeconds(66), '1.1 分钟');
      expect(formatRecordedSeconds(59 * 60 + 30), '59.5 分钟');
      expect(formatRecordedSeconds(29 * 60 + 50), '29.8 分钟');
    });
  });
}
