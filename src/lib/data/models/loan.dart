import 'package:hive/hive.dart';

part 'loan.g.dart';

const loanTypeId = 4;

/// Money lent out or borrowed. Lending and borrowing share one model because
/// their fields and every operation on them — repayment, outstanding, settled,
/// sorting — are identical; [direction] discriminates, the same way
/// `Transaction.type` does for income/expense.
///
/// Settled state is deliberately *not* stored here: it is derived from the
/// repayments in the `repayments` box, so it can never drift when a repayment
/// is edited or deleted (specs.md §8).
@HiveType(typeId: loanTypeId)
class Loan extends HiveObject {
  Loan({
    required this.id,
    required this.direction,
    required this.personName,
    required this.amount,
    required this.date,
    this.dueDate = '',
    this.note = '',
  });

  @HiveField(0)
  String id;

  /// 'lent' (money owed to the user) or 'borrowed' (money the user owes).
  @HiveField(1)
  String direction;

  @HiveField(2)
  String personName;

  /// The original amount, before any repayment.
  @HiveField(3)
  double amount;

  /// ISO 8601 date, yyyy-MM-dd.
  @HiveField(4)
  String date;

  /// ISO 8601 date, yyyy-MM-dd, or '' when there is no due date. Empty-for-absent
  /// rather than nullable so the generated adapter cast stays non-nullable and
  /// lexicographic date compares need no null branches.
  @HiveField(5)
  String dueDate;

  @HiveField(6)
  String note;

  bool get isLent => direction == 'lent';
  bool get isBorrowed => direction == 'borrowed';

  bool get hasDueDate => dueDate.isNotEmpty;

  DateTime get dateTime => DateTime.parse(date);

  DateTime? get dueDateTime => hasDueDate ? DateTime.parse(dueDate) : null;
}
