import 'dart:convert';

import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only persistence for Math AI tutoring & monitoring.
class MathLocalStore {
  MathLocalStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _cache;

  static const _studentKey = 'math_student_profile';
  static const _sessionsKey = 'math_tutor_sessions';
  static const _eventsKey = 'math_study_events';
  static const _practiceKey = 'math_practice_attempts';
  static const _reviewPlanKey = 'math_review_plan';

  Future<SharedPreferences> _prefs() async {
    return _cache ??= _prefsOverride ?? await SharedPreferences.getInstance();
  }

  // —— Student profile ——

  Future<MathStudentProfile> readProfile() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_studentKey);
    if (raw == null || raw.isEmpty) return MathStudentProfile.empty;
    try {
      return MathStudentProfile.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      return MathStudentProfile.empty;
    }
  }

  Future<void> writeProfile(MathStudentProfile profile) async {
    final prefs = await _prefs();
    await prefs.setString(_studentKey, jsonEncode(profile.toJson()));
  }

  // —— Tutor sessions ——

  Future<List<MathTutorSession>> listSessions() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) MathTutorSession.fromJson(item),
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } on Object {
      return [];
    }
  }

  Future<void> _saveSessions(List<MathTutorSession> sessions) async {
    final prefs = await _prefs();
    await prefs.setString(
      _sessionsKey,
      jsonEncode([for (final s in sessions) s.toJson()]),
    );
  }

  Future<MathTutorSession> createSession({
    String? title,
    String? topic,
    int? gradeLevel,
  }) async {
    final sessions = await listSessions();
    final now = DateTime.now().toUtc();
    final grade =
        gradeLevel == null ? null : SupportedGrades.normalize(gradeLevel);
    final session = MathTutorSession(
      id: now.millisecondsSinceEpoch.toString(),
      title: (title?.trim().isNotEmpty == true)
          ? title!.trim()
          : (topic?.trim().isNotEmpty == true
              ? 'Ngữ văn: ${topic!.trim()}'
              : (grade != null
                  ? 'Buổi học Ngữ văn lớp $grade'
                  : 'Buổi học Ngữ văn')),
      topic: topic?.trim(),
      gradeLevel: grade,
      messages: const [],
      createdAt: now,
      updatedAt: now,
    );
    sessions.insert(0, session);
    await _saveSessions(sessions);
    return session;
  }

  Future<MathTutorSession?> getSession(String id) async {
    final sessions = await listSessions();
    for (final s in sessions) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<MathTutorSession> appendMessage({
    required String sessionId,
    required MathChatMessage message,
  }) async {
    final sessions = await listSessions();
    final index = sessions.indexWhere((s) => s.id == sessionId);
    if (index < 0) {
      throw StateError('Session not found');
    }
    final current = sessions[index];
    final updated = current.copyWith(
      messages: [...current.messages, message],
      updatedAt: DateTime.now().toUtc(),
      title: current.messages.isEmpty && message.role == MathChatRole.user
          ? _titleFrom(message.content)
          : current.title,
    );
    sessions[index] = updated;
    await _saveSessions(sessions);
    return updated;
  }

  Future<void> deleteSession(String id) async {
    final sessions = await listSessions();
    await _saveSessions(sessions.where((s) => s.id != id).toList());
  }

  String _titleFrom(String content) {
    final oneLine = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (oneLine.isEmpty) return 'Buổi học Ngữ văn';
    return oneLine.length <= 42 ? oneLine : '${oneLine.substring(0, 42)}…';
  }

  // —— Study events (monitoring) ——

  Future<List<MathStudyEvent>> listEvents() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_eventsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) MathStudyEvent.fromJson(item),
      ]..sort((a, b) => b.at.compareTo(a.at));
    } on Object {
      return [];
    }
  }

  Future<void> addEvent(MathStudyEvent event) async {
    final events = await listEvents();
    events.insert(0, event);
    // Keep last 200 events
    final trimmed = events.take(200).toList();
    final prefs = await _prefs();
    await prefs.setString(
      _eventsKey,
      jsonEncode([for (final e in trimmed) e.toJson()]),
    );
  }

  // —— Practice attempts ——

  Future<List<MathPracticeAttempt>> listAttempts() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_practiceKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) MathPracticeAttempt.fromJson(item),
      ]..sort((a, b) => b.at.compareTo(a.at));
    } on Object {
      return [];
    }
  }

  Future<void> addAttempt(MathPracticeAttempt attempt) async {
    final attempts = await listAttempts();
    attempts.insert(0, attempt);
    final trimmed = attempts.take(100).toList();
    final prefs = await _prefs();
    await prefs.setString(
      _practiceKey,
      jsonEncode([for (final a in trimmed) a.toJson()]),
    );
    await addEvent(
      MathStudyEvent(
        id: attempt.id,
        type: MathStudyEventType.practice,
        topic: attempt.topic,
        detail: attempt.correct ? 'Đúng' : 'Sai',
        correct: attempt.correct,
        at: attempt.at,
      ),
    );
  }

  // —— Review plan (5-day) + reminder flags ——

  Future<MathReviewPlan?> readReviewPlan() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_reviewPlanKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return MathReviewPlan.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      return null;
    }
  }

  Future<void> writeReviewPlan(MathReviewPlan plan) async {
    final prefs = await _prefs();
    await prefs.setString(_reviewPlanKey, jsonEncode(plan.toJson()));
  }

  Future<void> clearReviewPlan() async {
    final prefs = await _prefs();
    await prefs.remove(_reviewPlanKey);
  }
}

