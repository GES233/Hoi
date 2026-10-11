import 'package:flutter_test/flutter_test.dart';

import 'package:hoi/widgets/set_stopwatch.dart';

void main() {
  // 可控假时钟，注入给 SetStopwatch，不用真实等待
  var fakeNow = DateTime(2026, 10, 5, 10, 0, 0);
  void advance(Duration d) => fakeNow = fakeNow.add(d);
  SetStopwatch stopwatch() => SetStopwatch(now: () => fakeNow);

  setUp(() {
    fakeNow = DateTime(2026, 10, 5, 10, 0, 0);
  });

  test('开始→结束得到正确秒数', () {
    final sw = stopwatch();
    expect(sw.elapsedSeconds(), 0);
    sw.start();
    advance(const Duration(seconds: 90));
    expect(sw.elapsedSeconds(), 90);
    expect(sw.stop(), 90);
    // 结束（stop）后复位
    expect(sw.isActive, isFalse);
    expect(sw.elapsedSeconds(), 0);
  });

  test('暂停段不计入累计', () {
    final sw = stopwatch();
    sw.start();
    advance(const Duration(seconds: 30));
    sw.pause();
    advance(const Duration(minutes: 5));
    expect(sw.elapsedSeconds(), 30);
    expect(sw.stop(), 30);
  });

  test('恢复后继续累计', () {
    final sw = stopwatch();
    sw.start();
    advance(const Duration(seconds: 30));
    sw.pause();
    advance(const Duration(minutes: 5));
    sw.resume();
    advance(const Duration(seconds: 45));
    expect(sw.isPaused, isFalse);
    expect(sw.stop(), 75);
  });

  test('重复暂停/恢复各段都不计入', () {
    final sw = stopwatch();
    sw.start();
    advance(const Duration(seconds: 10));
    sw.pause();
    advance(const Duration(seconds: 60));
    sw.resume();
    advance(const Duration(seconds: 20));
    sw.pause();
    advance(const Duration(seconds: 120));
    sw.resume();
    advance(const Duration(seconds: 5));
    expect(sw.stop(), 35);
  });

  test('0 秒停止返回 0，不构成有效组所需的正时长', () {
    final sw = stopwatch();
    sw.start();
    expect(sw.stop(), 0);
  });

  test('未开始时暂停/恢复/停止均无副作用', () {
    final sw = stopwatch();
    sw.pause();
    sw.resume();
    expect(sw.isActive, isFalse);
    expect(sw.stop(), 0);
  });
}
