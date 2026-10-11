import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:eduself_study_app/shared/widgets/grade_level_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MathTutorSessionsPage extends ConsumerWidget {
  const MathTutorSessionsPage({super.key});

  Future<void> _startNewSession(BuildContext context, WidgetRef ref) async {
    final hasKey =
        (ref.read(geminiApiKeyProvider).valueOrNull ?? '').trim().isNotEmpty;
    if (!hasKey) {
      AppToast.error('Cần Gemini API key — vào Cài đặt để dán key.');
      if (context.mounted) context.push('/settings');
      return;
    }

    final profileGrade = ref.read(mathProfileProvider).valueOrNull?.gradeLevel;
    final grade = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _GradePickSheet(
        initialGrade: SupportedGrades.normalize(profileGrade),
      ),
    );
    if (grade == null || !context.mounted) return;

    final session = await ref.read(mathLocalStoreProvider).createSession(
          gradeLevel: grade,
        );

    // Keep profile in sync so practice / games default to the same grade.
    final profile = ref.read(mathProfileProvider).valueOrNull;
    if (profile != null && profile.gradeLevel != grade) {
      await ref.read(mathProfileProvider.notifier).save(
            profile.copyWith(gradeLevel: grade),
          );
    }

    ref.invalidate(mathSessionsProvider);
    if (context.mounted) {
      context.push('/tutor/${session.id}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionsAsync = ref.watch(mathSessionsProvider);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Gia sư Toán AI',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _startNewSession(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Buổi học mới'),
        ),
        body: SafeArea(
          child: sessionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Lỗi: $e')),
            data: (sessions) {
              if (sessions.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: isDark ? 0.2 : 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.psychology_rounded,
                              size: 36,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Chưa có buổi học nào',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nhấn nút bên dưới để chọn lớp và bắt đầu hỏi đáp bài tập, ôn luyện công thức toán cùng AI.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.45,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 22),
                          FilledButton.icon(
                            onPressed: () => _startNewSession(context, ref),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Bắt đầu buổi học mới'),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Mẹo: Em có thể chụp ảnh đề bài để AI nhận diện và giải từng bước!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: sessions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  final gradeLabel =
                      s.gradeLevel != null ? 'Lớp ${s.gradeLevel}' : 'Chung';

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          gradeLabel,
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        '${s.messages.length} tin nhắn · ${_fmt(s.updatedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        tooltip: 'Xoá buổi học',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xoá buổi học'),
                              content: Text('Em có chắc muốn xoá buổi học "${s.title}" không?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Huỷ'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Xoá'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(mathLocalStoreProvider)
                                .deleteSession(s.id);
                            ref.invalidate(mathSessionsProvider);
                          }
                        },
                      ),
                      onTap: () => context.push('/tutor/${s.id}'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime utc) {
    final local = utc.toLocal();
    return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _GradePickSheet extends StatefulWidget {
  const _GradePickSheet({required this.initialGrade});

  final int initialGrade;

  @override
  State<_GradePickSheet> createState() => _GradePickSheetState();
}

class _GradePickSheetState extends State<_GradePickSheet> {
  late int _grade;

  @override
  void initState() {
    super.initState();
    _grade = SupportedGrades.normalize(widget.initialGrade);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Chọn lớp cho buổi học',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gia sư AI sẽ dạy theo chương trình Toán THCS (${SupportedGrades.labelShort}).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            GradeLevelSelector(
              value: _grade,
              onChanged: (g) => setState(() => _grade = g),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, _grade),
              icon: const Icon(Icons.chat_rounded),
              label: Text('Bắt đầu · Lớp $_grade'),
            ),
          ],
        ),
      ),
    );
  }
}
