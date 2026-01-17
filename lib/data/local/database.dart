import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// NORMALIZATION: Store unique merchants to save space ("Starbucks" stored once)
class Merchants extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

// NORMALIZATION: Categories are predefined or user-defined, stored once.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get icon => text().nullable()(); // Material Icon code
  TextColumn get color => text().nullable()(); // Hex color
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  
  // Relations (Space Optimization: Store IDs instead of Strings)
  IntColumn get merchantId => integer().references(Merchants, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().nullable()();
  
  // Metadata for "Trust" & Audit
  BoolColumn get isManual => boolean().withDefault(const Constant(false))();
  TextColumn get sourceSmsId => text().nullable()(); // ID of the SMS if auto-generated
}

@DriftDatabase(tables: [Expenses, Merchants, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      // SPACE OPTIMIZATION: Compact the DB on every start
      // In a real large app, you might run this less frequently.
      await customStatement('VACUUM'); 
    },
    onCreate: (m) async {
       await m.createAll();
       // Seed default categories
       await _seedCategories();
    }
  );

  Future<void> _seedCategories() async {
    final defaultCats = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Other'];
    for (var cat in defaultCats) {
      await into(categories).insert(
        CategoriesCompanion(name: Value(cat), isDefault: const Value(true)),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'expense_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
