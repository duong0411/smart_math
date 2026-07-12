import 'package:eduself_study_app/features/study_tools/presentation/providers/study_tools_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlashcardStudyPage extends ConsumerStatefulWidget {
  const FlashcardStudyPage({super.key, required this.deckId});

  final int deckId;

  @override
  ConsumerState<FlashcardStudyPage> createState() => _FlashcardStudyPageState();
}

class _FlashcardStudyPageState extends ConsumerState<FlashcardStudyPage> {
  var _index = 0;
  var _showBack = false;

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(flashcardDeckProvider(widget.deckId));
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(deckAsync.valueOrNull?.title ?? 'Flashcard'),
        ),
        drawer: const AppDrawer(),
        body: deckAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (deck) {
            if (deck.cards.isEmpty) {
              return const Center(child: Text('Bộ thẻ chưa có nội dung.'));
            }
            final card = deck.cards[_index.clamp(0, deck.cards.length - 1)];
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${_index + 1} / ${deck.cards.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showBack = !_showBack),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: GlassCard(
                          key: ValueKey('${card.id}-$_showBack'),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _showBack ? 'Mặt sau' : 'Mặt trước',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _showBack ? card.back : card.front,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                if (_showBack &&
                                    card.hint != null &&
                                    card.hint!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Gợi ý: ${card.hint}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                Text(
                                  'Chạm để lật thẻ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _index <= 0
                              ? null
                              : () => setState(() {
                                    _index -= 1;
                                    _showBack = false;
                                  }),
                          child: const Text('Trước'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _index >= deck.cards.length - 1
                              ? null
                              : () => setState(() {
                                    _index += 1;
                                    _showBack = false;
                                  }),
                          child: const Text('Sau'),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _index = 0;
                      _showBack = false;
                    }),
                    child: const Text('Học lại từ đầu'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
