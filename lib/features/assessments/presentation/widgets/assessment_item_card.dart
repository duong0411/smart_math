import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/presentation/widgets/matching_pair_board.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class AssessmentItemCard extends StatelessWidget {
  const AssessmentItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.response,
    required this.onChanged,
    this.readOnly = false,
  });

  final int index;
  final AssessmentItem item;
  final Map<String, dynamic>? response;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Câu ${index + 1} · ${item.itemType.labelVi} · ${item.points} điểm',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            item.prompt,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 16),
          switch (item.itemType) {
            AssessmentItemType.mcq => _McqBody(
                item: item,
                selectedId: response?['selectedOptionId']?.toString(),
                onChanged: readOnly
                    ? null
                    : (id) => onChanged({'selectedOptionId': id}),
              ),
            AssessmentItemType.trueFalse => _TrueFalseBody(
                value: response?['value'] as bool?,
                onChanged: readOnly
                    ? null
                    : (v) => onChanged({'value': v}),
              ),
            AssessmentItemType.fillBlank => _FillBlankBody(
                text: (response?['text'] ?? response?['value'] ?? '').toString(),
                onChanged: readOnly
                    ? null
                    : (t) => onChanged({'text': t}),
              ),
            AssessmentItemType.essay => _EssayBody(
                text: (response?['text'] ?? '').toString(),
                onChanged: readOnly
                    ? null
                    : (t) => onChanged({'text': t}),
              ),
            AssessmentItemType.matching => _MatchingBody(
                item: item,
                pairs: _asStringMap(response?['pairs']),
                onChanged: readOnly
                    ? null
                    : (pairs) => onChanged({'pairs': pairs}),
              ),
          },
        ],
      ),
    );
  }

  Map<String, String> _asStringMap(Object? raw) {
    if (raw is! Map) return {};
    return {
      for (final e in raw.entries) e.key.toString(): e.value.toString(),
    };
  }
}

class _McqBody extends StatelessWidget {
  const _McqBody({
    required this.item,
    required this.selectedId,
    required this.onChanged,
  });

  final AssessmentItem item;
  final String? selectedId;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final choices = item.mcqChoices;
    if (choices.isEmpty) {
      return const Text('Câu hỏi chưa có lựa chọn.');
    }
    return RadioGroup<String>(
      groupValue: selectedId,
      onChanged: onChanged == null
          ? (_) {}
          : (v) {
              if (v != null) onChanged!(v);
            },
      child: Column(
        children: [
          for (final choice in choices)
            RadioListTile<String>(
              value: choice.id,
              enabled: onChanged != null,
              title: Text(choice.text),
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

class _TrueFalseBody extends StatelessWidget {
  const _TrueFalseBody({required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('Đúng'), icon: Icon(Icons.check)),
        ButtonSegment(value: false, label: Text('Sai'), icon: Icon(Icons.close)),
      ],
      emptySelectionAllowed: true,
      selected: value == null ? <bool>{} : {value!},
      onSelectionChanged: onChanged == null
          ? null
          : (set) {
              if (set.isNotEmpty) onChanged!(set.first);
            },
    );
  }
}

class _FillBlankBody extends StatelessWidget {
  const _FillBlankBody({required this.text, required this.onChanged});

  final String text;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: text,
      enabled: onChanged != null,
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Câu trả lời',
        hintText: 'Em điền đáp án…',
      ),
    );
  }
}

class _EssayBody extends StatelessWidget {
  const _EssayBody({required this.text, required this.onChanged});

  final String text;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: text,
      enabled: onChanged != null,
      minLines: 4,
      maxLines: 8,
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Bài làm',
        hintText: 'Em viết câu trả lời…',
        alignLabelWithHint: true,
      ),
    );
  }
}

class _MatchingBody extends StatelessWidget {
  const _MatchingBody({
    required this.item,
    required this.pairs,
    required this.onChanged,
  });

  final AssessmentItem item;
  final Map<String, String> pairs;
  final ValueChanged<Map<String, String>>? onChanged;

  @override
  Widget build(BuildContext context) {
    final leftKeys = item.matchingLeftRight.keys.toList();
    final rightOptions = item.matchingRightBank.isNotEmpty
        ? item.matchingRightBank
        : (item.matchingLeftRight.values
            .where((v) => v.isNotEmpty)
            .toSet()
            .toList()
          ..sort());

    if (leftKeys.isEmpty || rightOptions.isEmpty) {
      return Text(
        'Câu nối cặp chưa có đủ mục ở hai cột.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return MatchingPairBoard(
      leftItems: leftKeys,
      rightItems: rightOptions,
      pairs: pairs,
      onChanged: onChanged,
      hint: onChanged == null
          ? null
          : 'Chạm cột trái, rồi chạm cột phải để nối. Chạm lại cặp đã nối để huỷ.',
    );
  }
}
