import 'package:picturestovideos/core/media/domain/saved_image_asset.dart';

abstract interface class SavedImageAssetRepository {
  Future<List<SavedImageAsset>> loadAll();

  Future<void> upsertAll(List<SavedImageAsset> assets);

  Future<void> removeAll(Set<String> ids);

  Future<void> clear();
}
