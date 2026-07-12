import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/theme/app_theme.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/presentation/pages/teacher_assessments_page.dart';
import 'package:eduself_study_app/features/assessments/presentation/providers/assessments_providers.dart';
import 'package:eduself_study_app/features/assessments/presentation/widgets/matching_pair_board.dart';
import 'package:eduself_study_app/features/exam_matrices/domain/entities/exam_matrix.dart';
import 'package:eduself_study_app/features/exam_matrices/presentation/providers/exam_matrices_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssessmentEditorPage extends ConsumerStatefulWidget {
  const AssessmentEditorPage({super.key, required this.assessmentId});

  final int assessmentId;

  @override
  ConsumerState<AssessmentEditorPage> createState() =>
      _AssessmentEditorPageState();
}

class _AssessmentEditorPageState extends ConsumerState<AssessmentEditorPage> {
  bool _busy = false;

  Future<void> _publish() async {
    setState(() => _busy = true);
    final result = await ref
        .read(assessmentsRepositoryProvider)
        .publishAssessment(widget.assessmentId);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        ref.invalidate(assessmentDetailProvider(widget.assessmentId));
        ref.invalidate(ownedAssessmentsProvider);
        AppToast.success('Đã xuất bản đề');
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  Future<void> _addItem() async {
    final type = await showDialog<AssessmentItemType>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Loại câu hỏi'),
        children: [
          for (final t in AssessmentItemType.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: Text(t.labelVi),
            ),
        ],
      ),
    );
    if (type == null || !mounted) return;

    final draft = await showDialog<_ItemDraft>(
      context: context,
      builder: (ctx) => _ItemEditorDialog(itemType: type),
    );
    if (draft == null) return;

    setState(() => _busy = true);
    final result = await ref.read(assessmentsRepositoryProvider).addItem(
          assessmentId: widget.assessmentId,
          itemType: draft.itemType,
          prompt: draft.prompt,
          options: draft.options,
          answerKey: draft.answerKey,
          points: draft.points,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        ref.invalidate(assessmentDetailProvider(widget.assessmentId));
        AppToast.success('Đã thêm câu hỏi');
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  Future<void> _deleteItem(AssessmentItem item) async {
    final result = await ref.read(assessmentsRepositoryProvider).deleteItem(
          assessmentId: widget.assessmentId,
          itemId: item.id,
        );
    switch (result) {
      case Success():
        ref.invalidate(assessmentDetailProvider(widget.assessmentId));
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  Future<void> _tagOutcome(AssessmentItem item) async {
    final matricesResult =
        await ref.read(examMatricesRepositoryProvider).list();
    if (matricesResult is! Success<List<ExamMatrix>>) {
      AppToast.error(
        matricesResult.failureOrNull?.message ?? 'Không tải được ma trận',
      );
      return;
    }

    final linkedDetails = <ExamMatrixDetail>[];
    for (final matrix in matricesResult.value) {
      final detailResult =
          await ref.read(examMatricesRepositoryProvider).get(matrix.id);
      if (detailResult is Success<ExamMatrixDetail> &&
          detailResult.value.linkedAssessmentIds
              .contains(widget.assessmentId)) {
        linkedDetails.add(detailResult.value);
      }
    }

    if (linkedDetails.isEmpty) {
      AppToast.error(
        'Chưa có ma trận liên kết đề này. Vào Ma trận đề để liên kết trước.',
      );
      return;
    }
    if (!mounted) return;

    final outcomes = [
      for (final d in linkedDetails)
        for (final o in d.outcomes) o,
    ];
    final selected = await showDialog<ExamMatrixOutcome>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Gắn chuẩn đầu ra'),
        children: [
          for (final o in outcomes)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, o),
              child: Text('${o.code} · ${o.title}'),
            ),
        ],
      ),
    );
    if (selected == null) return;

