import 'package:eduself_study_app/core/ai/gemini_client.dart';
import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MathTutorChatPage extends ConsumerStatefulWidget {
  const MathTutorChatPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<MathTutorChatPage> createState() => _MathTutorChatPageState();
}

class _MathTutorChatPageState extends ConsumerState<MathTutorChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  MathTutorSession? _session;
  var _loading = true;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session =
        await ref.read(mathLocalStoreProvider).getSession(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _session = session;
      _loading = false;
    });
    if (session != null && session.messages.isEmpty) {
      // Soft welcome without API call if no key — still invite first message.
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _session == null) return;

    setState(() => _sending = true);
    _controller.clear();

    final store = ref.read(mathLocalStoreProvider);
    final now = DateTime.now().toUtc();
    final userMsg = MathChatMessage(
      id: '${now.millisecondsSinceEpoch}-u',
      role: MathChatRole.user,
      content: text,
      at: now,
    );

    try {
      var session = await store.appendMessage(
        sessionId: widget.sessionId,
        message: userMsg,
      );
      if (mounted) setState(() => _session = session);

      final history = [
        for (final m in session.messages.where((m) => m.id != userMsg.id))
          GeminiTurn(
            role: m.role == MathChatRole.user
                ? GeminiRole.user
                : GeminiRole.model,
            text: m.content,
          ),
      ];

      final result = await askMathAi(
        ref,
        userMessage: text,
        history: history,
      );

      switch (result) {
        case Success(:final value):
          final reply = MathChatMessage(
            id: '${DateTime.now().millisecondsSinceEpoch}-m',
            role: MathChatRole.model,
            content: value,
            at: DateTime.now().toUtc(),
          );
          session = await store.appendMessage(
            sessionId: widget.sessionId,
            message: reply,
          );
          await store.addEvent(
            MathStudyEvent(
              id: reply.id,
              type: MathStudyEventType.tutor,
              topic: session.topic ?? 'Gia sư Toán',
              detail: 'Buổi chat · ${session.title}',
              at: reply.at,
            ),
          );
          ref.invalidate(mathSessionsProvider);
          ref.invalidate(mathEventsProvider);
          if (mounted) setState(() => _session = session);
        case FailureResult(:final failure):
          AppToast.error(failure.message);
      }
    } on Object catch (e) {
      AppToast.error('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final session = _session;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Không tìm thấy')),
        body: const Center(child: Text('Buổi học không tồn tại.')),
      );
    }

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: session.messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_sending && index == session.messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ChatBubble(
                          text: 'Đang suy nghĩ…',
                          isUser: false,
                        ),
                      ),
                    );
                  }
                  final m = session.messages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Align(
                      alignment: m.role == MathChatRole.user
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: ChatBubble(
                        text: m.content,
                        isUser: m.role == MathChatRole.user,
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(
                            hintText: 'Hỏi bài Toán, ghi đề bài…',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: _sending ? null : _send,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
