import 'dart:math';

enum MathGameDifficulty { easy, medium, hard }

class MathQuestion {
  const MathQuestion({
    required this.prompt,
    required this.answer,
    required this.choices,
  });

  final String prompt;
  final int answer;
  final List<int> choices;
}

abstract final class MathGameEngine {
  static final _rng = Random();

  static MathGameDifficulty difficultyForGrade(int? grade) {
    if (grade == null) return MathGameDifficulty.medium;
    if (grade <= 4) return MathGameDifficulty.easy;
    if (grade <= 8) return MathGameDifficulty.medium;
    return MathGameDifficulty.hard;
  }

  static MathQuestion nextQuestion(MathGameDifficulty difficulty) {
    return switch (difficulty) {
      MathGameDifficulty.easy => _easy(),
      MathGameDifficulty.medium => _medium(),
      MathGameDifficulty.hard => _hard(),
    };
  }

  static MathQuestion _easy() {
    final op = _rng.nextInt(3);
    late int a;
    late int b;
    late int answer;
    late String prompt;
    switch (op) {
      case 0:
        a = 1 + _rng.nextInt(20);
        b = 1 + _rng.nextInt(20);
        answer = a + b;
        prompt = '$a + $b = ?';
      case 1:
        a = 5 + _rng.nextInt(20);
        b = 1 + _rng.nextInt(a);
        answer = a - b;
        prompt = '$a − $b = ?';
      default:
        a = 2 + _rng.nextInt(9);
        b = 2 + _rng.nextInt(9);
        answer = a * b;
        prompt = '$a × $b = ?';
    }
    return MathQuestion(
      prompt: prompt,
      answer: answer,
      choices: _choicesAround(answer, spread: 8),
    );
  }

  static MathQuestion _medium() {
    final op = _rng.nextInt(4);
    late int answer;
    late String prompt;
    switch (op) {
      case 0:
        final a = 10 + _rng.nextInt(40);
        final b = 10 + _rng.nextInt(40);
        answer = a + b;
        prompt = '$a + $b = ?';
      case 1:
        final a = 20 + _rng.nextInt(60);
        final b = 5 + _rng.nextInt(a - 4);
        answer = a - b;
        prompt = '$a − $b = ?';
      case 2:
        final a = 3 + _rng.nextInt(12);
        final b = 3 + _rng.nextInt(12);
        answer = a * b;
        prompt = '$a × $b = ?';
      default:
        final b = 2 + _rng.nextInt(9);
        final q = 2 + _rng.nextInt(12);
        final a = b * q;
        answer = q;
        prompt = '$a ÷ $b = ?';
    }
    return MathQuestion(
      prompt: prompt,
      answer: answer,
      choices: _choicesAround(answer, spread: 12),
    );
  }

  static MathQuestion _hard() {
    final op = _rng.nextInt(5);
    late int answer;
    late String prompt;
    switch (op) {
      case 0:
        final a = 12 + _rng.nextInt(40);
        final b = 8 + _rng.nextInt(30);
        final c = 2 + _rng.nextInt(15);
        answer = a + b - c;
        prompt = '$a + $b − $c = ?';
      case 1:
        final a = 6 + _rng.nextInt(15);
        final b = 4 + _rng.nextInt(12);
        answer = a * b;
        prompt = '$a × $b = ?';
      case 2:
        final b = 3 + _rng.nextInt(12);
        final q = 3 + _rng.nextInt(15);
        final a = b * q;
        answer = q;
        prompt = '$a ÷ $b = ?';
      case 3:
        final a = 2 + _rng.nextInt(12);
        answer = a * a;
        prompt = '$a² = ?';
      default:
        final a = 10 + _rng.nextInt(25);
        final b = 2 + _rng.nextInt(9);
        final c = 3 + _rng.nextInt(10);
        answer = a * b + c;
        prompt = '$a × $b + $c = ?';
    }
    return MathQuestion(
      prompt: prompt,
      answer: answer,
      choices: _choicesAround(answer, spread: 20),
    );
  }

  static List<int> _choicesAround(int answer, {required int spread}) {
    final set = <int>{answer};
    var guard = 0;
    while (set.length < 4 && guard < 40) {
      guard++;
      final delta = 1 + _rng.nextInt(spread);
      final candidate = _rng.nextBool() ? answer + delta : answer - delta;
      if (candidate != answer) set.add(candidate);
    }
    while (set.length < 4) {
      set.add(answer + set.length + 1);
    }
    final list = set.toList()..shuffle(_rng);
    return list;
  }

  /// Pairs for memory match: equation ↔ result string.
  static List<({String id, String face, String pairId})> matchPairs(
    MathGameDifficulty difficulty, {
    int pairCount = 4,
  }) {
    final pairs = <({String id, String face, String pairId})>[];
    for (var i = 0; i < pairCount; i++) {
      final q = nextQuestion(difficulty);
      final pairId = 'p$i';
      pairs.add((id: '${pairId}_q', face: q.prompt.replaceAll(' = ?', ''), pairId: pairId));
      pairs.add((id: '${pairId}_a', face: '${q.answer}', pairId: pairId));
    }
    pairs.shuffle(_rng);
    return pairs;
  }
}
