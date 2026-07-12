import 'package:eduself_study_app/features/progress/presentation/providers/progress_providers.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/feature_list_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(progressRowsProvider);

    return FeatureListScaffold(
      title: 'Tiến độ học tập',
      value: rows,
      emptyTitle: 'Chưa có tiến độ',
      emptySubtitle:
          'Em học với Gia sư AI hoặc làm bài kiểm tra để thấy thống kê.',
      onRefresh: () async {
        ref.invalidate(progressSummaryProvider);
        await ref.read(progressRowsProvider.future);
      },
      itemBuilder: (context, row) {
        return DenseListRow(
          title: row.title,
          subtitle: row.subtitle,
          leadingIcon: Icons.insights_rounded,
        );
      },
    );
  }
}
