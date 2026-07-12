import 'package:eduself_study_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Rounded glass grade chips (1–12), grouped by VN school band.
class GradeLevelSelector extends StatelessWidget {
  const GradeLevelSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int> onChanged;

  static const _bands = <({String label, List<int> grades})>[
    (label: 'Tiểu học', grades: [1, 2, 3, 4, 5]),
    (label: 'THCS', grades: [6, 7, 8, 9]),
    (label: 'THPT', grades: [10, 11, 12]),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Lớp',
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _bands.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          Text(
            _bands[i].label,
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final grade in _bands[i].grades)
                _GradeChip(
                  grade: grade,
                  selected: value == grade,
                  onTap: () => onChanged(grade),
                ),
            ],
          ),
        ],
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
    // Same pale mint wash as FilledButton.tonal / drawer selected item.
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
