import 'dart:math' as math;
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
                  const Color(0xFF0F172A),
                  scheme.surface,
                  const Color(0xFF1E1B4B),
                ]
              : [
                  const Color(0xFFEEF2FF),
                  const Color(0xFFFDF4FF),
                  const Color(0xFFFFF1F2),
                ],
        ),
      ),
      child: Stack(
        children: [
          // Animated Glow Orbs for dynamic feel
          Positioned(
            top: -150,
            right: -100,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 10),
              curve: Curves.easeInOutSine,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(math.sin(value * math.pi * 2) * 30, math.cos(value * math.pi * 2) * 30),
                  child: _GlowOrb(
                    size: 600,
                    color: const Color(0xFFFACC15).withValues(alpha: isDark ? 0.35 : 0.45), // Golden VN star
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -200,
            left: -150,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1, end: 0),
              duration: const Duration(seconds: 12),
              curve: Curves.easeInOutSine,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(math.cos(value * math.pi * 2) * -40, math.sin(value * math.pi * 2) * 40),
                  child: _GlowOrb(
                    size: 800,
                    color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.25 : 0.4), // Red VN flag
                  ),
                );
              },
            ),
          ),
          Positioned(
             top: MediaQuery.sizeOf(context).height * 0.2,
             left: MediaQuery.sizeOf(context).width * 0.4,
             child: TweenAnimationBuilder<double>(
               tween: Tween<double>(begin: 0, end: 1),
               duration: const Duration(seconds: 8),
               curve: Curves.easeInOutSine,
               builder: (context, value, child) {
                 return Transform.scale(
                   scale: 1.0 + math.sin(value * math.pi * 2) * 0.1,
                   child: _GlowOrb(
                     size: 500,
                     color: scheme.primary.withValues(alpha: isDark ? 0.3 : 0.4), // AI Cyan/Blue
                   ),
                 );
               }
             ),
          ),
          // Tech Lotus Motif - Made much more visible
          Positioned.fill(
            child: CustomPaint(
              painter: _TechLotusPainter(
                color: scheme.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _TechLotusPainter extends CustomPainter {
  _TechLotusPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5 // Thicker line
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3); // Glow effect

    final center = Offset(size.width / 2, size.height * 0.65);
    final maxRadius = size.width * 0.6;

    // Draw abstract tech lotus petals using overlapping bezier curves
    for (int i = 0; i < 5; i++) {
      final path = Path();
      final widthOffset = (i - 2) * 50.0;
      final heightOffset = 100.0 - (i - 2).abs() * 30.0;

      path.moveTo(center.dx, center.dy);
      path.quadraticBezierTo(
        center.dx + widthOffset * 1.5,
        center.dy - heightOffset * 1.5,
        center.dx + widthOffset,
        center.dy - heightOffset * 3,
      );
      path.quadraticBezierTo(
        center.dx - widthOffset * 1.5,
        center.dy - heightOffset * 1.5,
        center.dx,
        center.dy,
      );
      canvas.drawPath(path, paint);
    }

    // Draw tech grid dots at intersections
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(center.dx, center.dy - 300), 3, dotPaint);
    canvas.drawCircle(Offset(center.dx - 50, center.dy - 240), 3, dotPaint);
    canvas.drawCircle(Offset(center.dx + 50, center.dy - 240), 3, dotPaint);
    canvas.drawCircle(Offset(center.dx - 100, center.dy - 120), 3, dotPaint);
    canvas.drawCircle(Offset(center.dx + 100, center.dy - 120), 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        ? const Color(0xFFF3F4F6)
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
                                ? Colors.black26
                                : scheme.outlineVariant)
                            .withValues(alpha: 0.45),
                        linkColor:
                            isUser ? scheme.primary : scheme.primary,
                        h1: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isUser
                                  ? Colors.black87
                                  : scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                        h2: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isUser
                                  ? Colors.black87
                                  : scheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                        h3: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: isUser
                                  ? Colors.black87
                                  : scheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      child: GptMarkdown(
                        text,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: isUser
                                      ? Colors.black87
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
