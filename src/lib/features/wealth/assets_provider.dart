import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/format.dart';
import '../../data/models/asset.dart';
import '../../data/repositories/asset_repository.dart';

/// The asset kinds the form offers, in the order it offers them.
const assetKinds = <String>['cash', 'bank', 'mobile', 'other'];

String assetKindLabel(String kind) {
  return switch (kind) {
    'cash' => 'Cash',
    'bank' => 'Bank',
    'mobile' => 'Mobile wallet',
    _ => 'Other',
  };
}

/// Spec's save requirement for an asset: a non-blank name and an amount of zero
/// or more. Zero is deliberately valid here — a drained wallet is a real
/// balance the user may still want listed — which is why this differs from
/// `isValidTransactionInput`, where amount must be strictly positive.
bool isValidAssetInput({required String name, required double? amount}) {
  return name.trim().isNotEmpty && (amount ?? -1) >= 0;
}

/// Largest balance first, then by name, so the listing order is stable and
/// independent of the internal key order `Box.values` iterates in.
List<Asset> sortedAssets(List<Asset> assets) {
  final sorted = [...assets];
  sorted.sort((a, b) {
    final byAmount = b.amount.compareTo(a.amount);
    if (byAmount != 0) return byAmount;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return sorted;
}

double totalAssets(List<Asset> assets) {
  var total = 0.0;
  for (final a in assets) {
    total += a.amount;
  }
  return total;
}

final assetBoxProvider = Provider<Box<Asset>>((ref) {
  return Hive.box<Asset>(AssetRepository.boxName);
});

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.watch(assetBoxProvider));
});

final assetsProvider =
    StateNotifierProvider<AssetsNotifier, List<Asset>>((ref) {
  return AssetsNotifier(ref.watch(assetRepositoryProvider));
});

final sortedAssetsProvider = Provider<List<Asset>>((ref) {
  return sortedAssets(ref.watch(assetsProvider));
});

final totalAssetsProvider = Provider<double>((ref) {
  return totalAssets(ref.watch(assetsProvider));
});

class AssetsNotifier extends StateNotifier<List<Asset>> {
  AssetsNotifier(this._repo) : super(_repo.getAll());

  final AssetRepository _repo;
  int _seq = 0;

  Future<bool> addAsset({
    required String name,
    required String kind,
    required double amount,
    String note = '',
  }) async {
    if (!isValidAssetInput(name: name, amount: amount)) return false;
    final asset = Asset(
      id: 'as${DateTime.now().millisecondsSinceEpoch}_${_seq++}',
      name: name.trim(),
      kind: kind,
      amount: amount,
      asOfDate: toIsoDate(DateTime.now()),
      note: note,
    );
    await _repo.add(asset);
    state = _repo.getAll();
    return true;
  }

  Future<bool> updateAsset(
    String id, {
    required String name,
    required String kind,
    required double amount,
    String note = '',
  }) async {
    if (!isValidAssetInput(name: name, amount: amount)) return false;
    final existing = state.firstWhere((a) => a.id == id);
    existing
      ..name = name.trim()
      ..kind = kind
      ..amount = amount
      ..asOfDate = toIsoDate(DateTime.now())
      ..note = note;
    await _repo.update(existing);
    state = _repo.getAll();
    return true;
  }

  Future<void> deleteAsset(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}
