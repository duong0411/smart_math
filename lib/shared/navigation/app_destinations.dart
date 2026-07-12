import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';

/// Role-exclusive destinations for hub + drawer (no cross-role overlap).
class AppDestination {
  const AppDestination({
    required this.id,
    required this.label,
    required this.route,
    required this.icon,
    this.subtitle,
    this.comingSoon = false,
  });

  final String id;
  final String label;
  final String route;
  final IconData icon;
  final String? subtitle;
  final bool comingSoon;
}

abstract final class AppDestinations {
  /// Học sinh — học tập & tự luyện.
  static const List<AppDestination> studentHub = [
    AppDestination(
      id: 'tutor',
      label: 'Gia sư AI',
      subtitle: 'Hỏi đáp từng bước',
      route: '/tutoring',
      icon: Icons.smart_toy_rounded,
    ),
    AppDestination(
      id: 'curriculum',
      label: 'Học theo SGK',
      subtitle: 'Môn & chủ đề theo lớp',
      route: '/curriculum',
      icon: Icons.menu_book_rounded,
    ),
    AppDestination(
      id: 'homework',
      label: 'Chụp bài tập',
      subtitle: 'Gửi ảnh cho Gia sư AI',
      route: '/homework-capture',
      icon: Icons.photo_camera_rounded,
    ),
    AppDestination(
      id: 'library',
      label: 'Tài liệu',
      subtitle: 'PDF, Word, Excel, ảnh — hỏi AI',
      route: '/library',
      icon: Icons.folder_rounded,
    ),
    AppDestination(
      id: 'ipa',
      label: 'Tiếng Anh (IPA)',
      subtitle: 'Phát âm chuẩn',
      route: '/ipa',
      icon: Icons.record_voice_over_rounded,
    ),
    AppDestination(
      id: 'assessments',
      label: 'Kiểm tra',
      subtitle: 'Đề được giao & luyện tập',
      route: '/assessments',
      icon: Icons.quiz_rounded,
    ),
    AppDestination(
      id: 'classrooms',
      label: 'Lớp học',
      subtitle: 'Tham gia lớp để nhận đề',
      route: '/classrooms',
      icon: Icons.groups_rounded,
    ),
    AppDestination(
      id: 'study_tools',
      label: 'Flashcard & Mindmap',
      subtitle: 'Ghi nhớ & sơ đồ',
      route: '/study-tools',
      icon: Icons.psychology_alt_rounded,
    ),
    AppDestination(
      id: 'progress',
      label: 'Tiến độ học tập',
      subtitle: 'Thống kê gần đây',
      route: '/progress',
      icon: Icons.insights_rounded,
    ),
    AppDestination(
      id: 'profile',
      label: 'Hồ sơ',
      subtitle: 'Tên, lớp, mã mời phụ huynh',
      route: '/profile',
      icon: Icons.person_rounded,
    ),
  ];

  /// Giáo viên — lớp, đề, chấm, ma trận.
  static const List<AppDestination> teacherHub = [
    AppDestination(
      id: 'classrooms',
      label: 'Lớp học',
      subtitle: 'Tạo lớp, mã tham gia, giao đề',
      route: '/classrooms',
      icon: Icons.groups_rounded,
    ),
    AppDestination(
      id: 'author',
      label: 'Soạn đề',
      subtitle: 'Tạo & xuất bản đề kiểm tra',
      route: '/teachers/assessments',
      icon: Icons.edit_note_rounded,
    ),
    AppDestination(
      id: 'grading',
      label: 'Chấm bài',
      subtitle: 'Chấm tự luận & điểm thủ công',
      route: '/teachers/grading',
      icon: Icons.grading_rounded,
    ),
    AppDestination(
      id: 'matrices',
      label: 'Ma trận đề',
      subtitle: 'Chuẩn đầu ra & độ phủ',
      route: '/exam-matrices',
      icon: Icons.grid_on_rounded,
    ),
  ];

  /// Phụ huynh — theo dõi con (hub chính = danh sách con tại /home).
  /// Drawer chỉ cần lối tắt phụ: cài đặt nằm riêng.
  static const List<AppDestination> parentHub = [
    AppDestination(
      id: 'children',
      label: 'Con của tôi',
      subtitle: 'Liên kết & theo dõi tiến độ',
      route: '/home',
      icon: Icons.family_restroom_rounded,
    ),
  ];

  static const AppDestination settings = AppDestination(
    id: 'settings',
    label: 'Cài đặt',
    subtitle: 'Giao diện & API',
    route: '/settings',
    icon: Icons.settings_rounded,
  );

  static List<AppDestination> hubFor(UserRole? role) {
    return switch (role) {
      UserRole.teacher => teacherHub,
      UserRole.parent => parentHub,
      UserRole.student => studentHub,
      null => const [],
    };
  }

  static String sectionLabelFor(UserRole? role) {
    return switch (role) {
      UserRole.teacher => 'Giảng dạy',
      UserRole.parent => 'Gia đình',
      UserRole.student => 'Học tập',
      null => 'Menu',
    };
  }

  static String homeTitleFor(UserRole? role) {
    return switch (role) {
      UserRole.teacher => 'Cổng giáo viên',
      UserRole.parent => 'Cổng phụ huynh',
      UserRole.student => 'EduSelf',
      null => 'EduSelf',
    };
  }

  /// Prefixes a role may open (beyond /home, /settings, /about, /login).
  static bool isAllowedRoute(UserRole role, String location) {
    if (location == '/home' ||
        location == '/settings' ||
        location == '/about' ||
        location == '/login' ||
        location == '/register') {
      return true;
    }
    return switch (role) {
      UserRole.student =>
        location.startsWith('/tutoring') ||
            location.startsWith('/curriculum') ||
            location.startsWith('/homework-capture') ||
            location.startsWith('/library') ||
            location.startsWith('/ipa') ||
            location.startsWith('/assessments') ||
            location.startsWith('/classrooms') ||
            location.startsWith('/study-tools') ||
            location.startsWith('/progress') ||
            location.startsWith('/profile'),
      UserRole.teacher =>
        location.startsWith('/classrooms') ||
            location.startsWith('/teachers') ||
            location.startsWith('/exam-matrices') ||
            location.startsWith('/assessments'), // read owned detail if needed
      UserRole.parent => location.startsWith('/parents'),
    };
  }
}
