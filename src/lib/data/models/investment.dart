import 'package:hive/hive.dart';

part 'investment.g.dart';

const investmentTypeId = 3;

/// Something the user put money into, valued by hand. [currentValue] is only
/// ever changed by the user — the app is fully offline, so there is no price
/// feed and no automatic valuation (specs.md §8).
@HiveType(typeId: investmentTypeId)
class Investment extends HiveObject {
  Investment({
    required this.id,
    required this.name,
    required this.type,
    required this.investedAmount,
    required this.currentValue,
    required this.date,
    required this.valuedDate,
    this.note = '',
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// 'stock', 'dps', 'fdr', 'gold', 'crypto' or 'other'.
  @HiveField(2)
  String type;

  @HiveField(3)
  double investedAmount;

  @HiveField(4)
  double currentValue;

  /// ISO 8601 date, yyyy-MM-dd — when the money was invested.
  @HiveField(5)
  String date;

  /// ISO 8601 date, yyyy-MM-dd — when [currentValue] was last updated.
  @HiveField(6)
  String valuedDate;

  @HiveField(7)
  String note;

  DateTime get dateTime => DateTime.parse(date);

  DateTime get valuedDateTime => DateTime.parse(valuedDate);
}
