import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/presentation/providers/assessments_providers.dart';
import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:eduself_study_app/features/classrooms/presentation/providers/classrooms_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AssessmentsPage extends ConsumerWidget {
  const AssessmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessments = ref.watch(assessmentsProvider);
    final classrooms = ref.watch(classroomsProvider);
    final user = ref.watch(authSessionProvider).valueOrNull;
    final isStudent = user?.role == UserRole.student;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Kiểm tra'),
        ),
        drawer: const AppDrawer(),
        body: assessments.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              GlassCard(
                child: Column(
                  children: [
                    Text('$error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(assessmentsProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (items) {
            final assigned = items
                .where((e) => e.source == AssessmentListSource.assigned)
                .toList(growable: false);
            final owned = items
                .where((e) => e.source == AssessmentListSource.owned)
                .toList(growable: false);
            final joinedCount = classrooms.valueOrNull?.length ?? 0;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(assessmentsProvider);
                ref.invalidate(classroomsProvider);
                await ref.read(assessmentsProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  if (isStudent) ...[
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Đề giao chỉ hiện khi em đã tham gia lớp',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            joinedCount == 0
                                ? 'Em chưa ở lớp nào. Vào Lớp học và nhập mã từ thầy/cô.'
                                : 'Em đang ở $joinedCount lớp. Đề được giao sẽ hiện bên dưới.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/classrooms'),
                            icon: const Icon(Icons.groups_rounded),
                            label: Text(
                              joinedCount == 0
                                  ? 'Tham gia lớp học'
                                  : 'Xem lớp của em',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    DenseListCard(
                      header: 'Đề được giao',
                      count: assigned.length,
                      emptyLabel: joinedCount == 0
                          ? 'Chưa có đề — em tham gia lớp trước nhé.'
                          : 'Lớp của em chưa được giao đề nào.',
                      children: [
                        for (final item in assigned)
                          _AssessmentDenseRow(item: item),
                      ],
                    ),
                    if (owned.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      DenseListCard(
                        header: 'Đề của em',
                        count: owned.length,
                        children: [
                          for (final item in owned)
                            _AssessmentDenseRow(item: item),
                        ],
                      ),
                    ],
                  ] else ...[
                    DenseListCard(
                      header: 'Đề kiểm tra',
                      count: items.length,
                      emptyLabel: 'Chưa có đề kiểm tra.',
                      children: [
                        for (final item in items)
                          _AssessmentDenseRow(item: item),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AssessmentDenseRow extends StatelessWidget {
  const _AssessmentDenseRow({required this.item});

  final AssessmentSummary item;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (item.source == AssessmentListSource.assigned) 'Được giao',
      if (item.classroomName != null) item.classroomName!,
      if (item.durationMinutes != null)
        'Thời gian: ${examDurationLabelVi(item.durationMinutes)}',
      if (item.subject != null) item.subject!,
      if (item.gradeLevel != null) 'Lớp ${item.gradeLevel}',
      item.status.labelVi,
    ].join(' · ');

    return DenseListRow(
      title: item.title,
      subtitle: meta,
      leadingIcon: item.source == AssessmentListSource.assigned
          ? Icons.assignment_turned_in_rounded
          : Icons.quiz_rounded,
      onTap: () => context.push('/assessments/${item.id}'),
    );
  }
}
