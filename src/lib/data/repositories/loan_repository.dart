import 'package:hive/hive.dart';

import '../models/loan.dart';

class LoanRepository {
  LoanRepository(this._box);

  final Box<Loan> _box;

  static const boxName = 'loans';

  /// Unsorted — see the note on [AssetRepository].
  List<Loan> getAll() => _box.values.toList();

  Future<void> add(Loan loan) => _box.put(loan.id, loan);

  Future<void> update(Loan loan) => loan.save();

  Future<void> delete(String id) => _box.delete(id);
}
