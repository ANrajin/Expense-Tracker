import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../transactions/transactions_provider.dart';

final categoryBoxProvider = Provider<Box<Category>>((ref) {
  return Hive.box<Category>(CategoryRepository.boxName);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(categoryBoxProvider));
});

final categoryTransactionCountProvider =
    Provider.family<int, String>((ref, categoryId) {
  final transactions = ref.watch(transactionsProvider);
  return transactions.where((t) => t.categoryId == categoryId).length;
});

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<Category>>((ref) {
  return CategoriesNotifier(ref.watch(categoryRepositoryProvider));
});

/// Spec's delete rule: a category can only be removed if it isn't a
/// default and no transactions are currently assigned to it.
bool canDeleteCategory({required bool isDefault, required int transactionCount}) {
  return !isDefault && transactionCount == 0;
}

class CategoriesNotifier extends StateNotifier<List<Category>> {
  CategoriesNotifier(this._repo) : super(_repo.getAll());

  final CategoryRepository _repo;

  Future<void> addCategory(String name, String type) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final category = Category(
      id: 'cat${DateTime.now().millisecondsSinceEpoch}',
      name: trimmed,
      type: type,
      isDefault: false,
      active: true,
    );
    await _repo.add(category);
    state = _repo.getAll();
  }

  Future<void> toggleActive(String id) async {
    final category = state.firstWhere((c) => c.id == id);
    category.active = !category.active;
    await _repo.update(category);
    state = _repo.getAll();
  }

  /// Deletes the category if it's non-default and has no transactions
  /// assigned. Returns whether the delete happened.
  Future<bool> deleteCategory(String id, {required int transactionCount}) async {
    final category = state.firstWhere((c) => c.id == id);
    if (!canDeleteCategory(
        isDefault: category.isDefault, transactionCount: transactionCount)) {
      return false;
    }
    await _repo.delete(id);
    state = _repo.getAll();
    return true;
  }
}
