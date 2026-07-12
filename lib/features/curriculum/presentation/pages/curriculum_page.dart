import 'package:eduself_study_app/features/curriculum/presentation/providers/curriculum_providers.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/feature_list_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurriculumPage extends ConsumerWidget {
  const CurriculumPage({super.key});

  String _bandLabel(String band) {
    return switch (band) {
      'primary' => 'Tiểu học',
      'lower_secondary' => 'THCS',
      'upper_secondary' => 'THPT',
      _ => band,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(curriculumSubjectsProvider);

    return FeatureListScaffold(
      title: 'Học theo SGK',
      value: subjects,
      emptyTitle: 'Chưa có môn học',
      emptySubtitle: 'Em cập nhật lớp trong hồ sơ rồi thử lại nhé.',
      onRefresh: () async {
        ref.invalidate(curriculumSubjectsProvider);
        await ref.read(curriculumSubjectsProvider.future);
      },
      itemBuilder: (context, subject) {
        return DenseListRow(
          title: subject.name,
          subtitle: _bandLabel(subject.gradeBand),
          leadingIcon: Icons.menu_book_rounded,
        );
      },
    );
  }
}
