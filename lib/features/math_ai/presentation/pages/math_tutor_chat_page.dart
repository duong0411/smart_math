import 'dart:convert';
import 'dart:typed_data';

import 'package:eduself_study_app/core/ai/gemini_client.dart';
import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/shared/utils/extract_study_document_text.dart';
import 'package:eduself_study_app/shared/utils/image_picker_errors.dart';
import 'package:eduself_study_app/shared/utils/pick_study_document.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class MathTutorChatPage extends ConsumerStatefulWidget {
  const MathTutorChatPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<MathTutorChatPage> createState() => _MathTutorChatPageState();
}

class _MathTutorChatPageState extends ConsumerState<MathTutorChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  MathTutorSession? _session;
  var _loading = true;
  var _sending = false;
  Uint8List? _pendingImageBytes;
  String? _pendingImageMime;
  String? _pendingDocumentName;
  String? _pendingDocumentText;

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
  }

  Future<void> _showAttachMenu() async {
    if (_sending) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Chụp ảnh'),
                subtitle: const Text('Chụp đề bài bằng camera'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn ảnh có sẵn'),
                subtitle: const Text('Lấy từ thư viện ảnh'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('PDF / Word'),
                subtitle: const Text('Đọc chữ trong tệp rồi hỏi AI'),
                onTap: () => Navigator.pop(ctx, 'document'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == 'camera') {
      await _pickImage(ImageSource.camera);
    } else if (choice == 'gallery') {
      await _pickImage(ImageSource.gallery);
    } else if (choice == 'document') {
      await _pickDocument();
    }
  }

  Future<void> _pickDocument() async {
    final picked = await pickMathAiDocument(context);
    if (picked == null) return;
    try {
      final extracted = await extractStudyDocumentText(
        filename: picked.name,
        bytes: picked.bytes,
      );
      if (!mounted) return;
      setState(() {
        _pendingDocumentName = extracted.filename;
        _pendingDocumentText = extracted.text;
        // Prefer one attachment type at a time for clearer prompts.
        _pendingImageBytes = null;
        _pendingImageMime = null;
      });
      if (extracted.truncated) {
        AppToast.info('Tệp khá dài — đã lấy phần đầu để gửi AI.');
      }
    } on Object catch (e) {
      AppToast.error('$e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        AppToast.error('Không đọc được ảnh.');
        return;
      }
      if (bytes.length > 8 * 1024 * 1024) {
        AppToast.error('Ảnh quá lớn (tối đa ~8MB sau nén).');
        return;
      }
      final lower = file.name.toLowerCase();
      final mime = lower.endsWith('.png')
          ? 'image/png'
          : lower.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      if (!mounted) return;
      setState(() {
        _pendingImageBytes = bytes;
        _pendingImageMime = mime;
        _pendingDocumentName = null;
        _pendingDocumentText = null;
      });
    } on Object catch (e) {
      AppToast.error(imagePickerErrorMessage(e));
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final hasImage = _pendingImageBytes != null;
    final hasDocument = _pendingDocumentText != null &&
        _pendingDocumentText!.trim().isNotEmpty;
    if ((text.isEmpty && !hasImage && !hasDocument) ||
        _sending ||
        _session == null) {
      return;
    }

    final imageBytes = _pendingImageBytes;
    final imageMime = _pendingImageMime ?? 'image/jpeg';
    final documentName = _pendingDocumentName;
    final documentText = _pendingDocumentText;
    final displayContent = text.isNotEmpty
        ? text
        : (hasDocument
            ? '📄 ${documentName ?? 'Tài liệu'}'
            : (hasImage ? '📷 Ảnh bài tập' : ''));

    setState(() {
      _sending = true;
      _pendingImageBytes = null;
      _pendingImageMime = null;
      _pendingDocumentName = null;
      _pendingDocumentText = null;
    });
    _controller.clear();

    final store = ref.read(mathLocalStoreProvider);
    final now = DateTime.now().toUtc();
    final userMsg = MathChatMessage(
      id: '${now.millisecondsSinceEpoch}-u',
      role: MathChatRole.user,
      content: displayContent,
      at: now,
      imageBase64: imageBytes != null ? base64Encode(imageBytes) : null,
      imageMimeType: imageBytes != null ? imageMime : null,
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
            text: m.hasImage && m.content.trim().isEmpty
                ? '[Học sinh đã gửi ảnh bài tập]'
                : (m.hasImage
                    ? '${m.content}\n[Kèm ảnh bài tập]'
                    : m.content),
          ),
      ];

      final promptMessage = text.isNotEmpty
          ? text
          : (hasDocument
              ? 'Em gửi tệp "${documentName ?? 'tài liệu'}". Thầy xem giúp em bài toán trong tệp và hướng dẫn giải từng bước nhé.'
              : (hasImage
                  ? 'Em gửi ảnh này. Thầy xem có phải đề bài hoặc bài tập Toán không và hướng dẫn giải giúp em với ạ.'
                  : ''));

      final result = await askMathAi(
        ref,
        userMessage: promptMessage,
        history: history,
        gradeLevel: _session?.gradeLevel,
        image: imageBytes == null
            ? null
            : GeminiImage(
                base64: base64Encode(imageBytes),
                mimeType: imageMime,
              ),
        documentText: documentText,
        documentName: documentName,
        extraSystemContext:
            'Gia sư STEM Toán: Chỉ hỗ trợ môn Toán và ứng dụng STEM. '
            'Nếu học sinh hỏi nội dung không liên quan hoặc gửi ảnh không liên quan đến Toán (ảnh người, phong cảnh, đồ vật, thú cưng, meme, ảnh rác...), '
            'hãy từ chối lịch sự, ngắn gọn và nhắc học sinh gửi bài tập Toán. '
            'Tuyệt đối không trả lời lan man hoặc tiếp chuyện ngoài lề.',
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
          final attachNote = hasDocument
              ? 'Chat kèm tệp · ${session.title}'
              : (hasImage
                  ? 'Chat kèm ảnh · ${session.title}'
                  : 'Buổi chat · ${session.title}');
          await store.addEvent(
            MathStudyEvent(
              id: reply.id,
              type: MathStudyEventType.tutor,
              topic: session.topic ?? 'Gia sư Toán',
              detail: attachNote,
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
        _scroll.position.maxScrollExtent + 120,
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
            session.gradeLevel != null
                ? '${session.title} · Lớp ${session.gradeLevel}'
                : session.title,
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
                  final isUser = m.role == MathChatRole.user;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                        ),
                        child: Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (m.hasImage)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    base64Decode(m.imageBase64!),
                                    fit: BoxFit.cover,
                                    width: 220,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 160,
                                      height: 100,
                                      color: Colors.black26,
                                      alignment: Alignment.center,
                                      child: const Text('Không hiện ảnh'),
                                    ),
                                  ),
                                ),
                              ),
                            if (m.content.trim().isNotEmpty)
                              ChatBubble(
                                text: m.content,
                                isUser: isUser,
                              ),
                          ],
                        ),
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
                  padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_pendingImageBytes != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _pendingImageBytes!,
                                  height: 96,
                                  width: 96,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Material(
                                  color: Colors.black54,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => setState(() {
                                      _pendingImageBytes = null;
                                      _pendingImageMime = null;
                                    }),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_pendingDocumentText != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Material(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.description_outlined),
                              title: Text(
                                _pendingDocumentName ?? 'Tài liệu',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: const Text('Sẽ gửi nội dung chữ cho AI'),
                              trailing: IconButton(
                                tooltip: 'Bỏ tệp',
                                onPressed: () => setState(() {
                                  _pendingDocumentName = null;
                                  _pendingDocumentText = null;
                                }),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Ảnh / PDF / Word',
                            onPressed: _sending ? null : _showAttachMenu,
                            icon: const Icon(Icons.attach_file_rounded),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 5,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: const InputDecoration(
                                hintText: 'Gõ câu hỏi, gửi ảnh hoặc PDF/Word…',
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
