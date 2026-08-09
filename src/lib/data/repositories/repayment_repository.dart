import 'package:hive/hive.dart';

import '../models/repayment.dart';

class RepaymentRepository {
  RepaymentRepository(this._box);

  final Box<Repayment> _box;

  static const boxName = 'repayments';

  /// Unsorted — see the note on [AssetRepository].
  List<Repayment> getAll() => _box.values.toList();

  Future<void> add(Repayment repayment) => _box.put(repayment.id, repayment);

  Future<void> update(Repayment repayment) => repayment.save();

  Future<void> delete(String id) => _box.delete(id);

  /// Removes every repayment in [ids] in a single box write — the cascade that
  /// runs when the loan they belong to is deleted.
  Future<void> deleteMany(Iterable<String> ids) => _box.deleteAll(ids);
}
