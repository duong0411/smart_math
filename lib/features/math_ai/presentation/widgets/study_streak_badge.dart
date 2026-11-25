import 'package:eduself_study_app/features/math_ai/infrastructure/study_streak_store.dart';
import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Badge Chuỗi học tập (Streak/Stack) — góc phải khung chào trang chủ.
class StudyStreakBadge extends ConsumerWidget {
  const StudyStreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(studyStreakProvider).valueOrNull ??
        StudyStreakState.empty;
    final open = streak.booksOpen;
    final color = open ? const Color(0xFFD97706) : const Color(0xFF94A3B8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSheet(context, ref, streak),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: [
              if (open)
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BookStack(
                count: open ? streak.stackBooks.clamp(1, 5) : 1,
                open: open,
              ),
              const SizedBox(height: 4),
              Text(
                '${streak.currentStreak}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: color,
                ),
              ),
              Text(
                'ngày',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSheet(
    BuildContext context,
    WidgetRef ref,
    StudyStreakState streak,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chuỗi học tập (Stack)',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                streak.booksOpen
                    ? 'Sách đang mở — em duy trì ${streak.currentStreak} ngày liên tiếp.'
                    : 'Sách đóng — học 1 nhiệm vụ thực chất hôm nay để mở lại chuỗi.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              _InfoRow('Chuỗi hiện tại', '${streak.currentStreak} ngày'),
              _InfoRow('Kỷ lục', '${streak.bestStreak} ngày'),
              _InfoRow('Danh hiệu', streak.titleLabel),
              _InfoRow('Thẻ giữ sách mở', '${streak.freezeCards}'),
              _InfoRow('Điểm Tinh Hoa', '${streak.essencePoints}'),
              if (streak.lastReason != null)
                _InfoRow('Lần gần nhất', streak.lastReason!),
              const SizedBox(height: 14),
              Text(
                'Tính chuỗi khi: thắng game Ngữ văn, hoàn thành ngày ôn, hoặc làm đúng bài luyện.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final next = await ref
                      .read(studyStreakStoreProvider)
                      .redeemFreezeCard();
                  ref.invalidate(studyStreakProvider);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (next == null) {
                    AppToast.error('Cần 40 Điểm Tinh Hoa để đổi thẻ bảo vệ.');
                  } else {
                    AppToast.success('Đã đổi 1 Thẻ giữ sách mở');
                  }
                },
                icon: const Icon(Icons.ac_unit_rounded),
                label: const Text('Đổi thẻ bảo vệ chuỗi (40 tinh hoa)'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BookStack extends StatelessWidget {
  const _BookStack({required this.count, required this.open});

  final int count;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final icon = open ? Icons.menu_book_rounded : Icons.book_rounded;
    final color = open ? const Color(0xFFD97706) : const Color(0xFF94A3B8);
    return SizedBox(
      width: 36,
      height: 28,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              bottom: i * 3.0,
              child: Icon(icon, size: 22, color: color.withValues(alpha: 0.55 + i * 0.08)),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
