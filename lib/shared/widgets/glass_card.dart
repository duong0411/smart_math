import 'dart:ui';

import 'package:eduself_study_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<GlassTheme>() ?? GlassTheme.light;
    final radius = BorderRadius.circular(glass.borderRadius);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : scheme.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.20)
                : const Color(0xFF64748B).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.92)
                  : Colors.white.withValues(alpha: 0.94),
              borderRadius: radius,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFE2E8F0),
                width: 1.0,
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

/// A clean, distraction-free educational background designed specifically for Math students.
/// Features a calm pastel gradient, subtle math graph paper grid, and gentle corner lighting.
/// Leaves the entire center 100% clean and unobstructed so all formulas and text are perfectly readable.
class AtmosphericBackground extends StatelessWidget {
  const AtmosphericBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF0F172A),
                  Color(0xFF111E36),
                  Color(0xFF0B132B),
                ]
              : const [
                  Color(0xFFF8FAFC),
                  Color(0xFFF1F5F9),
                  Color(0xFFEBF2F7),
                ],
        ),
      ),
      child: Stack(
        children: [
          // Gentle ambient corner glow - Top Left (Sky Blue)
          Positioned(
            top: -120,
            left: -100,
            child: _AmbientGlowOrb(
              size: 380,
              color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.08 : 0.12),
            ),
          ),

          // Gentle ambient corner glow - Bottom Right (Soft Indigo)
          Positioned(
            bottom: -140,
            right: -100,
            child: _AmbientGlowOrb(
              size: 420,
              color: const Color(0xFF818CF8).withValues(alpha: isDark ? 0.07 : 0.10),
            ),
          ),

          // Subtle Math graph paper grid (inspires math focus, never clutters text)
          Positioned.fill(
            child: CustomPaint(
              painter: _MathGridPainter(
                gridColor: isDark
                    ? const Color(0xFF60A5FA).withValues(alpha: 0.025)
                    : const Color(0xFF2563EB).withValues(alpha: 0.035),
                dotColor: isDark
                    ? const Color(0xFF93C5FD).withValues(alpha: 0.04)
                    : const Color(0xFF3B82F6).withValues(alpha: 0.05),
              ),
            ),
          ),

          // Foreground page content with pristine clarity
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _MathGridPainter extends CustomPainter {
  const _MathGridPainter({
    required this.gridColor,
    required this.dotColor,
  });

  final Color gridColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    const double step = 32.0;

    final linePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // Draw vertical grid lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    // Draw horizontal grid lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Draw subtle coordinate intersection dots every 2 grid steps
    const double dotStep = step * 2;
    for (double x = dotStep; x < size.width; x += dotStep) {
      for (double y = dotStep; y < size.height; y += dotStep) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MathGridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor || oldDelegate.dotColor != dotColor;
}

class _AmbientGlowOrb extends StatelessWidget {
  const _AmbientGlowOrb({required this.size, required this.color});

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
            Icons.calculate_rounded,
            size: size * 0.44,
            color: scheme.onPrimary,
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: 18),
          Text(
            'EduSelf Toán AI',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(20);
    final fill = isUser
        ? const Color(0xFF2563EB)
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

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
                      .withValues(alpha: isUser ? 0.18 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: fill,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onLongPress: onLongPress,
                borderRadius: radius,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: isUser
                        ? null
                        : Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0xFFE2E8F0),
                          ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: GptMarkdownTheme(
                      gptThemeData: GptMarkdownThemeData(
                        brightness: isUser ? Brightness.dark : Theme.of(context).brightness,
                        hrLineColor: (isUser
                                ? Colors.white24
                                : scheme.outlineVariant)
                            .withValues(alpha: 0.45),
                        linkColor:
                            isUser ? Colors.white : scheme.primary,
                        h1: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isUser
                                  ? Colors.white
                                  : scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                        h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isUser
                                  ? Colors.white
                                  : scheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                        h3: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: isUser
                                  ? Colors.white
                                  : scheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      child: GptMarkdown(
                        text,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: isUser
                                      ? Colors.white
                                      : scheme.onSurface,
                                  height: 1.45,
                                ),
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
