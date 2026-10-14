part of '../database.dart';

extension DailyCheckinDao on AppDatabase {
  Stream<DailyCheckin?> watchDailyCheckin(DateTime date) =>
      (select(dailyCheckins)
            ..where((row) => row.date.equals(AppDatabase.dateOnly(date))))
          .watchSingleOrNull();

  Future<void> saveDailyCheckin(
    DateTime date, {
    int? sleepRating,
    int? stressRating,
    String? note,
    DateTime? now,
  }) async {
    _validateRating(sleepRating, '睡眠感受');
    _validateRating(stressRating, '压力');
    final day = AppDatabase.dateOnly(date);
    final normalizedNote = note?.trim();
    if (sleepRating == null &&
        stressRating == null &&
        (normalizedNote == null || normalizedNote.isEmpty)) {
      await (delete(dailyCheckins)..where((row) => row.date.equals(day))).go();
      return;
    }

    final timestamp = now ?? DateTime.now();
    await into(dailyCheckins).insert(
      DailyCheckinsCompanion.insert(
        date: day,
        sleepRating: Value(sleepRating),
        stressRating: Value(stressRating),
        note: Value(
          normalizedNote == null || normalizedNote.isEmpty
              ? null
              : normalizedNote,
        ),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
      onConflict: DoUpdate(
        (old) => DailyCheckinsCompanion(
          sleepRating: Value(sleepRating),
          stressRating: Value(stressRating),
          note: Value(
            normalizedNote == null || normalizedNote.isEmpty
                ? null
                : normalizedNote,
          ),
          updatedAt: Value(timestamp),
        ),
        target: [dailyCheckins.date],
      ),
    );
  }

  void _validateRating(int? value, String label) {
    if (value != null && (value < 1 || value > 5)) {
      throw ArgumentError('$label必须在 1–5 之间');
    }
  }
}
