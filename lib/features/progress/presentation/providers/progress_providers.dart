import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/network_providers.dart';
import 'package:eduself_study_app/features/progress/domain/entities/progress_summary.dart';
import 'package:eduself_study_app/features/progress/domain/repositories/progress_repository.dart';
import 'package:eduself_study_app/features/progress/infrastructure/repositories/progress_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepositoryImpl(api: ref.watch(apiClientProvider));
});

final progressSummaryProvider = FutureProvider<ProgressSummary>((ref) async {
  final result = await ref.watch(progressRepositoryProvider).getSummary();
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final progressRowsProvider = FutureProvider<List<ProgressListRow>>((ref) async {
  final summary = await ref.watch(progressSummaryProvider.future);
  final minutes = (summary.totalDurationSec / 60).round();
  final rows = <ProgressListRow>[
    ProgressListRow(
      title: 'Tổng hoạt động',
      subtitle: '${summary.totalEvents} sự kiện · $minutes phút',
    ),
    for (final entry in summary.bySubject.entries)
      ProgressListRow(
        title: 'Môn: ${entry.key}',
        subtitle:
            '${entry.value.count} lần · ${(entry.value.durationSec / 60).round()} phút'
            '${entry.value.avgScore != null ? ' · TB ${entry.value.avgScore!.toStringAsFixed(0)}' : ''}',
      ),
    for (final entry in summary.byType.entries)
      ProgressListRow(
        title: 'Loại: ${entry.key}',
        subtitle:
            '${entry.value.count} lần · ${(entry.value.durationSec / 60).round()} phút',
      ),
  ];
  return rows;
});
