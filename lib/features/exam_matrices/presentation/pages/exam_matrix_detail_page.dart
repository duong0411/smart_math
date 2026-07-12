import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/presentation/pages/teacher_assessments_page.dart';
import 'package:eduself_study_app/features/exam_matrices/domain/entities/exam_matrix.dart';
import 'package:eduself_study_app/features/exam_matrices/presentation/providers/exam_matrices_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ExamMatrixDetailPage extends ConsumerWidget {
  const ExamMatrixDetailPage({super.key, required this.matrixId});

  final int matrixId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(examMatrixDetailProvider(matrixId));

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(detail.valueOrNull?.matrix.title ?? 'Ma trận đề'),
          actions: [
            TextButton(
              onPressed: () =>
                  context.push('/exam-matrices/$matrixId/coverage'),
              child: const Text('Độ phủ'),
            ),
          ],
        ),
        body: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) {
            final outcomeById = {
              for (final o in data.outcomes) o.id: o,
            };
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.matrix.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (data.matrix.subject != null)
                        Text('Môn: ${data.matrix.subject}'),
                      if (data.matrix.description != null)
                        Text(data.matrix.description!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Chuẩn đầu ra',
                  onAdd: () => _addOutcome(context, ref),
                ),
                for (final o in data.outcomes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${o.code} · ${o.title}'),
                        subtitle: o.description != null
                            ? Text(o.description!)
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final result = await ref
                                .read(examMatricesRepositoryProvider)
                                .deleteOutcome(
                                  matrixId: matrixId,
                                  outcomeId: o.id,
                                );
                            switch (result) {
                              case Success():
                                ref.invalidate(
                                  examMatrixDetailProvider(matrixId),
                                );
                              case FailureResult(:final failure):
                                AppToast.error(failure.message);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _SectionHeader(
                  title: 'Ô ma trận (cells)',
                  onAdd: data.outcomes.isEmpty
                      ? null
                      : () => _addCell(context, ref, data.outcomes),
                ),
                for (final c in data.cells)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${outcomeById[c.outcomeId]?.code ?? c.outcomeId}'
                          ' · ${c.itemType.labelVi}',
                        ),
                        subtitle: Text(
                          'Mục tiêu: ${c.targetCount} câu · ${c.targetPoints} điểm',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final result = await ref
                                .read(examMatricesRepositoryProvider)
                                .deleteCell(
                                  matrixId: matrixId,
                                  cellId: c.id,
                                );
                            switch (result) {
                              case Success():
                                ref.invalidate(
                                  examMatrixDetailProvider(matrixId),
                                );
                              case FailureResult(:final failure):
                                AppToast.error(failure.message);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _SectionHeader(
                  title: 'Đề liên kết',
                  onAdd: () => _linkAssessment(context, ref),
                ),
                if (data.linkedAssessmentIds.isEmpty)
                  const GlassCard(child: Text('Chưa liên kết đề nào.')),
                for (final assessmentId in data.linkedAssessmentIds)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Đề #$assessmentId'),
                        trailing: IconButton(
                          icon: const Icon(Icons.link_off),
                          onPressed: () async {
                            final result = await ref
                                .read(examMatricesRepositoryProvider)
                                .unlinkAssessment(
                                  matrixId: matrixId,
                                  assessmentId: assessmentId,
                                );
                            switch (result) {
                              case Success():
                                ref.invalidate(
                                  examMatrixDetailProvider(matrixId),
                                );
                              case FailureResult(:final failure):
                                AppToast.error(failure.message);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _addOutcome(BuildContext context, WidgetRef ref) async {
    final values = await showDialog<({String code, String title})>(
      context: context,
      builder: (ctx) => const _AddOutcomeDialog(),
    );
    if (values == null || values.code.isEmpty || values.title.isEmpty) return;

    final result = await ref.read(examMatricesRepositoryProvider).addOutcome(
          matrixId: matrixId,
          code: values.code,
          title: values.title,
        );
    switch (result) {
      case Success():
        ref.invalidate(examMatrixDetailProvider(matrixId));
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  Future<void> _addCell(
    BuildContext context,
    WidgetRef ref,
    List<ExamMatrixOutcome> outcomes,
  ) async {
    final values = await showDialog<
        ({
          int outcomeId,
          AssessmentItemType itemType,
          int count,
          double points,
        })>(
      context: context,
      builder: (ctx) => _AddCellDialog(outcomes: outcomes),
    );
    if (values == null) return;

    final result = await ref.read(examMatricesRepositoryProvider).addCell(
          matrixId: matrixId,
          outcomeId: values.outcomeId,
          itemType: values.itemType,
          targetCount: values.count,
          targetPoints: values.points,
        );
    switch (result) {
      case Success():
        ref.invalidate(examMatrixDetailProvider(matrixId));
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  Future<void> _linkAssessment(BuildContext context, WidgetRef ref) async {
    final owned = await ref.read(ownedAssessmentsProvider.future);
    if (owned.isEmpty) {
      AppToast.error('Chưa có đề để liên kết.');
      return;
    }
    if (!context.mounted) return;
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Liên kết đề'),
        children: [
          for (final a in owned)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, a.id),
              child: Text('${a.title} (#${a.id})'),
            ),
        ],
      ),
    );
    if (selected == null) return;
    final result = await ref.read(examMatricesRepositoryProvider).linkAssessment(
          matrixId: matrixId,
          assessmentId: selected,
        );
    switch (result) {
      case Success():
        ref.invalidate(examMatrixDetailProvider(matrixId));
        AppToast.success('Đã liên kết đề');
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onAdd});

  final String title;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (onAdd != null)
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
            ),
        ],
      ),
    );
  }
}

class _AddOutcomeDialog extends StatefulWidget {
  const _AddOutcomeDialog();

  @override
  State<_AddOutcomeDialog> createState() => _AddOutcomeDialogState();
}

class _AddOutcomeDialogState extends State<_AddOutcomeDialog> {
  late final TextEditingController _code;
  late final TextEditingController _title;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController();
    _title = TextEditingController();
  }

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm chuẩn'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _code,
            decoration: const InputDecoration(labelText: 'Mã (vd: C1)'),
          ),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Tiêu đề'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            (code: _code.text.trim(), title: _title.text.trim()),
          ),
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}

