import 'dart:typed_data';

import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/auth/presentation/providers/auth_session_provider.dart';
import 'package:eduself_study_app/features/library/domain/entities/library_document.dart';
import 'package:eduself_study_app/features/library/presentation/providers/library_providers.dart';
import 'package:eduself_study_app/features/media/presentation/providers/media_providers.dart';
import 'package:eduself_study_app/features/tutoring/presentation/providers/tutoring_providers.dart';
import 'package:eduself_study_app/shared/widgets/app_drawer.dart';
import 'package:eduself_study_app/shared/widgets/app_toast.dart';
import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

class LibraryReaderPage extends ConsumerStatefulWidget {
  const LibraryReaderPage({super.key, required this.documentId});

  final int documentId;

  @override
  ConsumerState<LibraryReaderPage> createState() => _LibraryReaderPageState();
}

class _LibraryReaderPageState extends ConsumerState<LibraryReaderPage> {
  var _asking = false;

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
    setState(() => _asking = true);
    final sessionResult = await ref.read(createTutoringSessionProvider)(
      userId: user.id,
      title: 'Hỏi về: ${doc.title}',
    );
    if (sessionResult is FailureResult) {
      if (mounted) setState(() => _asking = false);
      AppToast.error(sessionResult.failureOrNull!.message);
      return;
    }
    final session = sessionResult.valueOrNull!;
    final send = await ref.read(sendTutoringMessageProvider)(
      sessionId: session.id,
      content:
          'Em đính kèm tài liệu "${doc.title}". Thầy đọc giúp em và giải thích những phần quan trọng nhé.',
      mediaIds: [mediaId],
    );
    if (!mounted) return;
    setState(() => _asking = false);
    if (send.isFailure) {
      AppToast.error(send.failureOrNull!.message);
      context.go('/tutoring/${session.id}');
      return;
    }
    AppToast.success('Đã gửi tài liệu cho thầy AI');
    context.go('/tutoring/${session.id}');
  }

  @override
  Widget build(BuildContext context) {
    final docAsync = ref.watch(libraryDocumentProvider(widget.documentId));

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(docAsync.valueOrNull?.title ?? 'Tài liệu'),
          actions: [
            if (docAsync.valueOrNull?.mediaId != null)
              IconButton(
                tooltip: 'Hỏi Gia sư AI',
                onPressed: _asking
                    ? null
                    : () => _askAi(docAsync.valueOrNull!),
                icon: _asking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.smart_toy_outlined),
              ),
          ],
        ),
        drawer: const AppDrawer(),
        body: docAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              GlassCard(
                child: Column(
                  children: [
                    Text('$error'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(
                        libraryDocumentProvider(widget.documentId),
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (doc) {
            if (doc.mediaId != null) {
              return _MediaContentViewer(mediaId: doc.mediaId!);
            }
            if (doc.sourceUrl != null && doc.sourceUrl!.isNotEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          doc.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (doc.description != null) ...[
                          const SizedBox(height: 8),
                          Text(doc.description!),
                        ],
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () async {
                            final uri = Uri.tryParse(doc.sourceUrl!);
                            if (uri == null) return;
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Mở liên kết'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const Center(
              child: Text('Tài liệu chưa có nội dung để đọc.'),
            );
          },
        ),
      ),
    );
  }
}

class _MediaContentViewer extends ConsumerWidget {
  const _MediaContentViewer({required this.mediaId});

  final int mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Result<List<int>>>(
      future: ref.read(getMediaContentBytesProvider)(mediaId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final result = snapshot.data!;
        return switch (result) {
          FailureResult(:final failure) => Center(child: Text(failure.message)),
          Success(:final value) =>
            _BytesViewer(bytes: Uint8List.fromList(value)),
        };
      },
    );
  }
}

class _BytesViewer extends StatelessWidget {
  const _BytesViewer({required this.bytes});

  final Uint8List bytes;

  bool get _looksPdf =>
      bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;

  bool get _looksImage {
    if (bytes.length < 3) return false;
    if (bytes[0] == 0xff && bytes[1] == 0xd8) return true;
    if (bytes[0] == 0x89 && bytes[1] == 0x50) return true;
    if (bytes[0] == 0x47 && bytes[1] == 0x49) return true;
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_looksPdf) {
      return PdfViewer.data(
        bytes,
        sourceName: 'library-$hashCode',
      );
    }
    if (_looksImage) {
      return InteractiveViewer(
        child: Center(
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chưa xem được trong app',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Word, Excel và một số định dạng khác chưa mở trực tiếp. '
                'Em vẫn có thể hỏi Gia sư AI về tài liệu này.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Dung lượng: ${(bytes.length / 1024).toStringAsFixed(1)} KB',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
