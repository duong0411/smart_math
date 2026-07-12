import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/media/domain/entities/media_asset.dart';
import 'package:eduself_study_app/features/media/domain/repositories/media_repository.dart';

class UploadMedia {
  const UploadMedia(this._repo);
  final MediaRepository _repo;
  Future<Result<MediaAsset>> call(UploadMediaInput input) => _repo.upload(input);
}

class GetMediaContentBytes {
  const GetMediaContentBytes(this._repo);
  final MediaRepository _repo;
  Future<Result<List<int>>> call(int mediaId) => _repo.getContentBytes(mediaId);
}
