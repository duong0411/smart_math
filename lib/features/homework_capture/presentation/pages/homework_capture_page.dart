import 'dart:typed_data';

import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:eduself_study_app/features/media/domain/entities/media_asset.dart';
import 'package:eduself_study_app/features/media/presentation/providers/media_providers.dart';
import 'package:eduself_study_app/features/tutoring/presentation/providers/tutoring_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:eduself_study_app/shared/utils/image_picker_errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class HomeworkCapturePage extends ConsumerStatefulWidget {
  const HomeworkCapturePage({super.key});

  @override
  ConsumerState<HomeworkCapturePage> createState() =>
      _HomeworkCapturePageState();
}

class _HomeworkCapturePageState extends ConsumerState<HomeworkCapturePage> {
  final _noteController = TextEditingController(
    text: 'Em chụp bài này. Thầy gợi ý từng bước giúp em nhé.',
  );
  final _picker = ImagePicker();

  Uint8List? _previewBytes;
  String? _filename;
  String? _contentType;
  bool _busy = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _previewBytes = bytes;
        _filename = file.name;
        _contentType = _guessContentType(file.name);
      });
    } on Object catch (e) {
      AppToast.error(imagePickerErrorMessage(e));
    }
  }

  String _guessContentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<void> _sendToTutor() async {
    final bytes = _previewBytes;
    if (bytes == null || _busy) return;
    final user = ref.read(authSessionProvider).valueOrNull;
    if (user == null) {
      AppToast.error('Em đăng nhập lại nhé.');
      return;
    }

    setState(() => _busy = true);

    final upload = await ref.read(uploadMediaProvider)(
      UploadMediaInput(
        bytes: bytes,
        filename: _filename ?? 'homework.jpg',
        contentType: _contentType ?? 'image/jpeg',
        kind: 'image',
      ),
    );

    if (upload is FailureResult<MediaAsset>) {
      if (mounted) setState(() => _busy = false);
      AppToast.error(upload.failure.message);
      return;
    }

    final media = upload.valueOrNull!;
    final sessionResult = await ref.read(createTutoringSessionProvider)(
      userId: user.id,
      title: 'Bài tập chụp ảnh',
    );

    if (sessionResult is FailureResult) {
      if (mounted) setState(() => _busy = false);
      AppToast.error(sessionResult.failureOrNull!.message);
      return;
    }

    final session = sessionResult.valueOrNull!;
    final note = _noteController.text.trim().isEmpty
        ? 'Em chụp bài này. Thầy giúp em từng bước nhé.'
        : _noteController.text.trim();

    final send = await ref.read(sendTutoringMessageProvider)(
      sessionId: session.id,
      content: note,
      mediaIds: [media.id],
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (send.isFailure) {
      AppToast.error(send.failureOrNull!.message);
      // Still open the session so the student can retry.
      context.go('/tutoring/${session.id}');
      return;
    }

    AppToast.success('Đã gửi bài cho thầy AI');
    context.go('/tutoring/${session.id}');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Chụp bài tập'),
        ),
        drawer: const AppDrawer(),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Chụp hoặc chọn ảnh bài tập',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thầy AI sẽ xem ảnh và gợi ý từng bước — không làm hộ nếu em chưa cần đáp án đầy đủ.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (_previewBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.memory(
                          _previewBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: scheme.surface.withValues(alpha: 0.4),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_outlined,
                              size: 40, color: scheme.primary),
                          const SizedBox(height: 8),
                          Text(
                            'Chưa có ảnh',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _busy
                              ? null
                              : () => _pick(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_rounded),
                          label: const Text('Chụp'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _pick(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Thư viện'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Lời nhắn cho thầy',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed:
                        _previewBytes == null || _busy ? null : _sendToTutor,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _busy ? 'Đang gửi…' : 'Gửi cho Gia sư AI',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
