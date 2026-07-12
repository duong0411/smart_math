import 'package:eduself_study_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Tap-to-connect matching board for students (and teacher answer key).
///
/// Flow: chạm một mục cột trái → chạm mục cột phải để nối.
/// Chạm lại cặp đã nối để huỷ.
class MatchingPairBoard extends StatefulWidget {
  const MatchingPairBoard({
    super.key,
    required this.leftItems,
    required this.rightItems,
    required this.pairs,
    this.onChanged,
    this.hint =
        'Chạm cột trái, rồi chạm cột phải để nối. Chạm lại để huỷ nối.',
  });

  final List<String> leftItems;
  final List<String> rightItems;
  final Map<String, String> pairs;
  final ValueChanged<Map<String, String>>? onChanged;
  final String? hint;

  @override
  State<MatchingPairBoard> createState() => _MatchingPairBoardState();
}

class _MatchingPairBoardState extends State<MatchingPairBoard> {
  String? _selectedLeft;

  bool get _editable => widget.onChanged != null;

  int? _pairIndexFor(String left) {
    final right = widget.pairs[left];
    if (right == null || right.isEmpty) return null;
    final ordered = widget.leftItems
        .where((l) => (widget.pairs[l] ?? '').isNotEmpty)
        .toList();
    final i = ordered.indexOf(left);
    return i < 0 ? null : i;
  }

  String? _leftForRight(String right) {
    for (final e in widget.pairs.entries) {
      if (e.value == right) return e.key;
    }
    return null;
  }

  void _tapLeft(String left) {
    if (!_editable) return;
    final existing = widget.pairs[left];
    if (existing != null && existing.isNotEmpty && _selectedLeft == null) {
      // First tap on an already-matched left → clear that pair.
      final next = Map<String, String>.from(widget.pairs)..remove(left);
      widget.onChanged!(next);
      setState(() => _selectedLeft = null);
      return;
    }
    setState(() {
      _selectedLeft = _selectedLeft == left ? null : left;
    });
  }

  void _tapRight(String right) {
    if (!_editable) return;
    final selected = _selectedLeft;
    if (selected == null) {
      // Tap matched right alone → unpair.
      final left = _leftForRight(right);
      if (left != null) {
        final next = Map<String, String>.from(widget.pairs)..remove(left);
        widget.onChanged!(next);
      }
      return;
    }

    final next = Map<String, String>.from(widget.pairs);
    // Free this right if used by another left.
    next.removeWhere((_, v) => v == right);
    next[selected] = right;
    widget.onChanged!(next);
    setState(() => _selectedLeft = null);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final left = widget.leftItems.where((e) => e.trim().isNotEmpty).toList();
    final right = widget.rightItems.where((e) => e.trim().isNotEmpty).toList();

    if (left.isEmpty || right.isEmpty) {
      return Text(
        'Chưa đủ mục để nối cặp.',
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.hint != null && _editable) ...[
          Text(
            widget.hint!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ColumnCaption(label: 'Cột trái', scheme: scheme),
                  const SizedBox(height: 8),
                  for (final item in left) ...[
                    _MatchTile(
                      text: item,
                      selected: _selectedLeft == item,
                      pairIndex: _pairIndexFor(item),
                      onTap: () => _tapLeft(item),
                      enabled: _editable,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 36, left: 6, right: 6),
              child: Icon(
                Icons.compare_arrows_rounded,
                color: scheme.outline,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ColumnCaption(label: 'Cột phải', scheme: scheme),
                  const SizedBox(height: 8),
                  for (final item in right) ...[
                    _MatchTile(
                      text: item,
                      selected: false,
                      pairIndex: () {
                        final leftKey = _leftForRight(item);
                        return leftKey == null
                            ? null
                            : _pairIndexFor(leftKey);
                      }(),
                      waitingForPair: _selectedLeft != null,
                      onTap: () => _tapRight(item),
                      enabled: _editable,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (_editable && widget.pairs.isNotEmpty) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                widget.onChanged!({});
                setState(() => _selectedLeft = null);
              },
              icon: const Icon(Icons.link_off_rounded, size: 18),
              label: const Text('Huỷ tất cả nối'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ColumnCaption extends StatelessWidget {
  const _ColumnCaption({required this.label, required this.scheme});

  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.text,
    required this.selected,
    required this.pairIndex,
    required this.onTap,
    required this.enabled,
    this.waitingForPair = false,
  });

  final String text;
  final bool selected;
  final int? pairIndex;
  final VoidCallback onTap;
  final bool enabled;
  final bool waitingForPair;

  static const _pairColors = <Color>[
    Color(0xFF0F766E),
    Color(0xFFB45309),
    Color(0xFF7C3AED),
    Color(0xFFBE123C),
    Color(0xFF0369A1),
    Color(0xFF4D7C0F),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<GlassTheme>() ?? GlassTheme.light;
    final radius = BorderRadius.circular(glass.borderRadius * 0.55);
    final paired = pairIndex != null;
    final accent = paired
        ? _pairColors[pairIndex! % _pairColors.length]
        : (selected ? scheme.onSurface : scheme.outlineVariant);

    return Semantics(
      button: enabled,
      selected: selected || paired,
      label: text,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: radius,
              color: selected
                  ? scheme.surfaceContainerHighest.withValues(alpha: 0.95)
                  : paired
                      ? accent.withValues(alpha: 0.10)
                      : waitingForPair
                          ? scheme.surfaceContainerHighest
                              .withValues(alpha: 0.55)
                          : scheme.surface.withValues(alpha: 0.55),
              border: Border.all(
                color: selected || paired
                    ? accent.withValues(alpha: 0.75)
                    : scheme.outlineVariant.withValues(alpha: 0.4),
                width: selected || paired ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                if (paired) ...[
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '${pairIndex! + 1}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              selected || paired ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
