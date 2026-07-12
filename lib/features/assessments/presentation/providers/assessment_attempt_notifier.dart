import 'dart:async';

import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_enums.dart';
import 'package:eduself_study_app/features/assessments/domain/entities/assessment_models.dart';
import 'package:eduself_study_app/features/assessments/presentation/providers/assessments_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssessmentAttemptState {
  const AssessmentAttemptState({
    required this.detail,
    required this.attempt,
    required this.responses,
    this.saving = false,
    this.submitting = false,
    this.error,
    this.remaining,
    this.autoSubmitted = false,
  });

  final AssessmentDetail detail;
  final AssessmentAttempt attempt;
  final Map<int, Map<String, dynamic>> responses;
  final bool saving;
  final bool submitting;
  final String? error;
  final Duration? remaining;
  final bool autoSubmitted;

  AssessmentAttemptState copyWith({
    AssessmentDetail? detail,
    AssessmentAttempt? attempt,
    Map<int, Map<String, dynamic>>? responses,
    bool? saving,
    bool? submitting,
    String? error,
    bool clearError = false,
    Duration? remaining,
    bool clearRemaining = false,
    bool? autoSubmitted,
  }) {
    return AssessmentAttemptState(
      detail: detail ?? this.detail,
      attempt: attempt ?? this.attempt,
      responses: responses ?? this.responses,
      saving: saving ?? this.saving,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
      remaining: clearRemaining ? null : (remaining ?? this.remaining),
      autoSubmitted: autoSubmitted ?? this.autoSubmitted,
    );
  }
}

class AssessmentAttemptNotifier
    extends AutoDisposeFamilyAsyncNotifier<AssessmentAttemptState, int> {
  final Map<int, Timer> _debounce = {};
  Timer? _countdown;
  var _autoSubmitStarted = false;

  @override
  Future<AssessmentAttemptState> build(int assessmentId) async {
    ref.onDispose(() {
      for (final t in _debounce.values) {
        t.cancel();
      }
      _countdown?.cancel();
    });

    final detailResult = await ref.read(getAssessmentProvider)(assessmentId);
    final detail = switch (detailResult) {
      Success(:final value) => value,
      FailureResult(:final failure) => throw Exception(failure.message),
    };

    final attemptResult =
        await ref.read(startAssessmentAttemptProvider)(assessmentId);
    final attempt = switch (attemptResult) {
      Success(:final value) => value,
      FailureResult(:final failure) => throw Exception(failure.message),
    };

    // If already submitted/graded, load full attempt with answers.
    var loaded = attempt;
    if (attempt.status != AttemptStatus.inProgress) {
      final full = await ref.read(getAssessmentAttemptProvider)(attempt.id);
      loaded = switch (full) {
        Success(:final value) => value,
        FailureResult() => attempt,
      };
    }

    final responses = <int, Map<String, dynamic>>{
      for (final a in loaded.answers)
        a.itemId: Map<String, dynamic>.from(a.response),
    };

    final remaining = _remainingFor(loaded);
    final state = AssessmentAttemptState(
      detail: detail,
      attempt: loaded,
      responses: responses,
      remaining: remaining,
    );
    _startCountdownIfNeeded(loaded);
    return state;
  }

  Duration? _remainingFor(AssessmentAttempt attempt) {
    final endsAt = attempt.endsAtUtc;
    if (endsAt == null || attempt.status != AttemptStatus.inProgress) {
      return null;
    }
    final left = endsAt.difference(DateTime.now().toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  void _startCountdownIfNeeded(AssessmentAttempt attempt) {
    _countdown?.cancel();
    if (attempt.endsAtUtc == null ||
        attempt.status != AttemptStatus.inProgress) {
      return;
    }
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.valueOrNull;
      if (current == null) return;
      if (current.attempt.status != AttemptStatus.inProgress) {
        _countdown?.cancel();
        return;
      }
      final remaining = _remainingFor(current.attempt) ?? Duration.zero;
      state = AsyncData(current.copyWith(remaining: remaining));
      if (remaining <= Duration.zero) {
        _countdown?.cancel();
        unawaited(_autoSubmitOnTimeout());
      }
    });
  }

  Future<void> _autoSubmitOnTimeout() async {
    if (_autoSubmitStarted) return;
    _autoSubmitStarted = true;
    final attempt = await submit();
    final latest = state.valueOrNull;
    if (latest == null) return;
    if (attempt != null) {
      state = AsyncData(latest.copyWith(autoSubmitted: true, attempt: attempt));
    }
  }

  Future<void> setResponse(int itemId, Map<String, dynamic> response) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.attempt.status != AttemptStatus.inProgress) return;

    final nextResponses = Map<int, Map<String, dynamic>>.from(current.responses)
      ..[itemId] = response;
    state = AsyncData(
      current.copyWith(responses: nextResponses, clearError: true),
    );

    _debounce[itemId]?.cancel();
    _debounce[itemId] = Timer(const Duration(milliseconds: 450), () {
      unawaited(_persist(itemId, response));
    });
  }

  Future<void> _persist(int itemId, Map<String, dynamic> response) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(saving: true, clearError: true));

    final result = await ref.read(saveAssessmentAnswerProvider)(
      attemptId: current.attempt.id,
      itemId: itemId,
      response: response,
    );

    final latest = state.valueOrNull ?? current;
    switch (result) {
      case Success():
        state = AsyncData(latest.copyWith(saving: false, clearError: true));
      case FailureResult(:final failure):
        state = AsyncData(
          latest.copyWith(saving: false, error: failure.message),
        );
        if (failure.message.contains('Hết giờ')) {
          unawaited(_autoSubmitOnTimeout());
        }
    }
  }

  Future<AssessmentAttempt?> submit() async {
    final current = state.valueOrNull;
    if (current == null) return null;
    if (current.attempt.status != AttemptStatus.inProgress) {
      return current.attempt;
    }

    // Flush pending saves.
    for (final entry in _debounce.entries) {
      entry.value.cancel();
      final response = current.responses[entry.key];
      if (response != null) {
        await _persist(entry.key, response);
      }
    }
    _debounce.clear();

    final latest = state.valueOrNull ?? current;
    state = AsyncData(latest.copyWith(submitting: true, clearError: true));

    final result =
        await ref.read(submitAssessmentAttemptProvider)(latest.attempt.id);

    switch (result) {
      case Success(:final value):
        _countdown?.cancel();
        state = AsyncData(
          latest.copyWith(
            attempt: value,
            submitting: false,
            clearError: true,
            clearRemaining: true,
          ),
        );
        return value;
      case FailureResult(:final failure):
        state = AsyncData(
          latest.copyWith(submitting: false, error: failure.message),
        );
        return null;
    }
  }
}

final assessmentAttemptSessionProvider = AsyncNotifierProvider.autoDispose
    .family<AssessmentAttemptNotifier, AssessmentAttemptState, int>(
  AssessmentAttemptNotifier.new,
);
