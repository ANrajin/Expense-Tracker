import 'package:hive/hive.dart';

part 'repayment.g.dart';

/// Next free Hive typeId is 6 — 0..5 are Category, Transaction, Asset,
/// Investment, Loan and Repayment.
const repaymentTypeId = 5;

/// One payment made against a [Loan], referenced by [loanId].
///
/// Repayments live in their own box rather than as a list embedded on the loan:
/// a nested `@HiveType` would need its own adapter and typeId anyway, and only a
/// top-level `HiveObject` can use the app-wide `update(x) => x.save()` idiom.
/// Keeping them separate also makes outstanding/settled pure functions over two
/// plain lists, so they test without Hive.
///
/// The cost is no referential integrity — deleting a loan cascades to its
/// repayments at the call site, and every read filters on [loanId], so a stray
/// orphan is inert rather than corrupting.
@HiveType(typeId: repaymentTypeId)
class Repayment extends HiveObject {
  Repayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String loanId;

  @HiveField(2)
  double amount;

  /// ISO 8601 date, yyyy-MM-dd.
  @HiveField(3)
  String date;

  @HiveField(4)
  String note;

  DateTime get dateTime => DateTime.parse(date);
}
