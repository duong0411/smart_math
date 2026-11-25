import 'dart:io';

import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local study reminders for the 5-day review plan (Android / iOS / Windows / macOS).
class StudyReminderService {
  StudyReminderService._();

  static final StudyReminderService instance = StudyReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'eduself_study_reminders';
  static const _channelName = 'Nhắc nhở ôn tập Ngữ văn';
  static const _channelDesc =
      'Thông báo nhắc học sinh thực hiện kế hoạch ôn tập AI';

  /// Notification ids: 1000+day*10 + slot (0 morning, 1 evening, 2 nudge).
  static const _baseId = 1000;

  var _ready = false;

  Future<void> ensureInitialized() async {
    if (_ready) return;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } on Object {
      // Fall back to device local if IANA data missing.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const macOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const windows = WindowsInitializationSettings(
      appName: 'EduSelf Ngữ Văn',
      appUserModelId: 'EduSelf.NguVan.StudyApp.1',
      guid: 'd4e8a1b2-3c4d-5e6f-7890-abcdef123456',
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: ios,
        macOS: macOS,
        windows: windows,
      ),
    );
    _ready = true;
  }

  Future<bool> requestPermissions() async {
    await ensureInitialized();
    var granted = true;

    if (!kIsWeb && Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final notif = await android?.requestNotificationsPermission();
      try {
        await android?.requestExactAlarmsPermission();
      } on Object {
        // Optional on some OEMs.
      }
      granted = notif ?? true;
    } else if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final mac = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      final ok = await (ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          mac?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ));
      granted = ok ?? false;
    }

    return granted;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        windows: WindowsNotificationDetails(),
      );

  Future<void> cancelAllPlanReminders() async {
    await ensureInitialized();
    for (var day = 1; day <= 5; day++) {
      for (var slot = 0; slot < 3; slot++) {
        await _plugin.cancel(id: _baseId + day * 10 + slot);
      }
    }
    // Instant nudge id
    await _plugin.cancel(id: 999);
  }

  /// Schedule morning (07:30) + evening (18:30) reminders for incomplete days.
  Future<void> syncPlanReminders(MathReviewPlan plan) async {
    await ensureInitialized();
    await cancelAllPlanReminders();
    if (!plan.remindersEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final start = tz.TZDateTime(
      tz.local,
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );

    for (final task in plan.days) {
      if (task.done) continue;
      final dayDate = start.add(Duration(days: task.day - 1));
      await _scheduleAt(
        id: _baseId + task.day * 10,
        when: tz.TZDateTime(
          tz.local,
          dayDate.year,
          dayDate.month,
          dayDate.day,
          7,
          30,
        ),
        title: 'Nhắc ôn Ngữ văn — Ngày ${task.day}',
        body: 'Buổi sáng: ${task.title}. Em vào app đánh dấu hoàn thành nhé!',
        after: now,
      );
      await _scheduleAt(
        id: _baseId + task.day * 10 + 1,
        when: tz.TZDateTime(
          tz.local,
          dayDate.year,
          dayDate.month,
          dayDate.day,
          18,
          30,
        ),
        title: 'Chưa ôn xong ngày ${task.day}?',
        body: '${task.title} — mở Giám sát học tập để tiếp tục.',
        after: now,
      );
    }

    // If already behind, nudge again tonight.
    final overdue = plan.overdueTasks;
    if (overdue.isNotEmpty) {
      final tonight = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        19,
        0,
      );
      final when =
          tonight.isAfter(now) ? tonight : tonight.add(const Duration(days: 1));
      await _scheduleAt(
        id: _baseId + overdue.first.day * 10 + 2,
        when: when,
        title: 'Cảnh báo: bỏ lỡ kế hoạch ôn',
        body:
            'Em còn ${overdue.length} ngày chưa ôn (vd: ${overdue.first.title}). Vào học ngay!',
        after: now,
      );
    }
  }

  Future<void> _scheduleAt({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
    required tz.TZDateTime after,
  }) async {
    if (!when.isAfter(after)) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'monitor',
      );
    } on Object {
      // Windows/web may not support zonedSchedule — ignore.
    }
  }

  /// Immediate notification (demo / “nhắc ngay”).
  Future<void> sendImmediateReminder({
    required String title,
    required String body,
  }) async {
    await ensureInitialized();
    await _plugin.show(
      id: 999,
      title: title,
      body: body,
      notificationDetails: _details,
      payload: 'monitor',
    );
  }
}
