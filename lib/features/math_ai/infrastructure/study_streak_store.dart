import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Chuỗi ngày học tập (Streak/Stack) theo đề xuất khách EduSelf Ngữ Văn.
class StudyStreakStore {
  StudyStreakStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _cache;

  static const _key = 'study_streak_v1';

  Future<SharedPreferences> _prefs() async {
    return _cache ??= _prefsOverride ?? await SharedPreferences.getInstance();
  }

  Future<StudyStreakState> read() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return StudyStreakState.empty;
    try {
      return StudyStreakState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      ).reconcileForToday();
    } on Object {
      return StudyStreakState.empty;
    }
  }

  Future<StudyStreakState> write(StudyStreakState state) async {
    final prefs = await _prefs();
    await prefs.setString(_key, jsonEncode(state.toJson()));
    return state;
  }

  /// Ghi nhận 1 nhiệm vụ thực chất trong ngày (luyện tập / thắng game / hoàn ngày ôn).
  Future<StudyStreakState> recordMeaningfulStudy({
    required String reason,
  }) async {
    final current = await read();
    final today = StudyStreakState.todayKey();
    if (current.lastStudyDay == today && current.studiedToday) {
      return current;
    }

    final yesterday = StudyStreakState.dayKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    var streak = 1;
    var freeze = current.freezeCards;

    if (current.lastStudyDay == yesterday) {
      streak = current.currentStreak + 1;
    } else if (current.lastStudyDay != null &&
        current.lastStudyDay != today) {
      final gap = StudyStreakState.daysBetween(current.lastStudyDay!, today);
      if (gap == 2 && freeze > 0) {
        freeze -= 1;
        streak = current.currentStreak + 1;
      } else {
        streak = 1;
      }
    } else if (current.lastStudyDay == today) {
      streak = current.currentStreak <= 0 ? 1 : current.currentStreak;
    }

    var essence = current.essencePoints + 10;
    final freezesAwarded = {...current.freezeMilestonesAwarded};
    for (final m in const [7, 14, 30]) {
      if (streak >= m && !freezesAwarded.contains(m)) {
        freeze += 1;
        freezesAwarded.add(m);
      }
    }

    return write(
      StudyStreakState(
        currentStreak: streak,
        bestStreak: streak > current.bestStreak ? streak : current.bestStreak,
        lastStudyDay: today,
        studiedToday: true,
        freezeCards: freeze,
        essencePoints: essence,
        freezeMilestonesAwarded: freezesAwarded,
        lastReason: reason,
      ),
    );
  }

  Future<StudyStreakState> addEssence(int points) async {
    final current = await read();
    return write(
      current.copyWith(essencePoints: current.essencePoints + points),
    );
  }

  Future<StudyStreakState?> redeemFreezeCard() async {
    final current = await read();
    if (current.essencePoints < 40) return null;
    return write(
      current.copyWith(
        essencePoints: current.essencePoints - 40,
        freezeCards: current.freezeCards + 1,
      ),
    );
  }
}

class StudyStreakState {
  const StudyStreakState({
    required this.currentStreak,
    required this.bestStreak,
    required this.lastStudyDay,
    required this.studiedToday,
    required this.freezeCards,
    required this.essencePoints,
    required this.freezeMilestonesAwarded,
    this.lastReason,
  });

  static const empty = StudyStreakState(
    currentStreak: 0,
    bestStreak: 0,
    lastStudyDay: null,
    studiedToday: false,
    freezeCards: 0,
    essencePoints: 0,
    freezeMilestonesAwarded: {},
  );

  final int currentStreak;
  final int bestStreak;
  final String? lastStudyDay;
  final bool studiedToday;
  final int freezeCards;
  final int essencePoints;
  final Set<int> freezeMilestonesAwarded;
  final String? lastReason;

  int get stackBooks => currentStreak.clamp(0, 5);

  bool get booksOpen => currentStreak > 0 && (studiedToday || _isYesterdayOk);

  bool get _isYesterdayOk {
    if (lastStudyDay == null) return false;
    final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    return lastStudyDay == yesterday || lastStudyDay == todayKey();
  }

  String get titleLabel {
    if (currentStreak >= 100) return 'Nhà phê bình Trẻ';
    if (currentStreak >= 30) return 'Cây bút Triển vọng';
    if (currentStreak >= 7) return 'Mầm non Văn học';
    if (currentStreak >= 1) return 'Khởi đầu tri thức';
    return 'Chưa mở chuỗi';
  }

  StudyStreakState copyWith({
    int? currentStreak,
    int? bestStreak,
    String? lastStudyDay,
    bool? studiedToday,
    int? freezeCards,
    int? essencePoints,
    Set<int>? freezeMilestonesAwarded,
    String? lastReason,
  }) {
    return StudyStreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastStudyDay: lastStudyDay ?? this.lastStudyDay,
      studiedToday: studiedToday ?? this.studiedToday,
      freezeCards: freezeCards ?? this.freezeCards,
      essencePoints: essencePoints ?? this.essencePoints,
      freezeMilestonesAwarded:
          freezeMilestonesAwarded ?? this.freezeMilestonesAwarded,
      lastReason: lastReason ?? this.lastReason,
    );
  }

  StudyStreakState reconcileForToday() {
    final today = todayKey();
    if (lastStudyDay == null) return this;
    if (lastStudyDay == today) {
      return copyWith(studiedToday: studiedToday);
    }
    final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    if (lastStudyDay == yesterday) {
      return copyWith(studiedToday: false);
    }
    final gap = daysBetween(lastStudyDay!, today);
    if (gap == 2 && freezeCards > 0) {
      return copyWith(
        freezeCards: freezeCards - 1,
        lastStudyDay: yesterday,
        studiedToday: false,
      );
    }
    if (gap >= 2) {
      return copyWith(currentStreak: 0, studiedToday: false);
    }
    return copyWith(studiedToday: false);
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastStudyDay': lastStudyDay,
        'studiedToday': studiedToday,
        'freezeCards': freezeCards,
        'essencePoints': essencePoints,
        'freezeMilestonesAwarded': freezeMilestonesAwarded.toList(),
        'lastReason': lastReason,
      };

  factory StudyStreakState.fromJson(Map<String, dynamic> json) {
    final milestones = json['freezeMilestonesAwarded'];
    return StudyStreakState(
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      lastStudyDay: json['lastStudyDay'] as String?,
      studiedToday: json['studiedToday'] as bool? ?? false,
      freezeCards: json['freezeCards'] as int? ?? 0,
      essencePoints: json['essencePoints'] as int? ?? 0,
      freezeMilestonesAwarded: {
        if (milestones is List)
          for (final m in milestones)
            if (m is int) m,
      },
      lastReason: json['lastReason'] as String?,
    );
  }

  static String todayKey() => dayKey(DateTime.now());

  static String dayKey(DateTime d) {
    final local = d.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static int daysBetween(String a, String b) {
    final da = DateTime.tryParse(a);
    final db = DateTime.tryParse(b);
    if (da == null || db == null) return 99;
    return DateTime(db.year, db.month, db.day)
        .difference(DateTime(da.year, da.month, da.day))
        .inDays;
  }
}
