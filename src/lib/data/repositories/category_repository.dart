import 'package:hive/hive.dart';

import '../models/category.dart';

class CategoryRepository {
  CategoryRepository(this._box);

  final Box<Category> _box;

  static const boxName = 'categories';

  static final List<Category> defaultCategories = [
    Category(id: 'salary', name: 'Salary', type: 'income', isDefault: true, active: true),
    Category(id: 'freelance', name: 'Freelance', type: 'income', isDefault: true, active: true),
    Category(id: 'other_income', name: 'Other', type: 'income', isDefault: true, active: true),
    Category(id: 'food', name: 'Food', type: 'expense', isDefault: true, active: true),
    Category(id: 'transport', name: 'Transport', type: 'expense', isDefault: true, active: true),
    Category(id: 'bills', name: 'Bills', type: 'expense', isDefault: true, active: true),
    Category(id: 'shopping', name: 'Shopping', type: 'expense', isDefault: true, active: true),
    Category(id: 'health', name: 'Health', type: 'expense', isDefault: true, active: true),
    Category(id: 'entertainment', name: 'Entertainment', type: 'expense', isDefault: true, active: true),
  ];

  static final List<String> _defaultOrder =
      defaultCategories.map((c) => c.id).toList();

  /// Hive's `Box.values` iterates by internal key order, not insertion
  /// order, so results are sorted explicitly here: defaults keep their
  /// canonical spec order, custom categories follow alphabetically.
  List<Category> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      if (a.isDefault) {
        return _defaultOrder.indexOf(a.id).compareTo(_defaultOrder.indexOf(b.id));
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  Future<void> seedDefaultsIfEmpty() async {
    if (_box.isNotEmpty) return;
    for (final c in defaultCategories) {
      await _box.put(c.id, c);
    }
  }

  Future<void> add(Category category) => _box.put(category.id, category);

  Future<void> update(Category category) => category.save();

  Future<void> delete(String id) => _box.delete(id);
}
