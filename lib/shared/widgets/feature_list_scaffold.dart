import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// AtmosphericBackground is exported from glass_card.dart.

/// Shared glass list scaffold for Phase 1 feature screens.
///
/// Non-empty lists render as one dense [DenseListCard] with dividers.
class FeatureListScaffold<T> extends ConsumerWidget {
  const FeatureListScaffold({
    super.key,
    required this.title,
    required this.value,
    required this.itemBuilder,
    this.onRefresh,
    this.emptyTitle = 'Chưa có dữ liệu',
    this.emptySubtitle = 'Em quay lại sau hoặc tạo mục mới nhé.',
    this.floatingActionButton,
    this.listHeader,
  });

  final String title;
  final AsyncValue<List<T>> value;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Future<void> Function()? onRefresh;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget? floatingActionButton;

  /// Optional section label above the dense card (defaults to [title]).
  final String? listHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(title),
        ),
        drawer: const AppDrawer(),
        floatingActionButton: floatingActionButton,
        body: value.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.cloud_off_rounded, color: scheme.error, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'Không tải được dữ liệu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$error',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    if (onRefresh != null) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: onRefresh,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  GlassCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 40,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          emptyTitle,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          emptySubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final list = ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 88),
              children: [
                DenseListCard(
                  header: listHeader ?? title,
                  count: items.length,
                  children: [
                    for (final item in items) itemBuilder(context, item),
                  ],
                ),
              ],
            );

            if (onRefresh == null) return list;
            return RefreshIndicator(
              onRefresh: onRefresh!,
              child: list,
            );
          },
        ),
      ),
    );
  }
}
