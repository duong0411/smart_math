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
                    color: const Color(0xFFFACC15).withValues(alpha: isDark ? 0.35 : 0.65), // Golden VN star
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
                    color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.25 : 0.55), // Red VN flag
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
                     color: scheme.primary.withValues(alpha: isDark ? 0.3 : 0.6), // AI Cyan/Blue
                   ),
                 );
               }
             ),
          ),
          Positioned(
             bottom: MediaQuery.sizeOf(context).height * 0.1,
             right: MediaQuery.sizeOf(context).width * 0.1,
             child: TweenAnimationBuilder<double>(
               tween: Tween<double>(begin: 1, end: 0),
               duration: const Duration(seconds: 15),
               curve: Curves.easeInOutSine,
               builder: (context, value, child) {
                 return Transform.translate(
                   offset: Offset(math.sin(value * math.pi * 2) * -50, math.cos(value * math.pi * 2) * 50),
                   child: _GlowOrb(
                     size: 600,
                     color: scheme.secondary.withValues(alpha: isDark ? 0.3 : 0.65), // Xanh nước biển
                   ),
                 );
               }
             ),
          ),
          // Circular Geography Globe Map (Background Hero)
          Positioned(
            top: -40,
            right: -60,
            child: IgnorePointer(
              child: Opacity(
                opacity: isDark ? 0.34 : 0.22,
                child: Container(
                  width: 580,
                  height: 580,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.38 : 0.20),
                        blurRadius: 80,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/circular_geo_map.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Secondary subtle globe watermark at bottom-left
          Positioned(
            bottom: -150,
            left: -120,
            child: IgnorePointer(
              child: Opacity(
                opacity: isDark ? 0.20 : 0.12,
                child: Container(
                  width: 460,
                  height: 460,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/circular_geo_map.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Circular Geo Coordinate Grid overlay (lat/lon, degree ticks, compass)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GeoCoordinateGridPainter(
                  color: scheme.primary.withValues(alpha: isDark ? 0.45 : 0.65),
                ),
              ),
            ),
          ),
          // Flowing Data Stream Effect
          Positioned.fill(
            child: _DataStreamEffect(
              color: scheme.primary.withValues(alpha: isDark ? 0.5 : 0.8),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _GeoCoordinateGridPainter extends CustomPainter {
  _GeoCoordinateGridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.26)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width * 0.82, size.height * 0.22);
    final radius = math.min(size.width, size.height) * 0.45;

    // Outer graduation ring
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 1.05, paint..strokeWidth = 0.6);

    // Degree tick marks on outer ring
    for (int deg = 0; deg < 360; deg += 15) {
      final rad = deg * math.pi / 180;
      final isMajor = deg % 45 == 0;
      final len = isMajor ? 14.0 : 7.0;
      final p1 = Offset(center.dx + radius * math.cos(rad), center.dy + radius * math.sin(rad));
      final p2 = Offset(center.dx + (radius + len) * math.cos(rad), center.dy + (radius + len) * math.sin(rad));
      canvas.drawLine(p1, p2, paint..strokeWidth = isMajor ? 1.5 : 0.8);
    }

    // Latitude lines (parallels)
    for (double f in [-0.65, -0.35, 0.0, 0.35, 0.65]) {
      final rect = Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * f * 0.75),
        width: radius * 2 * math.sqrt(math.max(0.1, 1 - f * f)),
        height: radius * 0.38,
      );
      canvas.drawOval(rect, f == 0.0 ? dashPaint : paint);
    }

    // Longitude lines (meridians)
    for (double f in [-0.75, -0.45, -0.15, 0.15, 0.45, 0.75]) {
      final rect = Rect.fromCenter(
        center: Offset(center.dx + radius * f * 0.7, center.dy),
        width: radius * 0.42,
        height: radius * 2 * math.sqrt(math.max(0.1, 1 - f * f * 0.6)),
      );
      canvas.drawOval(rect, paint);
    }

    // Compass Rose / Cardinal ticks
    final compassPaint = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    final cLen = radius * 1.12;
    canvas.drawLine(Offset(center.dx, center.dy - cLen), Offset(center.dx, center.dy + cLen), compassPaint);
    canvas.drawLine(Offset(center.dx - cLen, center.dy), Offset(center.dx + cLen, center.dy), compassPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DataStreamEffect extends StatefulWidget {
  final Color color;
  const _DataStreamEffect({required this.color});

  @override
  State<_DataStreamEffect> createState() => _DataStreamEffectState();
}

class _DataStreamEffectState extends State<_DataStreamEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _DataStreamPainter(
            color: widget.color,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      }
    );
  }
}

class _DataStreamPainter extends CustomPainter {
  final Color color;
  final double progress;

  _DataStreamPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    
    final paint = Paint()..strokeWidth = 1.0;
    final dotPaint = Paint()..style = PaintingStyle.fill;
    
    // Scale distance based on screen size, max 150
    final double maxDistance = (size.width / 10).clamp(80.0, 150.0);
    
    // Determine number of points based on area
    final int numPoints = ((size.width * size.height) / 12000).clamp(30, 100).toInt();
    final List<Offset> points = [];

    // Calculate seamlessly looping positions
    for (int i = 0; i < numPoints; i++) {
      final double baseX = (i * 873.123) % size.width;
      final double baseY = (i * 2137.456) % size.height;
      
      final double amplitudeX = 20.0 + (i * 13) % 40;
      final double amplitudeY = 20.0 + (i * 17) % 40;
      final double phaseX = (i * 0.5) % (math.pi * 2);
      final double phaseY = (i * 0.7) % (math.pi * 2);

      final currentPhase = progress * math.pi * 2;
      
      final double x = baseX + math.sin(currentPhase + phaseX) * amplitudeX;
      final double y = baseY + math.cos(currentPhase + phaseY) * amplitudeY;
      
      points.add(Offset(x, y));
    }

    // Draw lines and nodes
    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      
      // Draw node
      final bool isMajorNode = i % 7 == 0;
      dotPaint.color = color.withValues(alpha: isMajorNode ? 0.8 : 0.4);
      canvas.drawCircle(p1, isMajorNode ? 3.0 : 1.5, dotPaint);

      // Draw connections
      for (int j = i + 1; j < points.length; j++) {
        final p2 = points[j];
        final distance = (p1 - p2).distance;

        if (distance < maxDistance) {
          final opacity = 1.0 - (distance / maxDistance);
          paint.color = color.withValues(alpha: opacity * 0.6);
          canvas.drawLine(p1, p2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DataStreamPainter oldDelegate) {
    return oldDelegate.progress != progress;
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
