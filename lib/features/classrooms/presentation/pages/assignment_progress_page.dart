import 'package:eduself_study_app/features/classrooms/presentation/providers/classrooms_providers.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AssignmentProgressPage extends ConsumerWidget {
  const AssignmentProgressPage({
    super.key,
    required this.classroomId,
    required this.assignmentId,
  });

  final int classroomId;
  final int assignmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      assignmentProgressProvider(
        (classroomId: classroomId, assignmentId: assignmentId),
      ),
    );

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Tiến độ bài giao'),
        ),
        body: progress.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (rows) {
            if (rows.isEmpty) {
              return const Center(child: Text('Chưa có học sinh.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                final score = row.score != null && row.maxScore != null
                    ? '${row.score!.toStringAsFixed(0)}/${row.maxScore!.toStringAsFixed(0)}'
                    : '—';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(row.studentEmail),
                      subtitle: Text(
                        '${row.attemptStatus ?? 'chưa làm'} · $score',
                      ),
                      trailing: row.attemptId != null
                          ? const Icon(Icons.chevron_right)
                          : null,
                      onTap: row.attemptId == null
                          ? null
                          : () => context.push(
                                '/teachers/grading/attempts/${row.attemptId}',
                              ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
