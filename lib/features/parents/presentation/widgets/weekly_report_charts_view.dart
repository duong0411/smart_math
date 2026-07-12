import 'package:eduself_study_app/features/parents/domain/entities/weekly_report.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Visual charts for a weekly report (preview or persisted).
class WeeklyReportChartsView extends StatelessWidget {
  const WeeklyReportChartsView({
    super.key,
    required this.charts,
    this.compact = false,
  });

  final WeeklyReportCharts charts;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final chartHeight = compact ? 160.0 : 200.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle('Tổng quan tuần'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatChip(
                label: 'Phút học',
                value: '${(charts.progress.totalDurationSec / 60).round()}',
                icon: Icons.schedule_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatChip(
                label: 'Hoạt động',
                value: '${charts.progress.totalEvents}',
                icon: Icons.bolt_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatChip(
                label: 'Điểm TB',
                value: charts.avgScorePercent == null
                    ? '—'
                    : '${charts.avgScorePercent!.round()}%',
                icon: Icons.grade_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _StatChip(
                label: 'Bài làm',
                value: '${charts.attemptCount}',
                icon: Icons.quiz_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatChip(
                label: 'Đã chấm',
                value: '${charts.gradedCount}',
                icon: Icons.task_alt_rounded,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
        const SizedBox(height: 20),
        _SectionTitle('Thời gian học theo ngày'),
        const SizedBox(height: 8),
        SizedBox(
          height: chartHeight,
          child: charts.studyMinutesByDay.isEmpty
              ? _EmptyChart(
                  message: 'Chưa có dữ liệu thời gian học tuần này.',
                  scheme: scheme,
                )
              : _StudyMinutesBarChart(days: charts.studyMinutesByDay),
        ),
        const SizedBox(height: 20),
        _SectionTitle('Phân bố theo môn'),
        const SizedBox(height: 8),
        SizedBox(
          height: chartHeight,
          child: charts.progress.bySubject.isEmpty
              ? _EmptyChart(
                  message: 'Chưa có hoạt động theo môn.',
                  scheme: scheme,
                )
              : _SubjectPieChart(
                  entries: charts.progress.bySubject.entries
                      .map(
                        (e) => (
                          label: e.key,
                          value: e.value.durationSec > 0
                              ? e.value.durationSec / 60.0
                              : e.value.count.toDouble(),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        if (charts.assessmentBySubject.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionTitle('Điểm kiểm tra theo môn'),
          const SizedBox(height: 8),
          SizedBox(
            height: chartHeight,
            child: _ScoreBySubjectBars(
              stats: charts.assessmentBySubject.values.toList(growable: false),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _SuggestionsBlock(suggestions: charts.suggestions),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text(
            'Đơn vị: phút học · điểm trung bình (%)',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _SuggestionsBlock extends StatelessWidget {
  const _SuggestionsBlock({required this.suggestions});

  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = suggestions.isNotEmpty
        ? suggestions
        : const [
            'Duy trì lịch học đều mỗi ngày.',
            'Ôn lại các chủ đề điểm thấp hơn trung bình.',
          ];
    final bg = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.12),
      scheme.surface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Gợi ý cải thiện'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.12),
      scheme.surface,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message, required this.scheme});

  final String message;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _StudyMinutesBarChart extends StatelessWidget {
  const _StudyMinutesBarChart({required this.days});

  final List<StudyMinutesDay> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxY = days
        .map((d) => d.minutes)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final chartMax = maxY <= 0 ? 10.0 : (maxY * 1.25).clamp(10, 240);

    return BarChart(
      BarChartData(
        maxY: chartMax.toDouble(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: chartMax / 2,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= days.length) {
                  return const SizedBox.shrink();
                }
                final label = _shortDay(days[index].dateUtc);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].minutes,
                  width: days.length > 5 ? 12 : 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  color: scheme.primary.withValues(alpha: 0.85),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _shortDay(String dateUtc) {
    final parsed = DateTime.tryParse(dateUtc)?.toLocal();
    if (parsed == null) return dateUtc;
    return '${parsed.day}/${parsed.month}';
  }
}

class _SubjectPieChart extends StatelessWidget {
  const _SubjectPieChart({required this.entries});

  final List<({String label, double value})> entries;

  static const _palette = <Color>[
    Color(0xFF0F766E),
    Color(0xFF0284C7),
    Color(0xFFB45309),
    Color(0xFF7C3AED),
    Color(0xFFBE123C),
    Color(0xFF4D7C0F),
  ];

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(0, (a, b) => a + b.value);
    final safeTotal = total <= 0 ? 1.0 : total;

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 28,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    color: _palette[i % _palette.length],
                    value: entries[i].value <= 0 ? 0.01 : entries[i].value,
                    title: '${((entries[i].value / safeTotal) * 100).round()}%',
                    radius: 42,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _palette[i % _palette.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entries[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreBySubjectBars extends StatelessWidget {
  const _ScoreBySubjectBars({required this.stats});

  final List<AssessmentSubjectStat> stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sorted = [...stats]
      ..sort((a, b) => b.attemptCount.compareTo(a.attemptCount));

    return BarChart(
      BarChartData(
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 50,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sorted.length) {
                  return const SizedBox.shrink();
                }
                final label = sorted[index].subject;
                final short =
                    label.length > 6 ? '${label.substring(0, 6)}…' : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    short,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < sorted.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (sorted[i].avgScorePercent ?? 0).clamp(0, 100),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  color: scheme.tertiary.withValues(alpha: 0.85),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
