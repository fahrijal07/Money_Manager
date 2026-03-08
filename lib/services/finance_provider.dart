import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/saving_model.dart';
import '../models/reminder_model.dart';
import '../database/db_helper.dart';

class FinanceProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  List<SavingModel> _savings = [];
  List<ReminderModel> _reminders = [];
  ThemeMode _themeMode = ThemeMode.system;

  List<TransactionModel> get transactions => _transactions;
  List<SavingModel> get savings => _savings;
  List<ReminderModel> get reminders => _reminders;
  ThemeMode get themeMode => _themeMode;

  final DBHelper _dbHelper = DBHelper();

  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalExpense => _transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get balance => totalIncome - totalExpense;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> fetchAllData() async {
    _transactions = await _dbHelper.getAllTransactions();
    _savings = await _dbHelper.getAllSavings();
    _reminders = await _dbHelper.getAllReminders();
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _dbHelper.insertTransaction(transaction);
    await fetchAllData();
  }

  Future<void> deleteTransaction(int id) async {
    await _dbHelper.deleteTransaction(id);
    await fetchAllData();
  }

  Future<void> addSaving(SavingModel saving) async {
    await _dbHelper.insertSaving(saving);
    await fetchAllData();
  }

  Future<void> updateSaving(SavingModel saving, {double? addedAmount}) async {
    await _dbHelper.updateSaving(saving);
    
    if (addedAmount != null && addedAmount > 0) {
      final transaction = TransactionModel(
        title: 'Tabungan: ${saving.name}',
        amount: addedAmount,
        category: 'Tabungan',
        date: DateTime.now(),
        isIncome: false,
      );
      await _dbHelper.insertTransaction(transaction);
    }
    
    await fetchAllData();
  }

  Future<void> deleteSaving(int id) async {
    await _dbHelper.deleteSaving(id);
    await fetchAllData();
  }

  List<TransactionModel> get todayTransactions {
    final now = DateTime.now();
    return _transactions.where((t) => 
      t.date.year == now.year && 
      t.date.month == now.month && 
      t.date.day == now.day
    ).toList();
  }
}
