import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/auth/domain/entities/user.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:eduself_study_app/features/parents/domain/entities/parent_invite_code.dart';
import 'package:eduself_study_app/features/parents/presentation/providers/parents_providers.dart';
import 'package:eduself_study_app/features/student/domain/entities/student_profile.dart';
import 'package:eduself_study_app/features/student/presentation/providers/student_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:eduself_study_app/shared/widgets/grade_level_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectsController = TextEditingController();
  int? _gradeLevel;
  bool _saving = false;
  bool _inviteBusy = false;
  String? _error;
  bool _seeded = false;
  ParentInviteCode? _invite;

  @override
  void dispose() {
    _nameController.dispose();
    _subjectsController.dispose();
    super.dispose();
  }

  void _seed(StudentProfile profile) {
    if (_seeded) return;
    _seeded = true;
    _nameController.text = profile.displayName ?? '';
    _gradeLevel = profile.gradeLevel;
    _subjectsController.text = profile.subjects.join(', ');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gradeLevel == null) {
      setState(() => _error = 'Em chọn lớp học nhé.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final subjects = _subjectsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    final result = await ref.read(updateStudentProfileProvider)(
      UpdateStudentProfileInput(
        displayName: _nameController.text.trim(),
        gradeLevel: _gradeLevel,
        subjects: subjects,
      ),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    switch (result) {
      case Success():
        ref.invalidate(studentProfileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu hồ sơ.')),
        );
      case FailureResult(:final failure):
        setState(() => _error = failure.message);
    }
  }

  Future<void> _createInvite() async {
    setState(() => _inviteBusy = true);
    final result =
        await ref.read(parentsRepositoryProvider).createInviteCode();
    if (!mounted) return;
    setState(() => _inviteBusy = false);
    switch (result) {
      case Success(:final value):
        setState(() => _invite = value);
      case FailureResult(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(studentProfileProvider);
    final role = ref.watch(authSessionProvider).valueOrNull?.role;
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Hồ sơ'),
        ),
        drawer: const AppDrawer(),
        body: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              GlassCard(
                child: Column(
                  children: [
                    Text('$error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(studentProfileProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (profile) {
            _seed(profile);
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Thông tin học sinh',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Tên hiển thị',
                            hintText: 'Ví dụ: Minh Anh',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Em nhập tên nhé.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        GradeLevelSelector(
                          value: _gradeLevel,
                          onChanged: (grade) {
                            setState(() {
                              _gradeLevel = grade;
                              _error = null;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _subjectsController,
                          decoration: const InputDecoration(
                            labelText: 'Môn học quan tâm',
                            hintText: 'Toán, Tiếng Anh, ...',
                            helperText: 'Cách nhau bằng dấu phẩy',
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(color: scheme.error),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Lưu hồ sơ'),
                        ),
                      ],
                    ),
                  ),
                  if (role == UserRole.student) ...[
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Mã mời phụ huynh',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tạo mã và gửi cho phụ huynh để họ liên kết theo dõi tiến độ.',
                          ),
                          const SizedBox(height: 12),
                          if (_invite != null) ...[
                            SelectableText(
                              _invite!.code,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hết hạn: ${_invite!.expiresAtUtc.toLocal()}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: _invite!.code),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã sao chép mã mời.'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('Sao chép'),
                            ),
                            const SizedBox(height: 8),
                          ],
                          FilledButton.tonal(
                            onPressed: _inviteBusy ? null : _createInvite,
                            child: _inviteBusy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _invite == null
                                        ? 'Tạo mã mời'
                                        : 'Tạo mã mới',
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
