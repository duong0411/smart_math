import 'package:eduself_study_app/features/ipa/presentation/providers/ipa_providers.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/feature_list_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IpaPage extends ConsumerWidget {
  const IpaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(ipaListsProvider);

    return FeatureListScaffold(
      title: 'Tiếng Anh (IPA)',
      value: lists,
      emptyTitle: 'Chưa có danh sách từ',
      emptySubtitle: 'Em tạo danh sách IPA để luyện phát âm nhé.',
      onRefresh: () async {
        ref.invalidate(ipaListsProvider);
        await ref.read(ipaListsProvider.future);
      },
      itemBuilder: (context, list) {
        return DenseListRow(
          title: list.title,
          subtitle: 'Cấp độ: ${list.level}',
          leadingIcon: Icons.record_voice_over_rounded,
        );
      },
    );
  }
}
