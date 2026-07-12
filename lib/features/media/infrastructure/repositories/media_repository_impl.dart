import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/core/network/api_client.dart';
import 'package:eduself_study_app/features/media/domain/entities/media_asset.dart';
import 'package:eduself_study_app/features/media/domain/repositories/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl({required ApiClient api}) : _api = api;

  final ApiClient _api;

  @override
  Future<Result<MediaAsset>> upload(UploadMediaInput input) async {
    final create = await _api.post(
      '/media',
      body: {
        'kind': input.kind,
        'contentType': input.contentType,
        'filename': input.filename,
        'sizeBytes': input.bytes.length,
      },
    );

    final created = switch (create) {
      Success(:final value) => _parseAsset(value),
      FailureResult(:final failure) => FailureResult<MediaAsset>(failure),
    };
    if (created is FailureResult<MediaAsset>) return created;

    final asset = created.valueOrNull!;
    final uploadPath = asset.uploadPath ?? '/media/${asset.id}/content';
    final uploaded = await _api.putBytes(
      uploadPath,
      bytes: input.bytes,
      contentType: input.contentType,
      timeout: const Duration(seconds: 90),
    );

    return switch (uploaded) {
      Success(:final value) => _parseAsset(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<MediaAsset>> getMedia(int mediaId) async {
    final result = await _api.get('/media/$mediaId');
    return switch (result) {
      Success(:final value) => _parseAsset(value),
      FailureResult(:final failure) => FailureResult(failure),
    };
  }

  @override
  Future<Result<List<int>>> getContentBytes(int mediaId) {
    return _api.getBytes('/media/$mediaId/content');
  }

  Result<MediaAsset> _parseAsset(Map<String, dynamic> envelope) {
    final data = envelope['data'];
    if (data is! Map<String, dynamic>) {
      return const FailureResult(ApiFailure('Invalid media response.'));
    }
    return Success(MediaAsset.fromJson(data));
  }
}
