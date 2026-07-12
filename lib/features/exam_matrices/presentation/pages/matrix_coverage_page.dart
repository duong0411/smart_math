import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/exam_matrices/domain/entities/exam_matrix.dart';
import 'package:eduself_study_app/features/exam_matrices/presentation/providers/exam_matrices_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatrixCoveragePage extends ConsumerStatefulWidget {
  const MatrixCoveragePage({super.key, required this.matrixId});

  final int matrixId;

  @override
  ConsumerState<MatrixCoveragePage> createState() => _MatrixCoveragePageState();
}

class _MatrixCoveragePageState extends ConsumerState<MatrixCoveragePage> {
  int? _assessmentId;
  MatrixCoverage? _coverage;
  bool _loading = false;

  Future<void> _load([int? assessmentId]) async {
    final id = assessmentId ?? _assessmentId;
    if (id == null) return;
    setState(() {
      _assessmentId = id;
      _loading = true;
    });
    final result = await ref.read(examMatricesRepositoryProvider).coverage(
          matrixId: widget.matrixId,
          assessmentId: id,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Success(:final value):
        setState(() => _coverage = value);
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(examMatrixDetailProvider(widget.matrixId));

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Độ phủ ma trận'),
        ),
        body: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (data) {
            final linked = data.linkedAssessmentIds;
            if (linked.isEmpty) {
              return const Center(
                child: Text('Liên kết ít nhất một đề trước khi xem độ phủ.'),
              );
            }
            final selectedId = _assessmentId ?? linked.first;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: selectedId,
                        decoration: const InputDecoration(labelText: 'Đề'),
                        items: [
                          for (final id in linked)
                            DropdownMenuItem(
                              value: id,
                              child: Text('Đề #$id'),
                            ),
                        ],
                        onChanged: (v) => setState(() {
                          _assessmentId = v;
                          _coverage = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loading
                            ? null
                            : () => _load(selectedId),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Xem độ phủ'),
                      ),
                    ],
                  ),
                ),
                if (_coverage != null) ...[
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Text(
                      _coverage!.overallMet
                          ? 'Đạt đủ mục tiêu ma trận'
                          : 'Chưa đạt đủ mục tiêu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: _coverage!.overallMet
                                ? Colors.green.shade700
                                : Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final cell in _coverage!.cells)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            cell.met
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            color: cell.met
                                ? Colors.green
                                : Theme.of(context).colorScheme.error,
                          ),
                          title: Text(
                            '${cell.outcomeCode} · ${cell.itemType.labelVi}',
                          ),
                          subtitle: Text(
                            'Câu: ${cell.actualCount}/${cell.targetCount}'
                            ' · Điểm: ${cell.actualPoints.toStringAsFixed(0)}'
                            '/${cell.targetPoints.toStringAsFixed(0)}',
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