class MathStudentProfile {
  const MathStudentProfile({
    required this.displayName,
    required this.gradeLevel,
    this.focusTopics = const [],
  });

  static const empty = MathStudentProfile(displayName: '', gradeLevel: null);

  final String displayName;
  final int? gradeLevel;
  final List<String> focusTopics;

  bool get isComplete =>
      displayName.trim().isNotEmpty && gradeLevel != null;

  MathStudentProfile copyWith({
    String? displayName,
    int? gradeLevel,
    List<String>? focusTopics,
  }) {
    return MathStudentProfile(
      displayName: displayName ?? this.displayName,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      focusTopics: focusTopics ?? this.focusTopics,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'gradeLevel': gradeLevel,
        'focusTopics': focusTopics,
      };

  factory MathStudentProfile.fromJson(Map<String, dynamic> json) {
    final topics = json['focusTopics'];
    final rawGrade = json['gradeLevel'] as int?;
    return MathStudentProfile(
      displayName: json['displayName'] as String? ?? '',
      gradeLevel:
          rawGrade == null ? null : SupportedGrades.normalize(rawGrade),
      focusTopics: [
        if (topics is List)
          for (final t in topics)
            if (t is String) t,
      ],
    );
  }
}

enum MathChatRole { user, model }

class MathChatMessage {
  const MathChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.at,
    this.imageBase64,
    this.imageMimeType,
  });

  final String id;
  final MathChatRole role;
  final String content;
  final DateTime at;
  final String? imageBase64;
  final String? imageMimeType;

  bool get hasImage =>
      imageBase64 != null && imageBase64!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'at': at.toIso8601String(),
        if (imageBase64 != null) 'imageBase64': imageBase64,
        if (imageMimeType != null) 'imageMimeType': imageMimeType,
      };

  factory MathChatMessage.fromJson(Map<String, dynamic> json) {
    return MathChatMessage(
      id: json['id'] as String? ?? '',
      role: (json['role'] as String?) == 'model'
          ? MathChatRole.model
          : MathChatRole.user,
      content: json['content'] as String? ?? '',
      at: DateTime.tryParse(json['at'] as String? ?? '') ??
          DateTime.now().toUtc(),
      imageBase64: json['imageBase64'] as String?,
      imageMimeType: json['imageMimeType'] as String?,
    );
  }
}

