import 'package:eduself_study_app/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:eduself_study_app/features/tutoring/domain/entities/chat_message.dart';
import 'package:eduself_study_app/features/tutoring/presentation/providers/tutoring_providers.dart';
import 'package:eduself_study_app/features/tutoring/presentation/providers/tutoring_chat_provider.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TutoringSessionsPage extends ConsumerWidget {
  const TutoringSessionsPage({super.key});

  Future<void> _startSession(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authSessionProvider).valueOrNull;
    if (user == null) return;
    final result =
        await ref.read(createTutoringSessionProvider)(userId: user.id);
    if (!context.mounted) return;
    result.when(
      success: (session) {
        ref.invalidate(tutoringSessionsProvider);
        context.push('/tutoring/${session.id}');
      },
      failure: (failure) => AppToast.error(failure.message),
    );
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    ChatSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete session'),
        content: Text(
          'Delete "${session.title}" and all messages in this session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(deleteTutoringSessionProvider)(session.id);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(tutoringSessionsProvider);
        ref.invalidate(tutoringChatProvider(session.id));
        AppToast.success('Session deleted');
      },
      failure: (failure) => AppToast.error(failure.message),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(tutoringSessionsProvider);

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Học cùng EduSelf'),
        ),
        drawer: const AppDrawer(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _startSession(context, ref),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Buổi học mới'),
        ),
        body: sessions.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Chưa có buổi học nào',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bắt đầu trò chuyện với giáo viên AI. '
                          'Lịch sử chat được lưu trên thiết bị.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () => _startSession(context, ref),
                          child: const Text('Bắt đầu học'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = items[index];
                final scheme = Theme.of(context).colorScheme;
                return GlassCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      session.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Cập nhật: ${session.updatedAtUtc.toLocal()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Delete session',
                          onPressed: () => _deleteSession(context, ref, session),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: scheme.error,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    onTap: () => context.push('/tutoring/${session.id}'),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
        ),
      ),
    );
  }
}
