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

  int countByCategory(String categoryId) =>
      _box.values.where((t) => t.categoryId == categoryId).length;
}