class MathTutorSession {
  const MathTutorSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.topic,
    this.gradeLevel,
  });

  final String id;
  final String title;
  final String? topic;
  final int? gradeLevel;
  final List<MathChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  MathTutorSession copyWith({
    String? title,
    String? topic,
    int? gradeLevel,
    List<MathChatMessage>? messages,
    DateTime? updatedAt,
  }) {
    return MathTutorSession(
      id: id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'topic': topic,
        'gradeLevel': gradeLevel,
        'messages': [for (final m in messages) m.toJson()],
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MathTutorSession.fromJson(Map<String, dynamic> json) {
    final msgs = json['messages'];
    return MathTutorSession(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Buổi học Ngữ văn',
      topic: json['topic'] as String?,
      gradeLevel: () {
        final raw = json['gradeLevel'] as int?;
        return raw == null ? null : SupportedGrades.normalize(raw);
      }(),
      messages: [
        if (msgs is List)
          for (final m in msgs)
            if (m is Map<String, dynamic>) MathChatMessage.fromJson(m),
      ],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

enum MathStudyEventType { tutor, practice, monitor, game, reminder }

class MathReviewDayTask {
  const MathReviewDayTask({
    required this.day,
    required this.title,
    required this.detail,
    this.done = false,
    this.completedAt,
  });

  final int day;
  final String title;
  final String detail;
  final bool done;
  final DateTime? completedAt;

  MathReviewDayTask copyWith({
    String? title,
    String? detail,
    bool? done,
    DateTime? completedAt,
  }) {
    return MathReviewDayTask(
      day: day,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      done: done ?? this.done,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'title': title,
        'detail': detail,
        'done': done,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory MathReviewDayTask.fromJson(Map<String, dynamic> json) {
    return MathReviewDayTask(
      day: json['day'] as int? ?? 1,
      title: json['title'] as String? ?? 'Ôn tập',
      detail: json['detail'] as String? ?? '',
      done: json['done'] as bool? ?? false,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }
}

enum MathReviewCompliance { none, onTrack, behind, completed }

class MathReviewPlan {
  const MathReviewPlan({
    required this.id,
    required this.reportText,
    required this.days,
    required this.createdAt,
    required this.startDate,
    this.remindersEnabled = true,
  });

  final String id;
  final String reportText;
  final List<MathReviewDayTask> days;
  final DateTime createdAt;

  /// Local calendar date (date-only) when day 1 begins.
  final DateTime startDate;
  final bool remindersEnabled;

  int get doneCount => days.where((d) => d.done).length;

  bool get isCompleted => days.isNotEmpty && days.every((d) => d.done);

  /// 1–5 for the calendar day relative to [startDate]; 0 before start; >5 after.
  int dayIndexOn(DateTime localNow) {
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return today.difference(start).inDays + 1;
  }

  List<MathReviewDayTask> get overdueTasks {
    final idx = dayIndexOn(DateTime.now());
    return [
      for (final d in days)
        if (!d.done && d.day < idx) d,
    ];
  }

  MathReviewDayTask? get todayTask {
    final idx = dayIndexOn(DateTime.now());
    for (final d in days) {
      if (d.day == idx) return d;
    }
    return null;
  }

  MathReviewCompliance get compliance {
    if (days.isEmpty) return MathReviewCompliance.none;
    if (isCompleted) return MathReviewCompliance.completed;
    if (overdueTasks.isNotEmpty) return MathReviewCompliance.behind;
    return MathReviewCompliance.onTrack;
  }

  String get complianceLabel => switch (compliance) {
        MathReviewCompliance.none => 'Chưa có kế hoạch',
        MathReviewCompliance.onTrack => 'Đang theo đúng kế hoạch',
        MathReviewCompliance.behind =>
          'Cảnh báo: HS chưa ôn ${overdueTasks.length} ngày',
        MathReviewCompliance.completed => 'Đã hoàn thành 5 ngày ôn',
      };

  MathReviewPlan copyWith({
    String? reportText,
    List<MathReviewDayTask>? days,
    bool? remindersEnabled,
  }) {
    return MathReviewPlan(
      id: id,
      reportText: reportText ?? this.reportText,
      days: days ?? this.days,
      createdAt: createdAt,
      startDate: startDate,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reportText': reportText,
        'days': [for (final d in days) d.toJson()],
        'createdAt': createdAt.toIso8601String(),
        'startDate':
            '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        'remindersEnabled': remindersEnabled,
      };

  factory MathReviewPlan.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['days'];
    final startRaw = json['startDate'] as String? ?? '';
    final startParsed = DateTime.tryParse(startRaw);
    final created =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now().toUtc();
    final start = startParsed != null
        ? DateTime(startParsed.year, startParsed.month, startParsed.day)
        : DateTime(created.toLocal().year, created.toLocal().month,
            created.toLocal().day);

    return MathReviewPlan(
      id: json['id'] as String? ?? '',
      reportText: json['reportText'] as String? ?? '',
      days: [
        if (daysRaw is List)
          for (final d in daysRaw)
            if (d is Map<String, dynamic>) MathReviewDayTask.fromJson(d),
      ],
      createdAt: created,
      startDate: start,
      remindersEnabled: json['remindersEnabled'] as bool? ?? true,
    );
  }

  /// Build a plan from AI text + optional weak topics (fallback tasks).
  static MathReviewPlan fromAiReport({
    required String reportText,
    required List<String> weakTopics,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final parsed = _parsePlanJson(reportText);
    final displayText = _stripPlanJson(reportText).trim();
    final days = parsed.isNotEmpty
        ? parsed
        : _fallbackDays(weakTopics);

    return MathReviewPlan(
      id: now.millisecondsSinceEpoch.toString(),
      reportText: displayText.isEmpty ? reportText : displayText,
      days: days,
      createdAt: now.toUtc(),
      startDate: start,
      remindersEnabled: true,
    );
  }

  static List<MathReviewDayTask> _fallbackDays(List<String> weakTopics) {
    final topics = weakTopics.isEmpty
        ? const [
            'Đọc hiểu văn bản',
            'Từ ngữ & tiếng Việt',
            'Tập làm văn nghị luận',
            'Ôn ngữ liệu KNTT',
            'Luyện đề tổng hợp',
          ]
        : [
            ...weakTopics.take(5),
            ...List.filled(5, 'Ôn Ngữ văn'),
          ].take(5).toList();

    return [
      for (var i = 0; i < 5; i++)
        MathReviewDayTask(
          day: i + 1,
          title: 'Ngày ${i + 1}: ${topics[i]}',
          detail:
              'Ôn chủ đề "${topics[i]}" 20–30 phút: đọc ngữ liệu + làm 1 bài luyện.',
        ),
    ];
  }

  static final _planJsonRe = RegExp(
    r'<<<PLAN_JSON\s*([\s\S]*?)\s*PLAN_JSON>>>',
    multiLine: true,
  );

  static List<MathReviewDayTask> _parsePlanJson(String text) {
    final match = _planJsonRe.firstMatch(text);
    if (match == null) return const [];
    try {
      final decoded = jsonDecode(match.group(1)!.trim());
      if (decoded is! List) return const [];
      final out = <MathReviewDayTask>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        out.add(
          MathReviewDayTask(
            day: map['day'] as int? ?? out.length + 1,
            title: (map['title'] as String?)?.trim().isNotEmpty == true
                ? (map['title'] as String).trim()
                : 'Ngày ${out.length + 1}',
            detail: (map['detail'] as String?)?.trim() ?? '',
          ),
        );
      }
      out.sort((a, b) => a.day.compareTo(b.day));
      return out.take(5).toList();
    } on Object {
      return const [];
    }
  }

  static String _stripPlanJson(String text) {
    return text.replaceAll(_planJsonRe, '').trim();
  }
}

class MathStudyEvent {
  const MathStudyEvent({
    required this.id,
    required this.type,
    required this.topic,
    required this.detail,
    required this.at,
    this.correct,
  });

  final String id;
  final MathStudyEventType type;
  final String topic;
  final String detail;
  final bool? correct;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'topic': topic,
        'detail': detail,
        'correct': correct,
        'at': at.toIso8601String(),
      };

  factory MathStudyEvent.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'tutor';
    return MathStudyEvent(
      id: json['id'] as String? ?? '',
      type: MathStudyEventType.values.firstWhere(
        (t) => t.name == typeName,
        orElse: () => MathStudyEventType.tutor,
      ),
      topic: json['topic'] as String? ?? 'Ngữ văn',
      detail: json['detail'] as String? ?? '',
      correct: json['correct'] as bool?,
      at: DateTime.tryParse(json['at'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

class MathPracticeAttempt {
  const MathPracticeAttempt({
    required this.id,
    required this.topic,
    required this.question,
    required this.studentAnswer,
    required this.feedback,
    required this.correct,
    required this.at,
  });

  final String id;
  final String topic;
  final String question;
  final String studentAnswer;
  final String feedback;
  final bool correct;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'question': question,
        'studentAnswer': studentAnswer,
        'feedback': feedback,
        'correct': correct,
        'at': at.toIso8601String(),
      };

  factory MathPracticeAttempt.fromJson(Map<String, dynamic> json) {
    return MathPracticeAttempt(
      id: json['id'] as String? ?? '',
      topic: json['topic'] as String? ?? 'Ngữ văn',
      question: json['question'] as String? ?? '',
      studentAnswer: json['studentAnswer'] as String? ?? '',
      feedback: json['feedback'] as String? ?? '',
      correct: json['correct'] as bool? ?? false,
      at: DateTime.tryParse(json['at'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}