    final result = await ref.read(examMatricesRepositoryProvider).tagItemOutcome(
          assessmentId: widget.assessmentId,
          itemId: item.id,
          outcomeId: selected.id,
        );
    switch (result) {
      case Success():
        AppToast.success('Đã gắn ${selected.code}');
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(assessmentDetailProvider(widget.assessmentId));

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Soạn đề'),
          actions: [
            TextButton(
              onPressed: _busy ? null : _publish,
              child: const Text('Xuất bản'),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _busy ? null : _addItem,
          icon: const Icon(Icons.add),
          label: const Text('Thêm câu'),
        ),
        body: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (assessment) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessment.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${assessment.status.labelVi}'
                        '${assessment.subject != null ? ' · ${assessment.subject}' : ''}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (assessment.items.isEmpty)
                  const GlassCard(
                    child: Text('Chưa có câu hỏi. Thêm ít nhất 1 câu rồi xuất bản.'),
                  ),
                for (final item in assessment.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${item.itemType.labelVi}: ${item.prompt}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${item.points} điểm'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'tag') {
                              _tagOutcome(item);
                            } else if (v == 'delete') {
                              _deleteItem(item);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'tag',
                              child: Text('Gắn chuẩn'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Xoá'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ItemDraft {
  const _ItemDraft({
    required this.itemType,
    required this.prompt,
    this.options,
    required this.answerKey,
    required this.points,
  });

  final AssessmentItemType itemType;
  final String prompt;
  final Map<String, dynamic>? options;
  final Map<String, dynamic> answerKey;
  final double points;
}

class _ItemEditorDialog extends StatefulWidget {
  const _ItemEditorDialog({required this.itemType});

  final AssessmentItemType itemType;

  @override
  State<_ItemEditorDialog> createState() => _ItemEditorDialogState();
}

class _ItemEditorDialogState extends State<_ItemEditorDialog> {
  final _prompt = TextEditingController();
  final _points = TextEditingController(text: '1');
  final _choiceA = TextEditingController();
  final _choiceB = TextEditingController();
  final _choiceC = TextEditingController();
  final _choiceD = TextEditingController();
  final _accepted = TextEditingController();
  late final List<TextEditingController> _leftCtrls;
  late final List<TextEditingController> _rightCtrls;
  Map<String, String> _matchingPairs = {};
  String _correctMcq = 'a';
  bool _trueFalseCorrect = true;

  @override
  void initState() {
    super.initState();
    _leftCtrls = [
      TextEditingController(),
      TextEditingController(),
    ];
    _rightCtrls = [
      TextEditingController(),
      TextEditingController(),
    ];
  }

  @override
  void dispose() {
    _prompt.dispose();
    _points.dispose();
    _choiceA.dispose();
    _choiceB.dispose();
    _choiceC.dispose();
    _choiceD.dispose();
    _accepted.dispose();
    for (final c in _leftCtrls) {
      c.dispose();
    }
    for (final c in _rightCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _leftTexts => [
        for (final c in _leftCtrls)
          if (c.text.trim().isNotEmpty) c.text.trim(),
      ];

  List<String> get _rightTexts => [
        for (final c in _rightCtrls)
          if (c.text.trim().isNotEmpty) c.text.trim(),
      ];

  Map<String, String> get _validMatchingPairs {
    final left = _leftTexts.toSet();
    final right = _rightTexts.toSet();
    return {
      for (final e in _matchingPairs.entries)
        if (left.contains(e.key) && right.contains(e.value)) e.key: e.value,
    };
  }

  void _addLeft() {
    setState(() => _leftCtrls.add(TextEditingController()));
  }

  void _addRight() {
    setState(() => _rightCtrls.add(TextEditingController()));
  }

  void _removeLeft(int index) {
    if (_leftCtrls.length <= 1) return;
    setState(() {
      _leftCtrls.removeAt(index).dispose();
      _matchingPairs = _validMatchingPairs;
    });
  }

  void _removeRight(int index) {
    if (_rightCtrls.length <= 1) return;
    setState(() {
      _rightCtrls.removeAt(index).dispose();
      _matchingPairs = _validMatchingPairs;
    });
  }

  _ItemDraft? _build() {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty) return null;
    final points = double.tryParse(_points.text.trim()) ?? 1;

    switch (widget.itemType) {
      case AssessmentItemType.mcq:
        final choices = <Map<String, String>>[
          if (_choiceA.text.trim().isNotEmpty)
            {'id': 'a', 'text': _choiceA.text.trim()},
          if (_choiceB.text.trim().isNotEmpty)
            {'id': 'b', 'text': _choiceB.text.trim()},
          if (_choiceC.text.trim().isNotEmpty)
            {'id': 'c', 'text': _choiceC.text.trim()},
          if (_choiceD.text.trim().isNotEmpty)
            {'id': 'd', 'text': _choiceD.text.trim()},
        ];
        if (choices.length < 2) return null;
        return _ItemDraft(
          itemType: widget.itemType,
          prompt: prompt,
          options: {'choices': choices},
          answerKey: {'correctOptionId': _correctMcq},
          points: points,
        );
      case AssessmentItemType.trueFalse:
        return _ItemDraft(
          itemType: widget.itemType,
          prompt: prompt,
          answerKey: {'correct': _trueFalseCorrect},
          points: points,
        );
      case AssessmentItemType.fillBlank:
        final answers = _accepted.text
            .split(RegExp(r'[,;\n]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (answers.isEmpty) return null;
        return _ItemDraft(
          itemType: widget.itemType,
          prompt: prompt,
          answerKey: {'acceptedAnswers': answers},
          points: points,
        );
      case AssessmentItemType.matching:
        final left = _leftTexts;
        final right = _rightTexts;
        final pairs = _validMatchingPairs;
        if (left.length < 2 || right.length < 2) return null;
        if (left.toSet().length != left.length) return null;
        if (right.toSet().length != right.length) return null;
        if (pairs.length != left.length) return null;
        if (!left.every(pairs.containsKey)) return null;
        return _ItemDraft(
          itemType: widget.itemType,
          prompt: prompt,
          options: {'left': left, 'right': right},
          answerKey: {'pairs': pairs},
          points: points,
        );
      case AssessmentItemType.essay:
        return _ItemDraft(
          itemType: widget.itemType,
          prompt: prompt,
          answerKey: const {},
          points: points,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thêm câu hỏi',
            style: textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.itemType.labelVi,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _prompt,
                decoration: const InputDecoration(
                  labelText: 'Đề bài',
                  hintText: 'Nhập nội dung câu hỏi…',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _points,
                decoration: const InputDecoration(
                  labelText: 'Điểm',
                  prefixIcon: Icon(Icons.star_outline_rounded),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              if (widget.itemType == AssessmentItemType.mcq) ...[
                const SizedBox(height: 20),
                const _DialogSectionLabel('Lựa chọn'),
                const SizedBox(height: 10),
                _ChoiceField(letter: 'A', controller: _choiceA),
                const SizedBox(height: 10),
                _ChoiceField(letter: 'B', controller: _choiceB),
                const SizedBox(height: 10),
                _ChoiceField(letter: 'C', controller: _choiceC),
                const SizedBox(height: 10),
                _ChoiceField(letter: 'D', controller: _choiceD),
                const SizedBox(height: 20),
                _ChipAnswerSelector<String>(
                  label: 'Đáp án đúng',
                  value: _correctMcq,
                  options: const [
                    (value: 'a', label: 'A'),
                    (value: 'b', label: 'B'),
                    (value: 'c', label: 'C'),
                    (value: 'd', label: 'D'),
                  ],
                  onChanged: (v) => setState(() => _correctMcq = v),
                ),
              ],
              if (widget.itemType == AssessmentItemType.trueFalse) ...[
                const SizedBox(height: 20),
                _ChipAnswerSelector<bool>(
                  label: 'Đáp án đúng',
                  value: _trueFalseCorrect,
                  options: const [
                    (value: true, label: 'Đúng'),
                    (value: false, label: 'Sai'),
                  ],
                  wide: true,
                  onChanged: (v) => setState(() => _trueFalseCorrect = v),
                ),
              ],
              if (widget.itemType == AssessmentItemType.fillBlank) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _accepted,
                  decoration: const InputDecoration(
                    labelText: 'Đáp án chấp nhận',
                    helperText: 'Cách nhau bằng dấu phẩy hoặc dòng mới',
                  ),
                  maxLines: 2,
                ),
              ],
              if (widget.itemType == AssessmentItemType.matching) ...[
                const SizedBox(height: 20),
                const _DialogSectionLabel('Hai cột nội dung'),
                const SizedBox(height: 6),
                Text(
                  'Thêm mục cho từng cột. Học sinh sẽ nối trực tiếp trên màn hình.',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _MatchingColumnEditor(
                        title: 'Cột trái',
                        controllers: _leftCtrls,
                        onAdd: _addLeft,
                        onRemove: _removeLeft,
                        onChanged: () => setState(() {
                          _matchingPairs = _validMatchingPairs;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MatchingColumnEditor(
                        title: 'Cột phải',
                        controllers: _rightCtrls,
                        onAdd: _addRight,
                        onRemove: _removeRight,
                        onChanged: () => setState(() {
                          _matchingPairs = _validMatchingPairs;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _DialogSectionLabel('Đáp án đúng'),
                const SizedBox(height: 8),
                MatchingPairBoard(
                  leftItems: _leftTexts,
                  rightItems: _rightTexts,
                  pairs: _validMatchingPairs,
                  onChanged: (pairs) => setState(() => _matchingPairs = pairs),
                  hint:
                      'Nối đúng như học sinh sẽ làm: chạm trái rồi chạm phải.',
                ),
              ],
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(96, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {
            final draft = _build();
            if (draft == null) {
              AppToast.error(
                widget.itemType == AssessmentItemType.matching
                    ? 'Cần ≥2 mục mỗi cột, không trùng, và nối đủ đáp án đúng.'
                    : 'Thiếu nội dung câu hỏi hoặc đáp án.',
              );
              return;
            }
            Navigator.pop(context, draft);
          },
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Thêm'),
        ),
      ],
    );
  }
}

class _DialogSectionLabel extends StatelessWidget {
  const _DialogSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

/// Glass chips matching [GradeLevelSelector] — used for correct-answer picks.
class _ChipAnswerSelector<T> extends StatelessWidget {
  const _ChipAnswerSelector({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.wide = false,
  });

  final String label;
  final T value;
  final List<({T value, String label})> options;
  final ValueChanged<T> onChanged;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              _AnswerChip(
                label: option.label,
                selected: value == option.value,
                wide: wide,
                onTap: () => onChanged(option.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.wide = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<GlassTheme>() ?? GlassTheme.light;
    final radius = BorderRadius.circular(glass.borderRadius * 0.55);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: wide ? 88 : 52,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: selected
                  ? scheme.surfaceContainerHighest.withValues(alpha: 0.92)
                  : scheme.surface.withValues(alpha: 0.55),
              border: Border.all(
                color: selected
                    ? scheme.onSurface.withValues(alpha: 0.55)
                    : scheme.outlineVariant.withValues(alpha: 0.4),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: scheme.onSurface.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.letter,
    required this.controller,
  });

  final String letter;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<GlassTheme>() ?? GlassTheme.light;

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: 'Nội dung lựa chọn $letter',
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: UnconstrainedBox(
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(glass.borderRadius * 0.4),
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                letter,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
              ),
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 48),
      ),
    );
  }
}

class _MatchingColumnEditor extends StatelessWidget {
  const _MatchingColumnEditor({
    required this.title,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final String title;
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < controllers.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controllers[i],
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Mục ${i + 1}',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Xoá',
                onPressed:
                    controllers.length <= 1 ? null : () => onRemove(i),
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Thêm'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(40),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}
