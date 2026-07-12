import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/presentation/providers/assessments_providers.dart';
import 'package:eduself_study_app/features/classrooms/domain/entities/classroom_member.dart';
import 'package:eduself_study_app/features/classrooms/presentation/providers/classrooms_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:eduself_study_app/shared/widgets/grade_level_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ClassroomDetailPage extends ConsumerWidget {
  const ClassroomDetailPage({super.key, required this.classroomId});

  final int classroomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classroom = ref.watch(classroomDetailProvider(classroomId));
    final members = ref.watch(classroomMembersProvider(classroomId));
    final assignments = ref.watch(classroomAssignmentsProvider(classroomId));
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(classroom.valueOrNull?.name ?? 'Chi tiết lớp'),
          actions: [
            if (classroom.valueOrNull?.joinCode.isNotEmpty == true)
              IconButton(
                tooltip: 'Sao chép mã lớp',
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: classroom.valueOrNull!.joinCode),
                  );
                  AppToast.success('Đã sao chép mã lớp');
                },
                icon: const Icon(Icons.copy_rounded),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _assign(context, ref),
          icon: const Icon(Icons.assignment_add),
          label: const Text('Giao đề'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            if (classroom.valueOrNull != null)
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mã lớp: ${classroom.valueOrNull!.joinCode}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Học sinh',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(width: 8),
                if (members.valueOrNull != null)
                  Text(
                    '(${members.valueOrNull!.length})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            members.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
              data: (list) {
                if (list.isEmpty) {
                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Chưa có học sinh trong lớp.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  );
                }
                return GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: 48,
                            color: scheme.outlineVariant.withValues(alpha: 0.35),
                          ),
                        _CompactMemberTile(
                          member: list[i],
                          onSetGrade: () => _setGrade(context, ref, list[i]),
                          onRemove: () => _remove(context, ref, list[i]),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            assignments.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
              data: (list) {
                return DenseListCard(
                  header: 'Đề đã giao',
                  count: list.length,
                  emptyLabel: 'Chưa giao đề nào.',
                  children: [
                    for (final a in list)
                      DenseListRow(
                        title: a.assessmentTitle,
                        subtitle:
                            '${a.assessmentStatus.labelVi} · '
                            'Thời gian: ${examDurationLabelVi(a.durationMinutes)}',
                        leadingIcon: Icons.assignment_turned_in_rounded,
                        onTap: () => context.push(
                          '/classrooms/$classroomId/assignments/${a.id}/progress',
                        ),
                        trailing: IconButton(
                          tooltip: 'Huỷ giao',
                          visualDensity: VisualDensity.compact,
                          iconSize: 18,
                          onPressed: () async {
                            final result = await ref
                                .read(classroomsRepositoryProvider)
                                .deleteAssignment(
                                  classroomId: classroomId,
                                  assignmentId: a.id,
                                );
                            switch (result) {
                              case Success():
                                ref.invalidate(
                                  classroomAssignmentsProvider(classroomId),
                                );
                                AppToast.success('Đã huỷ giao đề');
                              case FailureResult(:final failure):
                                AppToast.error(failure.message);
                            }
                          },
                          icon: Icon(
                            Icons.delete_outline,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _setGrade(
    BuildContext context,
    WidgetRef ref,
    ClassroomMember member,
  ) async {
    int? grade = member.gradeLevel;
    final label = member.studentEmail ?? 'HS #${member.studentId}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final scheme = Theme.of(ctx).colorScheme;
          return AlertDialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn lớp học'),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: GradeLevelSelector(
                value: grade,
                onChanged: (v) => setLocal(() => grade = v),
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Huỷ'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Lưu lớp'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    final result =
        await ref.read(classroomsRepositoryProvider).updateMemberGrade(
              classroomId: classroomId,
              userId: member.studentId,
              gradeLevel: grade,
            );
    switch (result) {
      case Success():
        ref.invalidate(classroomMembersProvider(classroomId));
        AppToast.success(
          grade == null ? 'Đã cập nhật lớp' : 'Đã đặt Lớp $grade',
        );
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    ClassroomMember member,
  ) async {
    final label = member.studentEmail ?? 'HS #${member.studentId}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: Row(
            children: [
              Icon(Icons.person_remove_outlined, color: scheme.error),
              const SizedBox(width: 10),
              const Expanded(child: Text('Xoá khỏi lớp?')),
            ],
          ),
          content: Text(
            '$label sẽ không còn trong lớp này. Em vẫn có thể tham gia lại bằng mã lớp.',
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Giữ lại'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Xoá khỏi lớp'),
                ),
              ],
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final result = await ref.read(classroomsRepositoryProvider).removeMember(
          classroomId: classroomId,
          userId: member.studentId,
        );
    switch (result) {
      case Success():
        ref.invalidate(classroomMembersProvider(classroomId));
        AppToast.success('Đã xoá khỏi lớp');
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  Future<void> _assign(BuildContext context, WidgetRef ref) async {
    final owned =
        await ref.read(assessmentsRepositoryProvider).listAssessments();
    if (owned is! Success<List<AssessmentSummary>>) {
      AppToast.error(owned.failureOrNull?.message ?? 'Không tải được đề');
      return;
    }
    final published = owned.value
        .where((a) => a.status == AssessmentStatus.published)
        .toList();
    if (published.isEmpty) {
      AppToast.error('Chưa có đề đã xuất bản. Soạn đề trước nhé.');
      return;
    }
    if (!context.mounted) return;

    final assignResult = await showDialog<_AssignDialogResult>(
      context: context,
      builder: (ctx) => _AssignAssessmentDialog(assessments: published),
    );
    if (assignResult == null || assignResult.cancelled) return;

    final result =
        await ref.read(classroomsRepositoryProvider).assignAssessment(
              classroomId: classroomId,
              assessmentId: assignResult.assessmentId!,
              durationMinutes: assignResult.durationMinutes,
            );
    switch (result) {
      case Success():
        ref.invalidate(classroomAssignmentsProvider(classroomId));
        AppToast.success('Đã giao đề');
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }
}

class _CompactMemberTile extends StatelessWidget {
  const _CompactMemberTile({
    required this.member,
    required this.onSetGrade,
    required this.onRemove,
  });

  final ClassroomMember member;
  final VoidCallback onSetGrade;
  final VoidCallback onRemove;

  Future<void> _openActions(BuildContext context) async {
    final action = await showModalBottomSheet<_MemberAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MemberActionsSheet(member: member),
    );
    if (action == _MemberAction.setGrade) onSetGrade();
    if (action == _MemberAction.remove) onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = member.studentEmail ?? 'HS #${member.studentId}';
    final initial = label.isNotEmpty ? label[0].toUpperCase() : '?';

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      minVerticalPadding: 4,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: scheme.primary.withValues(alpha: 0.12),
        foregroundColor: scheme.primary,
        child: Text(
          initial,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        member.gradeLevel != null
            ? 'Lớp ${member.gradeLevel}'
            : 'Chưa chọn lớp',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
      trailing: IconButton(
        tooltip: 'Tuỳ chọn học sinh',
        visualDensity: VisualDensity.compact,
        iconSize: 20,
        onPressed: () => _openActions(context),
        icon: Icon(
          Icons.more_horiz_rounded,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

enum _MemberAction { setGrade, remove }

class _MemberActionsSheet extends StatelessWidget {
  const _MemberActionsSheet({required this.member});

  final ClassroomMember member;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = member.studentEmail ?? 'HS #${member.studentId}';
    final initial = label.isNotEmpty ? label[0].toUpperCase() : '?';
    final gradeLabel = member.gradeLevel != null
        ? 'Đang học Lớp ${member.gradeLevel}'
        : 'Chưa chọn lớp';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primary.withValues(alpha: 0.14),
                  foregroundColor: scheme.primary,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        gradeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MemberActionTile(
              icon: Icons.school_outlined,
              iconColor: scheme.primary,
              iconBg: scheme.primary.withValues(alpha: 0.12),
              title: 'Đặt lớp',
              subtitle: 'Chọn khối lớp phù hợp với học sinh',
              onTap: () => Navigator.pop(context, _MemberAction.setGrade),
            ),
            const SizedBox(height: 8),
            _MemberActionTile(
              icon: Icons.person_remove_outlined,
              iconColor: scheme.error,
              iconBg: scheme.error.withValues(alpha: 0.10),
              title: 'Xoá khỏi lớp',
              subtitle: 'Học sinh có thể tham gia lại bằng mã lớp',
              titleColor: scheme.error,
              onTap: () => Navigator.pop(context, _MemberAction.remove),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberActionTile extends StatelessWidget {
  const _MemberActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: iconBg,
                foregroundColor: iconColor,
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignDialogResult {
  const _AssignDialogResult({
    required this.cancelled,
    this.assessmentId,
    this.durationMinutes,
  });

  final bool cancelled;
  final int? assessmentId;
  final int? durationMinutes;
}

class _AssignAssessmentDialog extends StatefulWidget {
  const _AssignAssessmentDialog({required this.assessments});

  final List<AssessmentSummary> assessments;

  @override
  State<_AssignAssessmentDialog> createState() =>
      _AssignAssessmentDialogState();
}

class _AssignAssessmentDialogState extends State<_AssignAssessmentDialog> {
  static const _presets = [30, 45, 60, 90];

  late int _selectedId;
  final _controller = TextEditingController(text: '45');
  var _unlimited = false;
  int? _preset = 45;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.assessments.first.id;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPreset(int minutes) {
    setState(() {
      _unlimited = false;
      _preset = minutes;
      _controller.text = '$minutes';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      title: Row(
        children: [
          Icon(Icons.assignment_turned_in_outlined, color: scheme.primary),
          const SizedBox(width: 10),
          const Expanded(child: Text('Giao đề cho lớp')),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Chọn đề đã xuất bản và đặt thời lượng làm bài.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Đề kiểm tra',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < widget.assessments.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: scheme.outlineVariant
                                  .withValues(alpha: 0.35),
                            ),
                          Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: () => setState(
                                () => _selectedId = widget.assessments[i].id,
                              ),
                              child: ColoredBox(
                                color: _selectedId == widget.assessments[i].id
                                    ? scheme.primary.withValues(alpha: 0.10)
                                    : Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _selectedId ==
                                                widget.assessments[i].id
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        size: 22,
                                        color: _selectedId ==
                                                widget.assessments[i].id
                                            ? scheme.primary
                                            : scheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.assessments[i].title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (widget.assessments[i]
                                                    .subject !=
                                                null)
                                              Text(
                                                widget
                                                    .assessments[i].subject!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Thời lượng',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Học sinh sẽ thấy đồng hồ đếm ngược khi làm bài.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _presets)
                      ChoiceChip(
                        label: Text('$m phút'),
                        selected: !_unlimited && _preset == m,
                        onSelected: (_) => _selectPreset(m),
                      ),
                    FilterChip(
                      label: const Text('Không giới hạn'),
                      selected: _unlimited,
                      onSelected: (v) {
                        setState(() {
                          _unlimited = v;
                          if (v) _preset = null;
                        });
                      },
                    ),
                  ],
                ),
                if (!_unlimited) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      final minutes = int.tryParse(v.trim());
                      setState(() {
                        _preset = _presets.contains(minutes) ? minutes : null;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Hoặc nhập số phút',
                      hintText: '1–300',
                      suffixText: 'phút',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                const _AssignDialogResult(cancelled: true),
              ),
              child: const Text('Huỷ'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (_unlimited) {
                  Navigator.pop(
                    context,
                    _AssignDialogResult(
                      cancelled: false,
                      assessmentId: _selectedId,
                      durationMinutes: null,
                    ),
                  );
                  return;
                }
                final minutes = int.tryParse(_controller.text.trim());
                if (minutes == null || minutes < 1 || minutes > 300) {
                  AppToast.error('Nhập thời lượng từ 1 đến 300 phút.');
                  return;
                }
                Navigator.pop(
                  context,
                  _AssignDialogResult(
                    cancelled: false,
                    assessmentId: _selectedId,
                    durationMinutes: minutes,
                  ),
                );
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Giao đề'),
            ),
          ],
        ),
      ],
    );
  }
}
