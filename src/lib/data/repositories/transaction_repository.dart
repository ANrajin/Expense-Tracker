import 'package:hive/hive.dart';

import '../models/transaction.dart';

class TransactionRepository {
  TransactionRepository(this._box);

  final Box<Transaction> _box;

  static const boxName = 'transactions';

  List<Transaction> getAll() => _box.values.toList();

  Future<void> add(Transaction transaction) =>
      _box.put(transaction.id, transaction);

  Future<void> update(Transaction transaction) => transaction.save();

  Future<void> delete(String id) => _box.delete(id);

  /// Removes every transaction in [ids] in a single box write — the bulk
  /// month/year/all-history deletes in Data Management.
  Future<void> deleteMany(Iterable<String> ids) => _box.deleteAll(ids);

  int countByCategory(String categoryId) =>
      _box.values.where((t) => t.categoryId == categoryId).length;
}
