import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/assessments/presentation/providers/assessments_providers.dart';
import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:eduself_study_app/features/classrooms/presentation/providers/classrooms_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/feature_list_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ClassroomsPage extends ConsumerWidget {
  const ClassroomsPage({super.key});

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => const _JoinClassroomDialog(),
    );
    if (code == null || code.isEmpty) return;

    final result =
        await ref.read(classroomsRepositoryProvider).joinClassroom(code);
    if (!context.mounted) return;
    switch (result) {
      case Success():
        AppToast.success('Đã tham gia lớp học');
        ref.invalidate(classroomsProvider);
        ref.invalidate(assessmentsProvider);
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => const _CreateClassroomDialog(),
    );
    if (name == null || name.isEmpty) return;

    final result =
        await ref.read(classroomsRepositoryProvider).createClassroom(name);
    if (!context.mounted) return;
    switch (result) {
      case Success(:final value):
        ref.invalidate(classroomsProvider);
        await Clipboard.setData(ClipboardData(text: value.joinCode));
        AppToast.success('Đã tạo lớp · mã ${value.joinCode} (đã sao chép)');
        if (context.mounted) {
          context.push('/classrooms/${value.id}');
        }
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classrooms = ref.watch(classroomsProvider);
    final user = ref.watch(authSessionProvider).valueOrNull;
    final isStudent = user?.role == UserRole.student;
    final isTeacher = user?.role == UserRole.teacher;
    final scheme = Theme.of(context).colorScheme;

    return FeatureListScaffold(
      title: 'Lớp học',
      listHeader: isStudent ? 'Lớp của em' : 'Lớp đang dạy',
      value: classrooms,
      emptyTitle: isStudent ? 'Chưa tham gia lớp nào' : 'Chưa có lớp học',
      emptySubtitle: isStudent
          ? 'Em nhập mã lớp từ thầy/cô để xem đề được giao.'
          : 'Tạo lớp và chia sẻ mã tham gia cho học sinh.',
      onRefresh: () async {
        ref.invalidate(classroomsProvider);
        await ref.read(classroomsProvider.future);
      },
      floatingActionButton: isStudent
          ? FloatingActionButton.extended(
              onPressed: () => _join(context, ref),
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Tham gia lớp'),
            )
          : isTeacher
              ? FloatingActionButton.extended(
                  onPressed: () => _create(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Tạo lớp'),
                )
              : null,
      itemBuilder: (context, room) {
        return DenseListRow(
          title: room.name,
          subtitle: isStudent
              ? 'Em đã là thành viên lớp này'
              : 'Mã lớp: ${room.joinCode}',
          leadingIcon: Icons.groups_rounded,
          trailing: !isStudent && room.joinCode.isNotEmpty
              ? IconButton(
                  tooltip: 'Sao chép mã lớp',
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: room.joinCode),
                    );
                    AppToast.success('Đã sao chép mã lớp');
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : null,
          onTap: isTeacher
              ? () => context.push('/classrooms/${room.id}')
              : null,
        );
      },
    );
  }
}

/// Owns [TextEditingController] for the dialog lifetime (avoids dispose-while-animating).
class _JoinClassroomDialog extends StatefulWidget {
  const _JoinClassroomDialog();

  @override
  State<_JoinClassroomDialog> createState() => _JoinClassroomDialogState();
}

class _JoinClassroomDialogState extends State<_JoinClassroomDialog> {
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
      title: const Text('Tham gia lớp học'),
      content: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          labelText: 'Mã lớp',
          hintText: 'Nhập mã thầy/cô cung cấp',
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
        ],
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Tham gia'),
        ),
      ],
    );
  }
}

class _CreateClassroomDialog extends StatefulWidget {
  const _CreateClassroomDialog();

  @override
  State<_CreateClassroomDialog> createState() => _CreateClassroomDialogState();
}

class _CreateClassroomDialogState extends State<_CreateClassroomDialog> {
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
      title: const Text('Tạo lớp học'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Tên lớp',
          hintText: 'Ví dụ: Toán 6A',
        ),
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
          child: const Text('Tạo'),
        ),
      ],
    );
  }
}
