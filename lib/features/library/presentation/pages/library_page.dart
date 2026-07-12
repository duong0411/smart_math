import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:eduself_study_app/features/library/domain/document_file_types.dart';
import 'package:eduself_study_app/features/library/domain/entities/library_document.dart';
import 'package:eduself_study_app/features/library/presentation/providers/library_providers.dart';
import 'package:eduself_study_app/features/tutoring/presentation/providers/tutoring_providers.dart';
import 'package:eduself_study_app/shared/utils/pick_study_document.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/dense_list_card.dart';
import 'package:eduself_study_app/shared/widgets/feature_list_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  var _uploading = false;

  Future<void> _upload() async {
    if (_uploading) return;
    final picked = await pickStudyDocument(context);
    if (picked == null) return;
    final bytes = picked.bytes;
    if (bytes.isEmpty) {
      AppToast.error('Không đọc được tệp. Em thử lại nhé.');
      return;
    }
    if (bytes.length > 25 * 1024 * 1024) {
      AppToast.error('Tệp tối đa 25MB.');
      return;
    }

    final filename = picked.name;
    final typed = mediaTypeForFilename(filename);
    setState(() => _uploading = true);
    final result = await ref.read(uploadLibraryDocumentProvider)(
      UploadLibraryDocumentInput(
        bytes: bytes,
        filename: filename,
        contentType: typed.contentType,
        kind: typed.kind,
        title: filename,
      ),
    );
    if (!mounted) return;
    setState(() => _uploading = false);

    switch (result) {
      case Success():
        ref.invalidate(libraryDocumentsProvider);
        AppToast.success('Đã thêm tài liệu');
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  Future<void> _askAi(LibraryDocument doc) async {
    final mediaId = doc.mediaId;
    if (mediaId == null) {
      AppToast.error('Tài liệu này chưa có tệp để hỏi AI.');
      return;
    }
    final user = ref.read(authSessionProvider).valueOrNull;
    if (user == null) {
      AppToast.error('Em đăng nhập lại nhé.');
      return;
    }

    setState(() => _uploading = true);
    final sessionResult = await ref.read(createTutoringSessionProvider)(
      userId: user.id,
      title: 'Hỏi về: ${doc.title}',
    );
    if (sessionResult is FailureResult) {
      if (mounted) setState(() => _uploading = false);
      AppToast.error(sessionResult.failureOrNull!.message);
      return;
    }
    final session = sessionResult.valueOrNull!;
    final send = await ref.read(sendTutoringMessageProvider)(
      sessionId: session.id,
      content:
          'Em đính kèm tài liệu "${doc.title}". Thầy đọc giúp em và giải thích những phần quan trọng, '
          'sau đó hỏi em đã hiểu chưa nhé.',
      mediaIds: [mediaId],
    );
    if (!mounted) return;
    setState(() => _uploading = false);
    if (send.isFailure) {
      AppToast.error(send.failureOrNull!.message);
      context.go('/tutoring/${session.id}');
      return;
    }
    AppToast.success('Đã gửi tài liệu cho thầy AI');
    context.go('/tutoring/${session.id}');
  }

  Future<void> _delete(LibraryDocument doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá tài liệu?'),
        content: Text(doc.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final result =
        await ref.read(libraryRepositoryProvider).deleteDocument(doc.id);
    switch (result) {
      case Success():
        ref.invalidate(libraryDocumentsProvider);
        AppToast.success('Đã xoá tài liệu');
      case FailureResult(:final failure):
        AppToast.error(failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(libraryDocumentsProvider);
    final scheme = Theme.of(context).colorScheme;

    return FeatureListScaffold(
      title: 'Tài liệu',
      listHeader: 'Tài liệu của em',
      value: docs,
      emptyTitle: 'Chưa có tài liệu',
      emptySubtitle:
          'Em tải PDF, Word, Excel, ảnh… rồi hỏi Gia sư AI về nội dung đó.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _upload,
        icon: _uploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file_rounded),
        label: Text(_uploading ? 'Đang tải…' : 'Thêm tài liệu'),
      ),
      onRefresh: () async {
        ref.invalidate(libraryDocumentsProvider);
        await ref.read(libraryDocumentsProvider.future);
      },
      itemBuilder: (context, doc) {
        return DenseListRow(
          title: doc.title,
          subtitle: [
            formatLabelForDocumentTitle(doc.title),
            if (doc.subject != null) doc.subject!,
            'Hỏi AI được',
          ].join(' · '),
          leadingIcon: iconForDocumentTitle(doc.title),
          onTap: () => context.push('/library/${doc.id}'),
          trailing: PopupMenuButton<String>(
            iconSize: 20,
            padding: EdgeInsets.zero,
            onSelected: (v) {
              if (v == 'ask') _askAi(doc);
              if (v == 'delete') _delete(doc);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'ask',
                child: Text('Hỏi Gia sư AI'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Xoá',
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
