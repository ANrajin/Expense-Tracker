import 'package:hive/hive.dart';

import '../models/asset.dart';

/// Note that [getAll] does *not* sort, unlike `CategoryRepository.getAll`.
/// `Box.values` iterates by internal key order rather than insertion order, so
/// wealth listings are ordered by the pure `sortedAssets`/`sortedInvestments`/
/// `buildLoanSummaries` functions instead — that keeps the ordering rules
/// testable without a Hive box.
class AssetRepository {
  AssetRepository(this._box);

  final Box<Asset> _box;

  static const boxName = 'assets';

  List<Asset> getAll() => _box.values.toList();

  Future<void> add(Asset asset) => _box.put(asset.id, asset);

  Future<void> update(Asset asset) => asset.save();

  Future<void> delete(String id) => _box.delete(id);
}
