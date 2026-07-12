import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/parents/domain/entities/linked_child.dart';
import 'package:eduself_study_app/features/parents/presentation/providers/parents_providers.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/feature_list_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ParentsHubPage extends ConsumerWidget {
  const ParentsHubPage({super.key});

  Future<void> _linkChild(BuildContext context, WidgetRef ref) async {
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => const _InviteCodeDialog(),
    );
    if (code == null || code.isEmpty || !context.mounted) return;

    final result = await ref.read(parentsRepositoryProvider).linkChild(code);
    if (!context.mounted) return;
    switch (result) {
      case Success():
        ref.invalidate(linkedChildrenProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã liên kết học sinh.')),
        );
      case FailureResult(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  Future<void> _unlink(
    BuildContext context,
    WidgetRef ref,
    LinkedChild child,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ liên kết?'),
        content: Text(
          'Bỏ liên kết với ${child.displayName ?? child.studentEmail}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Huỷ liên kết'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final result =
        await ref.read(parentsRepositoryProvider).unlinkChild(child.studentId);
    if (!context.mounted) return;
    switch (result) {
      case Success():
        ref.invalidate(linkedChildrenProvider);
        ref.invalidate(reportsProvider);
      case FailureResult(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(linkedChildrenProvider);

    return FeatureListScaffold<LinkedChild>(
      title: 'Cổng phụ huynh',
      value: children,
      emptyTitle: 'Chưa liên kết học sinh',
      emptySubtitle: 'Nhập mã mời từ hồ sơ của con để theo dõi tiến độ.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _linkChild(context, ref),
        icon: const Icon(Icons.link_rounded),
        label: const Text('Liên kết'),
      ),
      onRefresh: () async {
        ref.invalidate(linkedChildrenProvider);
        await ref.read(linkedChildrenProvider.future);
      },
      itemBuilder: (context, child) {
        final title = child.displayName?.trim().isNotEmpty == true
            ? child.displayName!
            : child.studentEmail;
        final grade = child.gradeLevel != null
            ? 'Lớp ${child.gradeLevel}'
            : 'Chưa chọn lớp';
        final scheme = Theme.of(context).colorScheme;
        return DenseListRow(
          title: title,
          subtitle: '$grade · ${child.studentEmail}',
          onTap: () => context.push('/parents/children/${child.studentId}'),
          trailing: IconButton(
            tooltip: 'Huỷ liên kết',
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: () => _unlink(context, ref, child),
            icon: Icon(Icons.link_off_rounded, color: scheme.onSurfaceVariant),
          ),
        );
      },
    );
  }
}

/// Owns [TextEditingController] for the dialog lifetime (avoids dispose-while-animating).
class _InviteCodeDialog extends StatefulWidget {
  const _InviteCodeDialog();

  @override
  State<_InviteCodeDialog> createState() => _InviteCodeDialogState();
}

class _InviteCodeDialogState extends State<_InviteCodeDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Liên kết học sinh'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Mã mời',
          hintText: 'Nhập mã từ hồ sơ học sinh',
        ),
        textCapitalization: TextCapitalization.characters,
        autofocus: true,
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Liên kết'),
        ),
      ],
    );
  }
}
