import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/models/category.dart';
import 'data/models/transaction.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/transaction_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(TransactionAdapter());

  await Hive.openBox(settingsBoxName);
  final categoryBox = await Hive.openBox<Category>(CategoryRepository.boxName);
  await CategoryRepository(categoryBox).seedDefaultsIfEmpty();
  await Hive.openBox<Transaction>(TransactionRepository.boxName);

  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}
