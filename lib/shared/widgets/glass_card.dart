import 'dart:ui';

import 'package:eduself_study_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<GlassTheme>() ?? GlassTheme.light;
    final radius = BorderRadius.circular(glass.borderRadius);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Shadow must sit outside ClipRRect or it gets clipped away.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.45 : 0.14),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: scheme.primary.withValues(alpha: isDark ? 0.12 : 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: glass.blurSigma,
            sigmaY: glass.blurSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: glass.fillOpacity),
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: isDark ? 0.10 : 0.55,
                ),
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class AtmosphericBackground extends StatelessWidget {
  const AtmosphericBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF071214),
                  scheme.surface,
                  const Color(0xFF10262A),
                ]
              : [
                  const Color(0xFFE8F8F5),
                  const Color(0xFFF7FBFF),
                  const Color(0xFFEAF4FF),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _GlowOrb(
              size: 220,
              color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.22),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -60,
            child: _GlowOrb(
              size: 260,
              color: scheme.secondary.withValues(alpha: isDark ? 0.14 : 0.16),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 72,
    this.showTitle = true,
    this.subtitle,
  });

  final double size;
  final bool showTitle;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            size: size * 0.42,
            color: scheme.onPrimary,
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: 18),
          Text(
            'EduSelf',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],
        ],
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.onLongPress,
  });

  final String text;
  final bool isUser;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Keep all corners equally rounded to avoid sharp corner artifacts.
    final radius = BorderRadius.circular(20);
    final fill = isUser
        ? null
        : scheme.surfaceContainerLowest.withValues(alpha: 0.96);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: (isUser ? scheme.primary : scheme.shadow)
                      .withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: fill ?? Colors.transparent,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onLongPress: onLongPress,
                borderRadius: radius,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: isUser
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.primary,
                              Color.lerp(
                                scheme.primary,
                                scheme.secondary,
                                0.35,
                              )!,
                            ],
                          )
                        : null,
                    border: isUser
                        ? null
                        : Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.28),
                          ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: GptMarkdownTheme(
                      gptThemeData: GptMarkdownThemeData(
                        brightness: Theme.of(context).brightness,
                        hrLineColor: (isUser
                                ? scheme.onPrimary
                                : scheme.outlineVariant)
                            .withValues(alpha: 0.45),
                        linkColor:
                            isUser ? scheme.onPrimary : scheme.primary,
                        h1: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isUser
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                        h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isUser
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                        h3: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: isUser
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      child: GptMarkdown(
                        text,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: isUser
                                      ? scheme.onPrimary
                                      : scheme.onSurface,
                                  height: 1.45,
                                ),
                        // Gemini tutoring replies use $...$ / $$...$$ for math.
                        useDollarSignsForLatex: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
