import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/currency_service.dart';

class WalletProvider with ChangeNotifier {
  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  Map<String, double> _rates = {'TRY': 1.0, 'USD': 35.0, 'EUR': 38.0};

  List<Account> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  Map<String, double> get exchangeRatesToTryMap => _rates;

  WalletProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _loadData();
      _rates = await CurrencyService().getRates();
    } catch (e) {
      debugPrint('WalletProvider Init Error: $e');
    }
    notifyListeners();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getStringList('accounts');
      final transactionsJson = prefs.getStringList('transactions');

      if (accountsJson != null) {
        _accounts = accountsJson
            .map((e) => Account.fromJson(jsonDecode(e)))
            .toList();
      }
      if (transactionsJson != null) {
        _transactions = transactionsJson
            .map((e) => Transaction.fromJson(jsonDecode(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('WalletProvider Load Data Error: $e');
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('accounts', _accounts.map((e) => jsonEncode(e.toJson())).toList());
    await prefs.setStringList('transactions', _transactions.map((e) => jsonEncode(e.toJson())).toList());
  }

  void addAccount(String name) {
    if (name.trim().isEmpty) return;
    _accounts.add(Account(name: name.trim()));
    _saveData();
    notifyListeners();
  }

  void deleteAccount(String accountId) {
    _accounts.removeWhere((a) => a.id == accountId);
    _transactions.removeWhere((t) => t.accountId == accountId);
    _saveData();
    notifyListeners();
  }

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    _saveData();
    notifyListeners();
  }

  void deleteTransaction(String transactionId) {
    _transactions.removeWhere((t) => t.id == transactionId);
    _saveData();
    notifyListeners();
  }

  List<Transaction> getTransactionsForAccount(String accountId) {
    return _transactions.where((t) => t.accountId == accountId).toList();
  }

  List<Transaction> getActiveTransactions(String accountId) {
    return _transactions
        .where((t) => t.accountId == accountId && t.status != TransactionStatus.settled)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Transaction> getSettledTransactions(String accountId) {
    return _transactions
        .where((t) => t.accountId == accountId && t.status == TransactionStatus.settled)
        .toList()
      ..sort((a, b) => (b.settledAt ?? b.createdAt).compareTo(a.settledAt ?? a.createdAt));
  }

  void settleTransaction(String transactionId) {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      _transactions[index].status = TransactionStatus.settled;
      _transactions[index].paidAmount = _transactions[index].amount;
      _transactions[index].settledAt = DateTime.now();
      _saveData();
      notifyListeners();
    }
  }

  void addPartialPayment(String transactionId, double amount) {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      final t = _transactions[index];
      t.paidAmount += amount;
      if (t.paidAmount >= t.amount) {
        t.status = TransactionStatus.settled;
        t.paidAmount = t.amount;
        t.settledAt = DateTime.now();
      } else {
        t.status = TransactionStatus.partial;
      }
      _saveData();
      notifyListeners();
    }
  }

  double getTotalCredits(String accountId) {
    double total = 0;
    for (var t in getActiveTransactions(accountId)) {
      if (t.type == TransactionType.credit) {
        total += t.remainingAmount * (_rates[t.currency] ?? 1.0);
      }
    }
    return total;
  }

  double getTotalDebts(String accountId) {
    double total = 0;
    for (var t in getActiveTransactions(accountId)) {
      if (t.type == TransactionType.debt) {
        total += t.remainingAmount * (_rates[t.currency] ?? 1.0);
      }
    }
    return total;
  }

  double getNetUSD(String accountId) {
    final net = getTotalCredits(accountId) - getTotalDebts(accountId);
    return net / (_rates['USD'] ?? 35.0);
  }
}
