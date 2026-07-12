import 'package:eduself_study_app/core/error/result.dart';
import 'package:eduself_study_app/features/media/domain/entities/media_asset.dart';

abstract class MediaRepository {
  Future<Result<MediaAsset>> upload(UploadMediaInput input);
  Future<Result<MediaAsset>> getMedia(int mediaId);
  Future<Result<List<int>>> getContentBytes(int mediaId);
}
