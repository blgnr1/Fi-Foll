import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String _ratesKey = 'fx_rates_json';
  static const String _timestampKey = 'fx_rates_timestamp';
  static const String _apiUrl = 'https://api.exchangerate-api.com/v4/latest/TRY';

  // Fallback rates: how many TRY per 1 unit of foreign currency
  static const Map<String, double> _fallback = {
    'TRY': 1.0,
    'USD': 35.0,
    'EUR': 38.0,
  };

  /// Returns rates as TRY per 1 unit of each currency.
  /// e.g. { 'USD': 35.5, 'EUR': 38.2 }
  Future<Map<String, double>> getRates() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_ratesKey);
    final timestamp = prefs.getInt(_timestampKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Cache is valid for 24 hours
    if (cached != null && (now - timestamp) < 86400000) {
      final Map<String, dynamic> decoded = jsonDecode(cached);
      return _invertRates(decoded.map((k, v) => MapEntry(k, (v as num).toDouble())));
    }

    // Try fetching fresh rates
    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // data['rates'] contains { 'USD': 0.02857, 'EUR': 0.0263, ... }
        // These are "1 TRY in foreign currency", we need to invert to get "TRY per 1 foreign currency"
        final Map<String, dynamic> rawRates = data['rates'] as Map<String, dynamic>;
        await prefs.setString(_ratesKey, jsonEncode(rawRates));
        await prefs.setInt(_timestampKey, now);
        return _invertRates(rawRates.map((k, v) => MapEntry(k, (v as num).toDouble())));
      }
    } catch (_) {
      // Network failure — fall through to cached or fallback
    }

    // Use stale cache if available
    if (cached != null) {
      final Map<String, dynamic> decoded = jsonDecode(cached);
      return _invertRates(decoded.map((k, v) => MapEntry(k, (v as num).toDouble())));
    }

    return _fallback;
  }

  /// Converts raw API rates (TRY→X) to inverted map (X→TRY)
  Map<String, double> _invertRates(Map<String, double> raw) {
    final result = <String, double>{'TRY': 1.0};
    for (final entry in raw.entries) {
      if (entry.value > 0) {
        result[entry.key] = 1.0 / entry.value;
      }
    }
    return result;
  }
}
