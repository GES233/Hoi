/// 组级小秒表：纯 Dart 计时逻辑，时钟可注入便于测试。
/// 计时状态只保存在页面内存，不落库；应用被杀会丢失正在走的这一组，
/// 这是与开发者确认的既定取舍（简单版方案）。
class SetStopwatch {
  SetStopwatch({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  DateTime? _startedAt;
  DateTime? _pausedAt;
  var _pausedSeconds = 0;

  bool get isActive => _startedAt != null;
  bool get isPaused => _pausedAt != null;

  void start() {
    _startedAt ??= _now();
  }

  void pause() {
    if (_startedAt == null || _pausedAt != null) return;
    _pausedAt = _now();
  }

  void resume() {
    final pausedAt = _pausedAt;
    if (pausedAt == null) return;
    _pausedSeconds += _now().difference(pausedAt).inSeconds;
    _pausedAt = null;
  }

  /// 当前累计秒数（显式暂停段不计入）
  int elapsedSeconds() {
    final startedAt = _startedAt;
    if (startedAt == null) return 0;
    final t = _now();
    var elapsed = t.difference(startedAt).inSeconds - _pausedSeconds;
    final pausedAt = _pausedAt;
    if (pausedAt != null) elapsed -= t.difference(pausedAt).inSeconds;
    return elapsed < 0 ? 0 : elapsed;
  }

  /// 结束并返回累计秒数；调用后秒表复位
  int stop() {
    final result = elapsedSeconds();
    _startedAt = null;
    _pausedAt = null;
    _pausedSeconds = 0;
    return result;
  }
}