class _AddCellDialog extends StatefulWidget {
  const _AddCellDialog({required this.outcomes});

  final List<ExamMatrixOutcome> outcomes;

  @override
  State<_AddCellDialog> createState() => _AddCellDialogState();
}

class _AddCellDialogState extends State<_AddCellDialog> {
  late int? _outcomeId;
  var _itemType = AssessmentItemType.mcq;
  late final TextEditingController _count;
  late final TextEditingController _points;

  @override
  void initState() {
    super.initState();
    _outcomeId = widget.outcomes.first.id;
    _count = TextEditingController(text: '1');
    _points = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _count.dispose();
    _points.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm ô ma trận'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _outcomeId,
            decoration: const InputDecoration(labelText: 'Chuẩn'),
            items: [
              for (final o in widget.outcomes)
                DropdownMenuItem(
                  value: o.id,
                  child: Text('${o.code} · ${o.title}'),
                ),
            ],
            onChanged: (v) => setState(() => _outcomeId = v),
          ),
          DropdownButtonFormField<AssessmentItemType>(
            initialValue: _itemType,
            decoration: const InputDecoration(labelText: 'Loại câu'),
            items: [
              for (final t in AssessmentItemType.values)
                DropdownMenuItem(value: t, child: Text(t.labelVi)),
            ],
            onChanged: (v) =>
                setState(() => _itemType = v ?? AssessmentItemType.mcq),
          ),
          TextField(
            controller: _count,
            decoration: const InputDecoration(labelText: 'Số câu mục tiêu'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _points,
            decoration: const InputDecoration(labelText: 'Điểm mục tiêu'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () {
            final outcomeId = _outcomeId;
            if (outcomeId == null) return;
            Navigator.pop(
              context,
              (
                outcomeId: outcomeId,
                itemType: _itemType,
                count: int.tryParse(_count.text.trim()) ?? 1,
                points: double.tryParse(_points.text.trim()) ?? 1,
              ),
            );
          },
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
