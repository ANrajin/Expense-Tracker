import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/models/asset.dart';
import 'data/models/category.dart';
import 'data/models/investment.dart';
import 'data/models/loan.dart';
import 'data/models/repayment.dart';
import 'data/models/transaction.dart';
import 'data/repositories/asset_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/investment_repository.dart';
import 'data/repositories/loan_repository.dart';
import 'data/repositories/repayment_repository.dart';
import 'data/repositories/transaction_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Every adapter registers before any typed box opens — opening a typed box
  // deserializes its existing records immediately, which needs the adapter.
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(AssetAdapter());
  Hive.registerAdapter(InvestmentAdapter());
  Hive.registerAdapter(LoanAdapter());
  Hive.registerAdapter(RepaymentAdapter());

  // Every box opens before runApp, so providers can use the synchronous
  // Hive.box<T>() accessor. AppShell's IndexedStack builds all four tabs on the
  // first frame, so a box left unopened is a launch crash, not a lazy one.
  await Hive.openBox(settingsBoxName);
  final categoryBox = await Hive.openBox<Category>(CategoryRepository.boxName);
  await CategoryRepository(categoryBox).seedDefaultsIfEmpty();
  await Hive.openBox<Transaction>(TransactionRepository.boxName);
  await Hive.openBox<Asset>(AssetRepository.boxName);
  await Hive.openBox<Investment>(InvestmentRepository.boxName);
  await Hive.openBox<Loan>(LoanRepository.boxName);
  await Hive.openBox<Repayment>(RepaymentRepository.boxName);

  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}
