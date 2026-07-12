import 'package:eduself_study_app/core/network/network_providers.dart';
import 'package:eduself_study_app/features/media/domain/repositories/media_repository.dart';
import 'package:eduself_study_app/features/media/domain/usecases/media_usecases.dart';
import 'package:eduself_study_app/features/media/infrastructure/repositories/media_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepositoryImpl(api: ref.watch(apiClientProvider));
});

final uploadMediaProvider = Provider<UploadMedia>((ref) {
  return UploadMedia(ref.watch(mediaRepositoryProvider));
});

final getMediaContentBytesProvider = Provider<GetMediaContentBytes>((ref) {
  return GetMediaContentBytes(ref.watch(mediaRepositoryProvider));
});
