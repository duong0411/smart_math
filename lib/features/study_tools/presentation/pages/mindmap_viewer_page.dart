import 'package:eduself_study_app/features/study_tools/presentation/providers/study_tools_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MindmapViewerPage extends ConsumerWidget {
  const MindmapViewerPage({super.key, required this.mindmapId});

  final int mindmapId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mindmapAsync = ref.watch(mindmapDetailProvider(mindmapId));
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(mindmapAsync.valueOrNull?.title ?? 'Mindmap'),
        ),
        drawer: const AppDrawer(),
        body: mindmapAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (mindmap) {
            final nodes = _extractNodes(mindmap.graph);
            final edges = _extractEdges(mindmap.graph);

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        mindmap.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (mindmap.subject != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          mindmap.subject!,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (nodes.isEmpty)
                        Text(
                          'Sơ đồ chưa có nút để hiển thị. '
                          'Định dạng gợi ý: { "nodes": [{ "id", "label" }], "edges": [{ "from", "to" }] }',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final node in nodes)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: scheme.primaryContainer
                                      .withValues(alpha: 0.75),
                                  border: Border.all(
                                    color:
                                        scheme.primary.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  node,
                                  style: TextStyle(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (edges.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Liên kết',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        for (final edge in edges) ...[
                          Row(
                            children: [
                              Expanded(child: Text(edge.$1)),
                              Icon(Icons.arrow_forward_rounded,
                                  color: scheme.primary, size: 18),
                              Expanded(
                                child: Text(
                                  edge.$2,
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<String> _extractNodes(Map<String, dynamic> graph) {
    final raw = graph['nodes'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          (item['label'] ?? item['title'] ?? item['id'] ?? '').toString()
        else if (item is String)
          item,
    ].where((s) => s.trim().isNotEmpty).toList(growable: false);
  }

  List<(String, String)> _extractEdges(Map<String, dynamic> graph) {
    final raw = graph['edges'];
    if (raw is! List) return const [];
    final result = <(String, String)>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final from = (item['from'] ?? item['source'] ?? '').toString();
      final to = (item['to'] ?? item['target'] ?? '').toString();
      if (from.isNotEmpty && to.isNotEmpty) {
        result.add((from, to));
      }
    }
    return result;
  }
}
