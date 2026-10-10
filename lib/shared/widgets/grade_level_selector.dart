import 'package:eduself_study_app/core/theme/app_theme.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:flutter/material.dart';

/// Rounded glass grade chips for supported THCS grades (6–9).
class GradeLevelSelector extends StatelessWidget {
  const GradeLevelSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Lớp (THCS)',
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
            for (final grade in SupportedGrades.all)
              _GradeChip(
                grade: grade,
                selected: value == grade,
                onTap: () => onChanged(grade),
              ),
          ],
        ),
      ],
    );
  }
}

class _GradeChip extends StatelessWidget {
  const _GradeChip({
    required this.grade,
    required this.selected,
    required this.onTap,
  });

  final int grade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<GlassTheme>() ?? GlassTheme.light;
    final radius = BorderRadius.circular(glass.borderRadius * 0.55);
    final selectedBg = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.14),
      scheme.surface,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: 'Lớp $grade',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 52,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: selected
                  ? selectedBg
                  : scheme.surface.withValues(alpha: 0.45),
              border: Border.all(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.28)
                    : scheme.outlineVariant.withValues(alpha: 0.4),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              '$grade',
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
