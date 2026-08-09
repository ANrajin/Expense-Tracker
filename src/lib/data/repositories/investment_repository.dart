import 'package:hive/hive.dart';

import '../models/investment.dart';

class InvestmentRepository {
  InvestmentRepository(this._box);

  final Box<Investment> _box;

  static const boxName = 'investments';

  /// Unsorted — see the note on [AssetRepository].
  List<Investment> getAll() => _box.values.toList();

  Future<void> add(Investment investment) => _box.put(investment.id, investment);

  Future<void> update(Investment investment) => investment.save();

  Future<void> delete(String id) => _box.delete(id);
}
