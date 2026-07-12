import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/parents/presentation/providers/parents_providers.dart';
import 'package:eduself_study_app/features/parents/presentation/widgets/weekly_report_charts_view.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeeklyReportDetailPage extends ConsumerWidget {
  const WeeklyReportDetailPage({super.key, required this.reportId});

  final int reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportDetailProvider(reportId));

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Báo cáo tuần'),
        ),
        body: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (report) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Tuần ${_formatRange(report.weekStartUtc, report.weekEndUtc)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Trạng thái xuất: ${report.exportStatusLabelVi}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: WeeklyReportChartsView(charts: report.charts),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () async {
                    final result = await ref
                        .read(parentsRepositoryProvider)
                        .exportReport(reportId);
                    if (!context.mounted) return;
                    switch (result) {
                            case Success(:final value):
                              ref.invalidate(reportDetailProvider(reportId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Xuất sẵn (bản xem trước) · ${value.exportStatusLabelVi}',
                                  ),
                                ),
                              );
                      case FailureResult(:final failure):
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(failure.message)),
                        );
                    }
                  },
                  child: const Text('Xuất báo cáo'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatRange(DateTime start, DateTime end) {
    String fmt(DateTime dt) {
      final local = dt.toLocal();
      return '${local.day}/${local.month}/${local.year}';
    }

    return '${fmt(start)} – ${fmt(end)}';
  }
}
