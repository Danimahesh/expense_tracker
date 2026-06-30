import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';
import '../utils/categories.dart';
import '../utils/payment_methods.dart';

/// Singleton helper that owns the SQLite database and all queries.
///
/// Tables:
///   * expenses
///   * categories
///   * payment_methods
///   * settings
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String dbName = 'expense_tracker.db';
  static const int dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<String> databaseFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, dbName);
  }

  Future<Database> _open() async {
    final path = await databaseFilePath();
    return openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        date INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        label TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        label TEXT NOT NULL,
        has_billing_cycle INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db
        .execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db.execute(
        'CREATE INDEX idx_expenses_method ON expenses(payment_method)');

    // Seed reference tables.
    final batch = db.batch();
    for (final c in Categories.all) {
      batch.insert('categories', {'key': c.key, 'label': c.label});
    }
    for (final m in PaymentMethods.all) {
      batch.insert('payment_methods', {
        'key': m.key,
        'label': m.label,
        'has_billing_cycle': m.hasBillingCycle ? 1 : 0,
      });
    }
    batch.insert('settings', {'key': 'currency', 'value': '₹'});
    batch.insert('settings', {'key': 'dark_theme', 'value': 'true'});
    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------------------
  // Expense CRUD
  // ---------------------------------------------------------------------------

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert('expenses', expense.toMap()..remove('id'));
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final rows = await db.query('expenses', orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> deleteAllExpenses() async {
    final db = await database;
    return db.delete('expenses');
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> getSettings() async {
    final db = await database;
    final rows = await db.query('settings');
    return {
      for (final row in rows)
        row['key'] as String: row['value'] as String,
    };
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Closes the database so the underlying file can be replaced (restore).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Re-opens the database after a restore.
  Future<void> reopen() async {
    await close();
    _db = await _open();
  }
}
