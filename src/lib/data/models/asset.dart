import 'package:hive/hive.dart';

part 'asset.g.dart';

const assetTypeId = 2;

/// A balance the user maintains by hand — cash in a wallet, a bank account, a
/// mobile-money account. Deliberately has no transaction history: recording an
/// income or expense never adjusts an asset (specs.md §8).
@HiveType(typeId: assetTypeId)
class Asset extends HiveObject {
  Asset({
    required this.id,
    required this.name,
    required this.kind,
    required this.amount,
    required this.asOfDate,
    this.note = '',
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// 'cash', 'bank', 'mobile' or 'other'.
  @HiveField(2)
  String kind;

  @HiveField(3)
  double amount;

  /// ISO 8601 date, yyyy-MM-dd — when the user last set [amount].
  @HiveField(4)
  String asOfDate;

  @HiveField(5)
  String note;

  DateTime get asOfDateTime => DateTime.parse(asOfDate);
}
