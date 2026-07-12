import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/exam_matrices/domain/entities/exam_matrix.dart';
import 'package:eduself_study_app/features/exam_matrices/presentation/providers/exam_matrices_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/feature_list_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ExamMatricesPage extends ConsumerWidget {
  const ExamMatricesPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String title, String subject})>(
      context: context,
      builder: (ctx) => const _CreateMatrixDialog(),
    );
    if (result == null || result.title.isEmpty) return;

    final created = await ref.read(examMatricesRepositoryProvider).create(
          title: result.title,
          subject: result.subject.isEmpty ? null : result.subject,
        );
    if (!context.mounted) return;
    switch (created) {
      case Success(:final value):
        ref.invalidate(examMatricesProvider);
        context.push('/exam-matrices/${value.id}');
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrices = ref.watch(examMatricesProvider);

    return FeatureListScaffold<ExamMatrix>(
      title: 'Ma trận đề',
      value: matrices,
      emptyTitle: 'Chưa có ma trận',
      emptySubtitle: 'Tạo ma trận chuẩn đầu ra cho đề kiểm tra.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tạo ma trận'),
      ),
      onRefresh: () async {
        ref.invalidate(examMatricesProvider);
        await ref.read(examMatricesProvider.future);
      },
      itemBuilder: (context, item) {
        final scheme = Theme.of(context).colorScheme;
        return DenseListRow(
          title: item.title,
          subtitle: [
            if (item.subject != null) item.subject!,
            if (item.gradeLevel != null) 'Lớp ${item.gradeLevel}',
          ].join(' · '),
          leadingIcon: Icons.grid_view_rounded,
          onTap: () => context.push('/exam-matrices/${item.id}'),
          trailing: IconButton(
            tooltip: 'Xoá',
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xoá ma trận?'),
                  content: Text(item.title),
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
              if (ok != true) return;
              final result = await ref
                  .read(examMatricesRepositoryProvider)
                  .delete(item.id);
              switch (result) {
                case Success():
                  ref.invalidate(examMatricesProvider);
                case FailureResult(:final failure):
                  AppToast.error(failure.message);
              }
            },
            icon: Icon(Icons.delete_outline, color: scheme.onSurfaceVariant),
          ),
        );
      },
    );
  }
}

class _CreateMatrixDialog extends StatefulWidget {
  const _CreateMatrixDialog();

  @override
  State<_CreateMatrixDialog> createState() => _CreateMatrixDialogState();
}

class _CreateMatrixDialogState extends State<_CreateMatrixDialog> {
  late final TextEditingController _title;
  late final TextEditingController _subject;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _subject = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo ma trận đề'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Tiêu đề'),
            autofocus: true,
          ),
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Môn (tuỳ chọn)'),
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
            (
              title: _title.text.trim(),
              subject: _subject.text.trim(),
            ),
          ),
          child: const Text('Tạo'),
        ),
      ],
    );
  }
}
