import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';

final transactionBoxProvider = Provider<Box<Transaction>>((ref) {
  return Hive.box<Transaction>(TransactionRepository.boxName);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(transactionBoxProvider));
});

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  return TransactionsNotifier(ref.watch(transactionRepositoryProvider));
});

/// Spec's save requirement: amount must be positive; category and date
/// are required. Shared by [TransactionsNotifier] and the form screen so
/// the rule lives in exactly one place.
bool isValidTransactionInput({
  required double? amount,
  required String? categoryId,
  required String? date,
}) {
  return (amount ?? 0) > 0 && categoryId != null && date != null;
}

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  TransactionsNotifier(this._repo) : super(_repo.getAll());

  final TransactionRepository _repo;
  int _seq = 0;

  /// Adds a new transaction. Returns false (no-op) if the spec's required
  /// fields aren't satisfied: amount > 0, category, and date.
  Future<bool> addTransaction({
    required String type,
    required String? categoryId,
    required double amount,
    required String? date,
    String note = '',
  }) async {
    if (!isValidTransactionInput(amount: amount, categoryId: categoryId, date: date)) {
      return false;
    }
    final transaction = Transaction(
      id: 'tx${DateTime.now().millisecondsSinceEpoch}_${_seq++}',
      type: type,
      categoryId: categoryId!,
      amount: amount,
      date: date!,
      note: note,
    );
    await _repo.add(transaction);
    state = _repo.getAll();
    return true;
  }

  Future<bool> updateTransaction(
    String id, {
    required String type,
    required String? categoryId,
    required double amount,
    required String? date,
    String note = '',
  }) async {
    if (!isValidTransactionInput(amount: amount, categoryId: categoryId, date: date)) {
      return false;
    }
    final existing = state.firstWhere((t) => t.id == id);
    existing
      ..type = type
      ..categoryId = categoryId!
      ..amount = amount
      ..date = date!
      ..note = note;
    await _repo.update(existing);
    state = _repo.getAll();
    return true;
  }

  Future<void> deleteTransaction(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}
