import 'package:hive/hive.dart';

part 'transaction.g.dart';

const transactionTypeId = 1;

@HiveType(typeId: transactionTypeId)
class Transaction extends HiveObject {
  Transaction({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  @HiveField(0)
  String id;

  /// 'income' or 'expense'.
  @HiveField(1)
  String type;

  @HiveField(2)
  String categoryId;

  @HiveField(3)
  double amount;

  /// ISO 8601 date, yyyy-MM-dd (no time component — a transaction happens
  /// on a calendar day, matching the spec's "Manual date selection").
  @HiveField(4)
  String date;

  @HiveField(5)
  String note;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  DateTime get dateTime => DateTime.parse(date);
}
