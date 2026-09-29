import 'dart:convert';
import 'dart:typed_data';

import 'package:eduself_study_app/core/ai/gemini_client.dart';
import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/shared/utils/image_picker_errors.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:image_picker/image_picker.dart';

class MathPracticePage extends ConsumerStatefulWidget {
  const MathPracticePage({super.key});

  @override
  ConsumerState<MathPracticePage> createState() => _MathPracticePageState();
}

class _MathPracticePageState extends ConsumerState<MathPracticePage> {
  final _answerController = TextEditingController();
  final _topicController = TextEditingController();
  final _picker = ImagePicker();

  String? _question;
  String? _topic;
  String? _feedback;
  bool? _correct;
  var _busy = false;
  Uint8List? _answerImageBytes;
  String? _answerImageMime;

  @override
  void dispose() {
    _answerController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final hasKey =
        (ref.read(geminiApiKeyProvider).valueOrNull ?? '').trim().isNotEmpty;
    if (!hasKey) {
      AppToast.error('Cần Gemini API key.');
      if (mounted) context.push('/settings');
      return;
    }

    setState(() {
      _busy = true;
      _feedback = null;
      _correct = null;
      _question = null;
      _answerImageBytes = null;
      _answerImageMime = null;
    });
    _answerController.clear();

    final topic = _topicController.text.trim().isEmpty
        ? 'theo chương trình lớp hiện tại'
        : _topicController.text.trim();

    final result = await askMathAi(
      ref,
      userMessage: '''
Hãy tạo ĐÚNG 1 bài tập Toán (chưa có đáp án trong phần hiển thị cho học sinh) phù hợp lớp hiện tại.
Chủ đề: $topic

Yêu cầu chất lượng:
- Đề phải có nghiệm / đáp án xác định, không mâu thuẫn, vừa sức lớp.
- Nêu rõ đơn vị / điều kiện nếu cần.
- Dùng LaTeX \$...\$ hoặc \$\$...\$\$ cho biểu thức.

Trả lời CHỈ bằng JSON thuần (không markdown, không code fence):
{"topic":"...","question":"..."}
''',
      extraSystemContext:
          'Chế độ luyện tập: chỉ tạo 1 bài đúng kiến thức, phù hợp lớp, vừa sức. Ưu tiên độ chính xác đề bài.',
    );

    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case Success(:final value):
        final parsed = _parseJson(value);
        if (parsed == null) {
          AppToast.error('AI trả về định dạng không hợp lệ. Thử lại.');
          return;
        }
        setState(() {
          _topic = parsed['topic'] as String? ?? topic;
          _question = parsed['question'] as String? ?? value;
        });
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  Future<void> _showAttachMenu() async {
    if (_busy) return;
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
                title: const Text('Chụp ảnh bài làm'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn ảnh có sẵn'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == 'camera') {
      await _pickAnswerImage(ImageSource.camera);
    } else if (choice == 'gallery') {
      await _pickAnswerImage(ImageSource.gallery);
    }
  }

  Future<void> _pickAnswerImage(ImageSource source) async {
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
        _answerImageBytes = bytes;
        _answerImageMime = mime;
        _feedback = null;
        _correct = null;
      });
    } on Object catch (e) {
      AppToast.error(imagePickerErrorMessage(e));
    }
  }

  Future<void> _submit() async {
    final answer = _answerController.text.trim();
    final hasImage = _answerImageBytes != null;
    if ((answer.isEmpty && !hasImage) || _question == null || _busy) {
      AppToast.info('Em gõ bài làm hoặc gửi ảnh bài làm trước khi nộp.');
      return;
    }

    setState(() => _busy = true);

    final answerLabel = answer.isEmpty
        ? '(Bài làm gửi bằng ảnh)'
        : answer;
    final imageNote = hasImage
        ? '\n(Học sinh kèm ảnh bài làm — hãy đọc chữ/phép tính trên ảnh.)'
        : '';

    final result = await askMathAi(
      ref,
      userMessage: '''
Chấm bài luyện tập Toán — ưu tiên độ chính xác toán học.

Đề: $_question
Bài làm học sinh (text): $answerLabel$imageNote

Quy trình chấm:
1. Tự giải đúng đề (không hiện hết cho học sinh nếu sai).
2. So sánh với bài làm (text và/hoặc ảnh); đọc kỹ phép tính trên ảnh nếu có.
3. correct=true chỉ khi kết quả cuối cùng đúng (chấp nhận dạng tương đương hợp lệ).
4. Nếu sai: chỉ ra bước/lỗi cụ thể + gợi ý bước tiếp theo — chưa đưa đáp án đầy đủ trừ khi gần đúng.
5. Dùng LaTeX trong feedback khi cần.

Trả lời CHỈ bằng JSON thuần (không markdown, không code fence):
{"correct":true/false,"feedback":"..."}
''',
      image: hasImage
          ? GeminiImage(
              base64: base64Encode(_answerImageBytes!),
              mimeType: _answerImageMime ?? 'image/jpeg',
            )
          : null,
      extraSystemContext:
          'Chế độ chấm luyện tập: tự giải để đối chiếu trước khi kết luận đúng/sai. Không bịa.',
    );

    if (!mounted) return;

    switch (result) {
      case Success(:final value):
        final parsed = _parseJson(value);
        final correct = parsed?['correct'] == true;
        final feedback = (parsed?['feedback'] as String?) ?? value;
        final attempt = MathPracticeAttempt(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          topic: _topic ?? 'Toán',
          question: _question!,
          studentAnswer: hasImage && answer.isEmpty
              ? '📷 Ảnh bài làm'
              : (hasImage ? '$answer\n📷 (kèm ảnh)' : answer),
          feedback: feedback,
          correct: correct,
          at: DateTime.now().toUtc(),
        );
        await ref.read(mathLocalStoreProvider).addAttempt(attempt);
        ref.invalidate(mathAttemptsProvider);
        ref.invalidate(mathEventsProvider);
        setState(() {
          _busy = false;
          _correct = correct;
          _feedback = feedback;
        });
      case FailureResult(:final failure):
        setState(() => _busy = false);
        AppToast.error(failure.message);
    }
  }

  Map<String, dynamic>? _parseJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceAll(RegExp(r'^```(?:json)?\s*'), '');
      text = text.replaceAll(RegExp(r'\s*```$'), '');
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      if (decoded is Map<String, dynamic>) return decoded;
    } on Object {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Luyện tập Toán'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Chủ đề (tuỳ chọn)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _topicController,
                    decoration: const InputDecoration(
                      hintText: 'VD: phương trình bậc nhất, phân số…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _generate,
                    icon: _busy && _question == null
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _question == null ? 'Tạo bài mới' : 'Đổi bài khác',
                    ),
                  ),
                ],
              ),
            ),
            if (_question != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_topic != null)
                      Text(
                        _topic!,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    const SizedBox(height: 8),
                    GptMarkdown(
                      _question!,
                      useDollarSignsForLatex: true,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bài làm của em',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gõ text và/hoặc gửi ảnh bài làm (chụp / chọn từ thư viện).',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _answerController,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Gõ lời giải, đáp án…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_answerImageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _answerImageBytes!,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Material(
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: _busy
                                      ? null
                                      : () => setState(() {
                                            _answerImageBytes = null;
                                            _answerImageMime = null;
                                          }),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _showAttachMenu,
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: Text(
                              _answerImageBytes == null
                                  ? 'Ảnh bài làm'
                                  : 'Đổi ảnh',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: _busy ? null : _submit,
                            icon: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: const Text('Nộp bài'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (_feedback != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _correct == true
                              ? Icons.verified_rounded
                              : Icons.lightbulb_outline,
                          color: _correct == true
                              ? scheme.primary
                              : scheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _correct == true ? 'Đúng rồi!' : 'Cần xem lại',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GptMarkdown(
                      _feedback!,
                      useDollarSignsForLatex: true,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
