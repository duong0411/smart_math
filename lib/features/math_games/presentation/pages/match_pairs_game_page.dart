import 'dart:async';

import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/features/math_games/domain/math_game_engine.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MatchPairsGamePage extends ConsumerStatefulWidget {
  const MatchPairsGamePage({super.key});

  @override
  ConsumerState<MatchPairsGamePage> createState() => _MatchPairsGamePageState();
}

class _MatchPairsGamePageState extends ConsumerState<MatchPairsGamePage> {
  late MathGameDifficulty _difficulty;
  var _cards = <_CardModel>[];
  String? _firstId;
  var _lock = false;
  var _moves = 0;
  var _matched = 0;
  var _started = false;
  var _won = false;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _difficulty = MathGameDifficulty.medium;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final grade = ref.read(mathProfileProvider).valueOrNull?.gradeLevel;
      setState(() {
        _difficulty = MathGameEngine.difficultyForGrade(grade);
      });
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _deal() {
    _clock?.cancel();
    final pairs = MathGameEngine.matchPairs(_difficulty, pairCount: 4);
    setState(() {
      _cards = [
        for (final p in pairs)
          _CardModel(id: p.id, face: p.face, pairId: p.pairId),
      ];
      _firstId = null;
      _lock = false;
      _moves = 0;
      _matched = 0;
      _started = true;
      _won = false;
      _startedAt = DateTime.now();
      _elapsed = Duration.zero;
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _startedAt == null || _won) return;
      setState(() => _elapsed = DateTime.now().difference(_startedAt!));
    });
  }

  Future<void> _flip(_CardModel card) async {
    if (!_started || _lock || card.faceUp || card.matched) return;
    setState(() => card.faceUp = true);
    HapticFeedback.selectionClick();

    if (_firstId == null) {
      _firstId = card.id;
      return;
    }

    final first = _cards.firstWhere((c) => c.id == _firstId);
    _lock = true;
    _moves += 1;

    if (first.pairId == card.pairId) {
      HapticFeedback.lightImpact();
      setState(() {
        first.matched = true;
        card.matched = true;
        _matched += 1;
        _firstId = null;
        _lock = false;
      });
      if (_matched >= 4) {
        _clock?.cancel();
        setState(() => _won = true);
        await _logWin();
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        first.faceUp = false;
        card.faceUp = false;
        _firstId = null;
        _lock = false;
      });
    }
  }

  Future<void> _logWin() async {
    await ref.read(mathLocalStoreProvider).addEvent(
          MathStudyEvent(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: MathStudyEventType.game,
            topic: 'Ghép đôi Toán',
            detail: '$_moves lượt · ${_fmt(_elapsed)}',
            correct: true,
            at: DateTime.now().toUtc(),
          ),
        );
    ref.invalidate(mathEventsProvider);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Ghép đôi Toán'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Lượt $_moves',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      _fmt(_elapsed),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final d in MathGameDifficulty.values)
                        ChoiceChip(
                          label: Text(switch (d) {
                            MathGameDifficulty.easy => 'Dễ',
                            MathGameDifficulty.medium => 'Vừa',
                            MathGameDifficulty.hard => 'Khó',
                          }),
                          selected: _difficulty == d,
                          onSelected: _started && !_won
                              ? null
                              : (_) => setState(() => _difficulty = d),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: !_started
                        ? _Intro(onStart: _deal)
                        : _won
                            ? _WinPanel(
                                moves: _moves,
                                time: _fmt(_elapsed),
                                onAgain: _deal,
                              )
                            : GridView.builder(
                                itemCount: _cards.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.35,
                                ),
                                itemBuilder: (context, i) {
                                  final card = _cards[i];
                                  return _FlipCard(
                                    card: card,
                                    onTap: () => _flip(card),
                                  );
                                },
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

class _CardModel {
  _CardModel({
    required this.id,
    required this.face,
    required this.pairId,
  });

  final String id;
  final String face;
  final String pairId;
  bool faceUp = false;
  bool matched = false;
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({required this.card, required this.onTap});
  final _CardModel card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final show = card.faceUp || card.matched;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: Material(
        color: show
            ? (card.matched
                ? const Color(0xFF2A9D8F)
                : scheme.primaryContainer)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                show ? card.face : '?',
                key: ValueKey('${card.id}-$show'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: show
                          ? (card.matched
                              ? Colors.white
                              : scheme.onPrimaryContainer)
                          : scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧩', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              'Lật thẻ để ghép phép tính với kết quả đúng.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ít lượt nhất — thắng đẹp nhất!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Xào bài'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinPanel extends StatelessWidget {
  const _WinPanel({
    required this.moves,
    required this.time,
    required this.onAgain,
  });

  final int moves;
  final String time;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            'Hoàn thành!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text('$moves lượt · $time'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAgain,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Chơi ván mới'),
          ),
        ],
      ),
    );
  }
}
