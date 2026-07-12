import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/parents/domain/entities/weekly_report.dart';
import 'package:eduself_study_app/features/parents/presentation/providers/parents_providers.dart';
import 'package:eduself_study_app/features/parents/presentation/widgets/weekly_report_charts_view.dart';
import 'package:eduself_study_app/features/progress/domain/entities/progress_summary.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChildDetailPage extends ConsumerStatefulWidget {
  const ChildDetailPage({super.key, required this.studentId});

  final int studentId;

  @override
  ConsumerState<ChildDetailPage> createState() => _ChildDetailPageState();
}

class _ChildDetailPageState extends ConsumerState<ChildDetailPage> {
  WeeklyReportPreview? _preview;
  bool _busy = false;
  String? _error;

  Future<void> _loadPreview() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(parentsRepositoryProvider).previewWeeklyReport(
          studentId: widget.studentId,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(:final value):
        setState(() => _preview = value);
      case FailureResult(:final failure):
        setState(() => _error = failure.message);
    }
  }

  Future<void> _persistReport() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(parentsRepositoryProvider)
        .generateWeeklyReport(studentId: widget.studentId);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(:final value):
        ref.invalidate(reportsProvider);
        context.push('/parents/reports/${value.id}');
      case FailureResult(:final failure):
        setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(childProgressProvider(widget.studentId));
    final reports = ref.watch(reportsProvider);
    final childReports = reports.maybeWhen(
      data: (all) =>
          all.where((r) => r.studentId == widget.studentId).toList(),
      orElse: () => const <WeeklyReport>[],
    );

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Chi tiết học sinh'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tiến độ',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  progress.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Text('$e'),
                    data: (summary) => _ProgressStats(summary: summary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Báo cáo tuần',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  FilledButton.tonal(
                    onPressed: _busy ? null : _loadPreview,
                    child: const Text('Xem tuần này'),
                  ),
                  if (_preview != null) ...[
                    const SizedBox(height: 12),
                    WeeklyReportChartsView(
                      charts: _preview!.charts,
                      compact: true,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _busy ? null : _persistReport,
                      child: const Text('Lưu báo cáo'),
                    ),
                  ],
                  if (childReports.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Lịch sử',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    for (final report in childReports)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Tuần ${_formatDay(report.weekStartUtc)}',
                        ),
                        subtitle: Text(report.exportStatusLabelVi),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push('/parents/reports/${report.id}'),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDay(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _ProgressStats extends StatelessWidget {
  const _ProgressStats({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final minutes = (summary.totalDurationSec / 60).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${summary.totalEvents} hoạt động · $minutes phút'),
        if (summary.bySubject.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final entry in summary.bySubject.entries)
            Text(
              '• ${entry.key}: ${entry.value.count} lần'
              '${entry.value.avgScore != null ? ' · TB ${entry.value.avgScore!.toStringAsFixed(0)}' : ''}',
            ),
        ],
      ],
    );
  }
}
