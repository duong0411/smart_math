import 'package:eduself_study_app/features/study_tools/domain/entities/study_tool_item.dart';
import 'package:eduself_study_app/features/study_tools/presentation/providers/study_tools_providers.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/feature_list_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StudyToolsPage extends ConsumerWidget {
  const StudyToolsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tools = ref.watch(studyToolsProvider);

    return FeatureListScaffold(
      title: 'Flashcard & Mindmap',
      value: tools,
      emptyTitle: 'Chưa có bộ thẻ / sơ đồ',
      emptySubtitle: 'Em tạo flashcard hoặc mindmap để ôn bài nhé.',
      onRefresh: () async {
        ref.invalidate(studyToolsProvider);
        await ref.read(studyToolsProvider.future);
      },
      itemBuilder: (context, item) {
        final isDeck = item is FlashcardDeckItem;
        return DenseListRow(
          title: item.title,
          subtitle: [
            isDeck ? 'Flashcard' : 'Mindmap',
            if (item.subject != null) item.subject!,
          ].join(' · '),
          leadingIcon:
              isDeck ? Icons.style_rounded : Icons.account_tree_rounded,
          onTap: () {
            if (isDeck) {
              context.push('/study-tools/decks/${item.id}');
            } else {
              context.push('/study-tools/mindmaps/${item.id}');
            }
          },
        );
      },
    );
  }
}
