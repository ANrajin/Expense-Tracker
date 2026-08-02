import 'package:hive/hive.dart';

part 'category.g.dart';

const categoryTypeId = 0;

@HiveType(typeId: categoryTypeId)
class Category extends HiveObject {
  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.isDefault,
    required this.active,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// 'income' or 'expense'.
  @HiveField(2)
  String type;

  @HiveField(3)
  bool isDefault;

  @HiveField(4)
  bool active;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}
