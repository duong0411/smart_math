import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/library/domain/entities/library_document.dart';
import 'package:eduself_study_app/features/library/domain/repositories/library_repository.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<Result<List<LibraryDocument>>> listDocuments({
    String scope = 'mine',
  }) async {
    final result = await _api.get('/library?scope=$scope');
    return switch (result) {
      Success(:final value) => _parseList(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<LibraryDocument>> getDocument(int id) async {
    final result = await _api.get('/library/$id');
    return switch (result) {
      Success(:final value) => _parseOne(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<LibraryDocument>> createDocument({
    required String title,
    required int mediaId,
    String? description,
    String? subject,
    int? gradeLevel,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'mediaId': mediaId,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      if (gradeLevel != null) 'gradeLevel': gradeLevel,
    };
    final result = await _api.post('/library', body: body);
    return switch (result) {
      Success(:final value) => _parseOne(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<void>> deleteDocument(int id) async {
    final result = await _api.delete('/library/$id');
    return switch (result) {
      Success() => const Success(null),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  Result<List<LibraryDocument>> _parseList(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! List) {
      return const FailureResult(ApiFailure('Invalid library response.'));
    }
    return Success([
      for (final item in data)
        if (item is Map<String, dynamic>) LibraryDocument.fromJson(item),
    ]);
  }

  Result<LibraryDocument> _parseOne(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid library response.'));
    }
    return Success(LibraryDocument.fromJson(data));
  }
}
