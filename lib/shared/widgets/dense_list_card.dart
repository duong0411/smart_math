import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';

/// One glass card with dense rows, dividers, and an optional count header.
class DenseListCard extends StatelessWidget {
  const DenseListCard({
    super.key,
    required this.children,
    this.header,
    this.count,
    this.emptyLabel,
  });

  /// Section title shown above the card (e.g. "Lớp học").
  final String? header;

  /// Shown as `(n)` next to [header].
  final int? count;

  final List<Widget> children;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) ...[
          Row(
            children: [
              Text(
                header!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Text(
                  '($count)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (children.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              emptyLabel ?? 'Chưa có dữ liệu.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          )
        else
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 48,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  children[i],
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Compact list row with small avatar / icon leading.
class DenseListRow extends StatelessWidget {
  const DenseListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.leadingIcon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = title.trim().isNotEmpty ? title.trim()[0].toUpperCase() : '?';

    final leadingWidget = leading ??
        CircleAvatar(
          radius: 14,
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          foregroundColor: scheme.primary,
          child: leadingIcon != null
              ? Icon(leadingIcon, size: 16)
              : Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        );

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      minVerticalPadding: 4,
      leading: leadingWidget,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
      trailing: trailing ??
          (onTap == null
              ? null
              : Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                )),
      onTap: onTap,
    );
  }
}
