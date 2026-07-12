import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/network_providers.dart';
import 'package:eduself_study_app/features/library/domain/entities/library_document.dart';
import 'package:eduself_study_app/features/library/domain/repositories/library_repository.dart';
import 'package:eduself_study_app/features/library/infrastructure/repositories/library_repository_impl.dart';
import 'package:eduself_study_app/features/media/domain/entities/media_asset.dart';
import 'package:eduself_study_app/features/media/presentation/providers/media_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepositoryImpl(api: ref.watch(apiClientProvider));
});

final libraryDocumentsProvider =
    FutureProvider.autoDispose<List<LibraryDocument>>((ref) async {
  final result = await ref.watch(libraryRepositoryProvider).listDocuments();
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

final libraryDocumentProvider =
    FutureProvider.autoDispose.family<LibraryDocument, int>((ref, id) async {
  final result = await ref.watch(libraryRepositoryProvider).getDocument(id);
  return switch (result) {
    Success(:final value) => value,
    FailureResult(:final failure) => throw Exception(failure.message),
  };
});

class UploadLibraryDocumentInput {
  const UploadLibraryDocumentInput({
    required this.bytes,
    required this.filename,
    required this.contentType,
    required this.kind,
    String? title,
    this.subject,
  }) : title = title ?? filename;

  final List<int> bytes;
  final String filename;
  final String contentType;
  final String kind;
  final String title;
  final String? subject;
}

final uploadLibraryDocumentProvider =
    Provider<Future<Result<LibraryDocument>> Function(UploadLibraryDocumentInput)>(
  (ref) {
    return (input) async {
      final mediaResult = await ref.read(uploadMediaProvider)(
        UploadMediaInput(
          bytes: input.bytes,
          filename: input.filename,
          contentType: input.contentType,
          kind: input.kind,
        ),
      );
      switch (mediaResult) {
        case FailureResult(:final failure):
          return FailureResult(failure);
        case Success(:final value):
          return ref.read(libraryRepositoryProvider).createDocument(
                title: input.title,
                mediaId: value.id,
                subject: input.subject,
              );
      }
    };
  },
);
