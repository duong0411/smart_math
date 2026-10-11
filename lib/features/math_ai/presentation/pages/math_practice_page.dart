import 'dart:convert';
import 'dart:typed_data';

import 'package:eduself_study_app/core/ai/gemini_client.dart';
import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/math_ai/infrastructure/math_local_store.dart';
import 'package:eduself_study_app/features/math_ai/presentation/providers/math_ai_providers.dart';
import 'package:eduself_study_app/shared/utils/extract_study_document_text.dart';
import 'package:eduself_study_app/shared/utils/image_picker_errors.dart';
import 'package:eduself_study_app/shared/utils/pick_study_document.dart';
import 'package:eduself_study_app/shared/utils/supported_grades.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:eduself_study_app/shared/widgets/grade_level_selector.dart';
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
  int _grade = SupportedGrades.fallback;
  var _gradeSynced = false;
  var _busy = false;
  Uint8List? _answerImageBytes;
  String? _answerImageMime;
  String? _answerDocumentName;
  String? _answerDocumentText;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted || _gradeSynced) return;
      final profile = ref.read(mathProfileProvider).valueOrNull;
      setState(() {
        _grade = SupportedGrades.normalize(profile?.gradeLevel);
        _gradeSynced = true;
      });
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _setGrade(int grade) async {
    setState(() => _grade = grade);
    final profile = ref.read(mathProfileProvider).valueOrNull;
    if (profile != null && profile.gradeLevel != grade) {
      await ref.read(mathProfileProvider.notifier).save(
            profile.copyWith(gradeLevel: grade),
          );
    }
  }

  Future<void> _generate() async {
    final hasKey =
        (ref.read(geminiApiKeyProvider).valueOrNull ?? '').trim().isNotEmpty;
    if (!hasKey) {
      AppToast.error('Cần Gemini API key.');
      if (mounted) context.push('/settings');
      return;
    }

    final grade = _grade;

    setState(() {
      _busy = true;
      _feedback = null;
      _correct = null;
      _question = null;
      _answerImageBytes = null;
      _answerImageMime = null;
      _answerDocumentName = null;
      _answerDocumentText = null;
    });
    _answerController.clear();

    final topic = _topicController.text.trim().isEmpty
        ? 'theo chương trình Toán lớp $grade'
        : _topicController.text.trim();

    final result = await askMathAi(
      ref,
      gradeLevel: grade,
      userMessage: '''
Bạn là trợ lý EduSelf STEM Toán AI dành cho học sinh THCS.
Hãy tạo ĐÚNG 1 bài tập Toán lớp $grade (hoặc bài toán ứng dụng STEM liên quan đến Toán học lớp $grade).
Yêu cầu chủ đề: $topic (Nếu người dùng nhập chủ đề không liên quan môn Toán, hãy tự động bỏ qua và tạo 1 bài toán THCS trọng tâm chuẩn mực).

Yêu cầu chất lượng:
- Đề bài phải chuẩn xác 100%, có nghiệm / đáp số xác định, không mâu thuẫn, vừa sức học sinh lớp $grade.
- Trình bày sư phạm, rõ ràng điều kiện và đơn vị.
- Dùng LaTeX \$...\$ hoặc \$\$...\$\$ cho mọi biểu thức, công thức toán.

Trả lời CHỈ bằng 1 đối tượng JSON duy nhất (không có markdown code fence):
{"topic":"Tên chủ đề Toán","question":"Đề bài toán đầy đủ chuẩn LaTeX"}
''',
      extraSystemContext:
          'Chế độ luyện tập EduSelf STEM Toán AI: Chỉ tạo đề bài môn Toán và ứng dụng STEM Toán lớp $grade. Nghiêm cấm tạo nội dung ngoài lề môn Toán.',
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
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('PDF / Word bài làm'),
                subtitle: const Text('Đọc chữ trong tệp để chấm'),
                onTap: () => Navigator.pop(ctx, 'document'),
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
    } else if (choice == 'document') {
      await _pickAnswerDocument();
    }
  }

  Future<void> _pickAnswerDocument() async {
    final picked = await pickMathAiDocument(context);
    if (picked == null) return;
    try {
      final extracted = await extractStudyDocumentText(
        filename: picked.name,
        bytes: picked.bytes,
      );
      if (!mounted) return;
      setState(() {
        _answerDocumentName = extracted.filename;
        _answerDocumentText = extracted.text;
        _answerImageBytes = null;
        _answerImageMime = null;
        _feedback = null;
        _correct = null;
      });
      if (extracted.truncated) {
        AppToast.info('Tệp khá dài — đã lấy phần đầu để chấm.');
      }
    } on Object catch (e) {
      AppToast.error('$e');
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
        _answerDocumentName = null;
        _answerDocumentText = null;
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
    final hasDocument = _answerDocumentText != null &&
        _answerDocumentText!.trim().isNotEmpty;
    if ((answer.isEmpty && !hasImage && !hasDocument) ||
        _question == null ||
        _busy) {
      AppToast.info(
        'Em gõ bài làm, gửi ảnh hoặc PDF/Word bài làm trước khi nộp.',
      );
      return;
    }

    setState(() => _busy = true);

    final answerLabel = answer.isEmpty
        ? (hasDocument
            ? '(Bài làm gửi bằng tệp ${_answerDocumentName ?? 'tài liệu'})'
            : '(Bài làm gửi bằng ảnh)')
        : answer;


    final result = await askMathAi(
      ref,
      gradeLevel: _grade,
      userMessage: '''
Bạn là giám khảo chấm bài luyện tập môn Toán lớp $_grade (Chương trình GDPT THCS).
Nhiệm vụ: Chấm điểm bài làm của học sinh cho bài toán dưới đây với độ chính xác toán học tuyệt đối.

[ĐỀ BÀI TOÁN LỚP $_grade]:
$_question

[BÀI LÀM CỦA HỌC SINH]:
- Dạng văn bản (text): $answerLabel
- Có ảnh đính kèm: ${hasImage ? "CÓ (Xem ảnh bài làm)" : "KHÔNG"}
- Có tệp đính kèm: ${hasDocument ? "CÓ (${_answerDocumentName ?? 'tệp'})" : "KHÔNG"}

==============================
QUY TRÌNH CHẤM BẮT BUỘC (TUÂN THỦ THEO THỨ TỰ TỪNG BƯỚC):

BƯỚC 1: KIỂM TRA TÍNH HỢP LỆ VÀ LIÊN QUAN (ĐIỀU KIỆN TIÊN QUYẾT):
1. NẾU HỌC SINH GỬI ẢNH:
   - Hãy quan sát kỹ toàn bộ bức ảnh đính kèm.
   - Bức ảnh có chứa chữ viết tay, bài giải, công thức hoặc các bước giải liên quan đến bài toán [$_question] này không?
   - NẾU ẢNH LÀ ẢNH KHÔNG LIÊN QUAN (Ví dụ: ảnh người, ảnh phong cảnh, động vật, đồ vật, meme, ảnh rác, ảnh đen, ảnh mờ không đọc được chữ, hoặc ảnh chụp bài toán KHÁC không liên quan đến đề bài này):
     => BẮT BUỘC ĐẶT: "correct": false
     => "feedback": "Ảnh bạn tải lên không chứa bài giải hoặc không liên quan đến bài toán này. Em hãy chụp rõ bài làm hoặc nhập câu trả lời vào ô để hệ thống chấm điểm nhé!"
     => DỪNG LẠI NGAY, TUYỆT ĐỐI KHÔNG CHẤM ĐÚNG!
2. NẾU HỌC SINH GỬI VĂN BẢN (TEXT):
   - Kiểm tra xem văn bản có chứa câu trả lời / lời giải liên quan bài toán không?
   - NẾU VĂN BẢN LÀ NỘI DUNG NHẢM NHÍ, TÁN GẪU, SPAM, GÕ BỪA (Ví dụ: 'abc', 'hello', 'không biết', 'haha', 'test', câu chữ không liên quan):
     => BẮT BUỘC ĐẶT: "correct": false
     => "feedback": "Câu trả lời không liên quan đến bài toán. Em hãy tính toán cẩn thận và điền đáp số vào nhé!"
     => DỪNG LẠI NGAY, TUYỆT ĐỐI KHÔNG CHẤM ĐÚNG!

BƯỚC 2: TỰ GIẢI BÀI TOÁN ĐỂ CÓ KẾT QUẢ CHUẨN:
- Tự giải bài toán [$_question] từng bước để có đáp số chính xác K_chuẩn và điều kiện nghiệm.

BƯỚC 3: ĐỐI CHIẾU VÀ ĐÁNH GIÁ ĐÚNG / SAI:
- Đọc kỹ kết quả và các bước giải trong bài làm của học sinh (trên ảnh / tệp / text).
- ĐẶT "correct": true CHỈ KHI:
  + Bài làm thực sự giải bài toán này VÀ kết quả cuối cùng chính xác trùng khớp với K_chuẩn (chấp nhận cách viết tương đương hợp lệ: phân số tối giản, số thập phân tương đương).
- ĐẶT "correct": false KHI:
  + Kết quả sai, tính nhầm, sai dấu, thiếu điều kiện, hoặc các bước giải sai logic.
  + Trong "feedback": Chỉ rõ lỗi sai ở bước nào, gợi ý phương pháp giải / công thức cần áp dụng (chưa vội đưa toàn bộ đáp án để học sinh tự làm lại).

ĐỊNH DẠNG ĐẦU RA BẮT BUỘC:
Trả lời CHỈ bằng 1 đối tượng JSON duy nhất (không có markdown fence, không có chữ thừa):
{"correct": true hoặc false, "feedback": "Lời nhận xét chi tiết bằng tiếng Việt, dùng LaTeX \$...\$ cho biểu thức"}
''',
      image: hasImage
          ? GeminiImage(
              base64: base64Encode(_answerImageBytes!),
              mimeType: _answerImageMime ?? 'image/jpeg',
            )
          : null,
      documentText: _answerDocumentText,
      documentName: _answerDocumentName,
      extraSystemContext:
          'Chế độ chấm bài luyện tập STEM Toán: BẮT BUỘC kiểm tra tính liên quan của ảnh/text trước. Nếu ảnh/text không liên quan hoặc sai kết quả, BẮT BUỘC đặt correct = false. Tuyệt đối không chấm đúng cho ảnh hoặc câu trả lời không liên quan.',
    );

    if (!mounted) return;

    switch (result) {
      case Success(:final value):
        final parsed = _parseJson(value);
        final correct = parsed?['correct'] == true;
        final feedback = (parsed?['feedback'] as String?) ?? value;
        final storedAnswer = () {
          if (answer.isNotEmpty) {
            final extras = <String>[
              if (hasImage) '📷 (kèm ảnh)',
              if (hasDocument) '📄 (${_answerDocumentName ?? 'tệp'})',
            ];
            return extras.isEmpty ? answer : '$answer\n${extras.join(' ')}';
          }
          if (hasDocument) return '📄 ${_answerDocumentName ?? 'Tệp bài làm'}';
          if (hasImage) return '📷 Ảnh bài làm';
          return answer;
        }();
        final attempt = MathPracticeAttempt(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          topic: _topic ?? 'Toán',
          question: _question!,
          studentAnswer: storedAnswer,
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
          title: Text('Luyện tập Toán · Lớp $_grade'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            GlassCard(
              child: GradeLevelSelector(
                value: _grade,
                onChanged: (g) {
                  if (_busy) return;
                  _setGrade(g);
                },
              ),
            ),
            const SizedBox(height: 16),
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
                      'Gõ text, gửi ảnh, hoặc đính kèm PDF/Word bài làm.',
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
                    if (_answerDocumentText != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: scheme.secondaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.description_outlined),
                            title: Text(
                              _answerDocumentName ?? 'Tài liệu',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: const Text('Sẽ gửi nội dung chữ để chấm'),
                            trailing: IconButton(
                              tooltip: 'Bỏ tệp',
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                        _answerDocumentName = null;
                                        _answerDocumentText = null;
                                      }),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _showAttachMenu,
                            icon: const Icon(Icons.attach_file_rounded),
                            label: Text(
                              (_answerImageBytes == null &&
                                      _answerDocumentText == null)
                                  ? 'Ảnh / tệp'
                                  : 'Đổi đính kèm',
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
