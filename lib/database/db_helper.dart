import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/saving_model.dart';
import '../models/reminder_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() => _instance;

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'money_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount REAL,
        category TEXT,
        date TEXT,
        note TEXT,
        isIncome INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE savings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        targetAmount REAL,
        savedAmount REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        dateTime TEXT,
        isActive INTEGER
      )
    ''');
  }

  // Transaction CRUD
  Future<int> insertTransaction(TransactionModel transaction) async {
    Database db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Saving CRUD
  Future<int> insertSaving(SavingModel saving) async {
    Database db = await database;
    return await db.insert('savings', saving.toMap());
  }

  Future<List<SavingModel>> getAllSavings() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('savings');
    return List.generate(maps.length, (i) => SavingModel.fromMap(maps[i]));
  }

  Future<int> updateSaving(SavingModel saving) async {
    Database db = await database;
    return await db.update('savings', saving.toMap(), where: 'id = ?', whereArgs: [saving.id]);
  }

  Future<int> deleteSaving(int id) async {
    Database db = await database;
    return await db.delete('savings', where: 'id = ?', whereArgs: [id]);
  }

  // Reminder CRUD
  Future<int> insertReminder(ReminderModel reminder) async {
    Database db = await database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<List<ReminderModel>> getAllReminders() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('reminders');
    return List.generate(maps.length, (i) => ReminderModel.fromMap(maps[i]));
  }

  Future<int> deleteReminder(int id) async {
    Database db = await database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}
