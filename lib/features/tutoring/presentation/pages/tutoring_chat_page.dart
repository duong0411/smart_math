import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/library/domain/document_file_types.dart';
import 'package:eduself_study_app/features/library/domain/entities/library_document.dart';
import 'package:eduself_study_app/features/library/presentation/providers/library_providers.dart';
import 'package:eduself_study_app/features/media/domain/entities/media_asset.dart';
import 'package:eduself_study_app/features/media/presentation/providers/media_providers.dart';
import 'package:eduself_study_app/features/tutoring/domain/entities/chat_message.dart';
import 'package:eduself_study_app/features/tutoring/presentation/providers/tutoring_chat_provider.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:eduself_study_app/shared/utils/image_picker_errors.dart';
import 'package:eduself_study_app/shared/utils/pick_study_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class TutoringChatPage extends ConsumerStatefulWidget {
  const TutoringChatPage({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<TutoringChatPage> createState() => _TutoringChatPageState();
}

class _TutoringChatPageState extends ConsumerState<TutoringChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  var _sending = false;
  int? _pendingMediaId;
  String? _pendingMediaLabel;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showAttachMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Ảnh từ thư viện'),
                onTap: () => Navigator.pop(ctx, 'image'),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_rounded),
                title: const Text('Tệp tài liệu'),
                subtitle: const Text('PDF, Word, Excel, ảnh…'),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_rounded),
                title: const Text('Từ mục Tài liệu'),
                onTap: () => Navigator.pop(ctx, 'library'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == 'image') await _attachImage();
    if (choice == 'file') await _attachFile();
    if (choice == 'library') await _attachFromLibrary();
  }

  Future<void> _attachImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (file == null) return;
      setState(() => _sending = true);
      final bytes = await file.readAsBytes();
      final lower = file.name.toLowerCase();
      final contentType = lower.endsWith('.png')
          ? 'image/png'
          : lower.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      await _uploadPending(
        bytes: bytes,
        filename: file.name,
        contentType: contentType,
        kind: 'image',
        label: 'Ảnh ${file.name}',
      );
    } on Object catch (e) {
      if (mounted) setState(() => _sending = false);
      AppToast.error(imagePickerErrorMessage(e));
    }
  }

  Future<void> _attachFile() async {
    final picked = await pickStudyDocument(context);
    if (picked == null) return;
    final bytes = picked.bytes;
    if (bytes.isEmpty) {
      AppToast.error('Không đọc được tệp.');
      return;
    }
    if (bytes.length > 25 * 1024 * 1024) {
      AppToast.error('Tệp tối đa 25MB.');
      return;
    }
    final typed = mediaTypeForFilename(picked.name);
    setState(() => _sending = true);
    await _uploadPending(
      bytes: bytes,
      filename: picked.name,
      contentType: typed.contentType,
      kind: typed.kind,
      label: picked.name,
    );
  }

  Future<void> _attachFromLibrary() async {
    final docs = await ref.read(libraryDocumentsProvider.future);
    if (!mounted) return;
    if (docs.isEmpty) {
      AppToast.error('Chưa có tài liệu. Em vào mục Tài liệu để tải lên trước.');
      return;
    }
    final selected = await showModalBottomSheet<LibraryDocument>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.55,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            children: [
              for (final doc in docs)
                ListTile(
                  leading: Icon(iconForDocumentTitle(doc.title)),
                  title: Text(doc.title),
                  subtitle: Text(formatLabelForDocumentTitle(doc.title)),
                  enabled: doc.mediaId != null,
                  onTap: doc.mediaId == null
                      ? null
                      : () => Navigator.pop(ctx, doc),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected?.mediaId == null) return;
    setState(() {
      _pendingMediaId = selected!.mediaId;
      _pendingMediaLabel = selected.title;
    });
    AppToast.success('Đã đính kèm tài liệu');
  }

  Future<void> _uploadPending({
    required List<int> bytes,
    required String filename,
    required String contentType,
    required String kind,
    required String label,
  }) async {
    final upload = await ref.read(uploadMediaProvider)(
      UploadMediaInput(
        bytes: bytes,
        filename: filename,
        contentType: contentType,
        kind: kind,
      ),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    switch (upload) {
      case Success(:final value):
        setState(() {
          _pendingMediaId = value.id;
          _pendingMediaLabel = label;
        });
        AppToast.success('Đã đính kèm tệp');
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final mediaId = _pendingMediaId;
    if ((text.isEmpty && mediaId == null) || _sending) return;

    setState(() => _sending = true);
    _controller.clear();
    final attached = mediaId;
    final label = _pendingMediaLabel;
    setState(() {
      _pendingMediaId = null;
      _pendingMediaLabel = null;
    });

    final defaultPrompt = label == null
        ? 'Em gửi tài liệu này. Thầy giúp em từng bước nhé.'
        : 'Em gửi tài liệu "$label". Thầy đọc giúp em và giải thích từng bước nhé.';

    final error = await ref
        .read(tutoringChatProvider(widget.sessionId).notifier)
        .send(
          text.isEmpty ? defaultPrompt : text,
          mediaIds: attached == null ? null : [attached],
        );
    if (!mounted) return;
    setState(() => _sending = false);

    if (error != null) {
      AppToast.error(error);
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _confirmDelete(ChatMessage message) async {
    if (message.id <= 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message'),
        content: const Text('Remove this message from the chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(tutoringChatProvider(widget.sessionId).notifier)
        .deleteMessage(message.id);
    if (error != null) {
      AppToast.error(error);
    } else {
      AppToast.success('Message deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(tutoringChatProvider(widget.sessionId));
    final scheme = Theme.of(context).colorScheme;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('EduSelf AI Pro'),
        ),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            Expanded(
              child: chat.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: GlassCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.forum_rounded,
                                size: 40,
                                color: scheme.primary,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Bắt đầu buổi học',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Xin chào! Em tên là gì, đang học lớp mấy, '
                                'và hôm nay muốn học môn gì?',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.45,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_sending && index == messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Đang suy nghĩ…',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      final message = messages[index];
                      final isUser = message.role == ChatRole.user;
                      return Dismissible(
                        key: ValueKey('msg-${message.id}-$index'),
                        direction: message.id > 0
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
                        confirmDismiss: (_) async {
                          await _confirmDelete(message);
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: scheme.onErrorContainer,
                          ),
                        ),
                        child: ChatBubble(
                          text: message.mediaIds.isEmpty
                              ? message.content
                              : '${message.content}\n\n📎 Đã đính kèm ${message.mediaIds.length} tệp',
                          isUser: isUser,
                          onLongPress: message.id > 0
                              ? () => _confirmDelete(message)
                              : null,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('$error')),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_pendingMediaId != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                          child: Row(
                            children: [
                              Icon(Icons.attach_file_rounded,
                                  color: scheme.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _pendingMediaLabel ??
                                      'Đã đính kèm tệp #$_pendingMediaId',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              IconButton(
                                onPressed: _sending
                                    ? null
                                    : () => setState(() {
                                          _pendingMediaId = null;
                                          _pendingMediaLabel = null;
                                        }),
                                icon: const Icon(Icons.close_rounded),
                                tooltip: 'Bỏ đính kèm',
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _sending ? null : _showAttachMenu,
                            tooltip: 'Đính kèm',
                            icon: const Icon(Icons.attach_file_rounded),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: const InputDecoration(
                                hintText: 'Em muốn hỏi gì?',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                          IconButton.filled(
                            onPressed: _sending ? null : _send,
                            tooltip: 'Gửi',
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
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
