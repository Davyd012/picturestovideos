import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picturestovideos/core/media/data/saved_image_asset_repository.dart';
import 'package:picturestovideos/core/media/domain/saved_image_asset.dart';
import 'package:shared_preferences/shared_preferences.dart';

final savedImageAssetRepositoryProvider = Provider<SavedImageAssetRepository>(
  (ref) => const SharedPreferencesSavedImageAssetRepository(),
);

class SharedPreferencesSavedImageAssetRepository
    implements SavedImageAssetRepository {
  const SharedPreferencesSavedImageAssetRepository();

  static const _storageKey = 'saved_image_assets';

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  @override
  Future<List<SavedImageAsset>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final jsonString = preferences.getString(_storageKey);
    if (jsonString == null) {
      return const [];
    }

    final decoded = jsonDecode(jsonString) as Map<String, Object?>;
    final assetsJson = decoded['assets'];
    if (assetsJson is! List<Object?>) {
      return const [];
    }

    final assets = [
      for (final assetJson in assetsJson)
        if (assetJson is Map<String, Object?>) _deserialize(assetJson),
    ]..sort((a, b) => b.importedOn.compareTo(a.importedOn));
    return List.unmodifiable(assets);
  }

  @override
  Future<void> upsertAll(List<SavedImageAsset> assets) async {
    if (assets.isEmpty) {
      return;
    }

    final currentAssets = await loadAll();
    final nextById = {
      for (final asset in currentAssets) asset.id: asset,
      for (final asset in assets) asset.id: asset,
    };
    final nextAssets = nextById.values.toList()
      ..sort((a, b) => b.importedOn.compareTo(a.importedOn));

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode({
        'version': 1,
        'assets': [for (final asset in nextAssets) _serialize(asset)],
      }),
    );
  }

  @override
  Future<void> removeAll(Set<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final nextAssets = [
      for (final asset in await loadAll())
        if (!ids.contains(asset.id)) asset,
    ];
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode({
        'version': 2,
        'assets': [for (final asset in nextAssets) _serialize(asset)],
      }),
    );
  }

  Map<String, Object?> _serialize(SavedImageAsset asset) {
    return {
      'id': asset.id,
      'fileName': asset.fileName,
      'sourcePath': asset.sourcePath,
      'byteLength': asset.byteLength,
      'importedOn': asset.importedOn.toIso8601String(),
      'fileModifiedOn': asset.fileModifiedOn?.toIso8601String(),
      'importOrder': asset.importOrder,
    };
  }

  SavedImageAsset _deserialize(Map<String, Object?> json) {
    return SavedImageAsset(
      id: json['id']! as String,
      fileName: json['fileName']! as String,
      sourcePath: json['sourcePath']! as String,
      byteLength: json['byteLength'] as int? ?? 0,
      importedOn: DateTime.parse(json['importedOn']! as String),
      fileModifiedOn: switch (json['fileModifiedOn']) {
        final String value => DateTime.tryParse(value),
        _ => null,
      },
      importOrder: json['importOrder'] as int? ?? 0,
    );
  }
}
