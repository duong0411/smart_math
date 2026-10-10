import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
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
      builder: (ctx) => _GradePickSheet(initialGrade: profileGrade ?? 8),
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
    final sessionsAsync = ref.watch(mathSessionsProvider);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Gia sư Toán AI'),
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
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Chưa có buổi học.\nNhấn “Buổi học mới”, chọn lớp, rồi hỏi AI Toán.',
                      textAlign: TextAlign.center,
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
                      s.gradeLevel != null ? 'Lớp ${s.gradeLevel} · ' : '';
                  return GlassCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '$gradeLabel${s.messages.length} tin nhắn · ${_fmt(s.updatedAt)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref
                              .read(mathLocalStoreProvider)
                              .deleteSession(s.id);
                          ref.invalidate(mathSessionsProvider);
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
    _grade = widget.initialGrade.clamp(1, 12);
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
              'Gia sư AI sẽ dạy theo chương trình Toán lớp đã chọn (1–12).',
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
