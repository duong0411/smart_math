import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/library/domain/entities/library_document.dart';

abstract class LibraryRepository {
  Future<Result<List<LibraryDocument>>> listDocuments({String scope = 'mine'});

  Future<Result<LibraryDocument>> getDocument(int id);

  Future<Result<LibraryDocument>> createDocument({
    required String title,
    required int mediaId,
    String? description,
    String? subject,
    int? gradeLevel,
  });

  Future<Result<void>> deleteDocument(int id);
}
