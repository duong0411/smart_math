import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MathTutorSessionsPage extends ConsumerWidget {
  const MathTutorSessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(mathSessionsProvider);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Gia sư Địa lí AI'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final hasKey =
                (ref.read(geminiApiKeyProvider).valueOrNull ?? '')
                    .trim()
                    .isNotEmpty;
            if (!hasKey) {
              AppToast.error('Cần Gemini API key — vào Cài đặt để dán key.');
              if (context.mounted) context.push('/settings');
              return;
            }
            final session =
                await ref.read(mathLocalStoreProvider).createSession();
            ref.invalidate(mathSessionsProvider);
            if (context.mounted) {
              context.push('/tutor/${session.id}');
            }
          },
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
                      'Chưa có buổi học.\nNhấn “Buổi học mới” để hỏi AI Địa lí.',
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
                        '${s.messages.length} tin nhắn · ${_fmt(s.updatedAt)}',
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
