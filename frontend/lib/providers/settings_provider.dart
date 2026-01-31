import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for app settings
class SettingsProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _defaultCurrencyKey = 'default_currency';
  static const String _defaultLanguagesKey = 'default_languages';

  ThemeMode _themeMode = ThemeMode.system;
  String _defaultCurrency = 'USD';
  List<String> _defaultLanguages = ['en'];

  ThemeMode get themeMode => _themeMode;
  String get defaultCurrency => _defaultCurrency;
  List<String> get defaultLanguages => _defaultLanguages;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];
    
    _defaultCurrency = prefs.getString(_defaultCurrencyKey) ?? 'USD';
    _defaultLanguages = prefs.getStringList(_defaultLanguagesKey) ?? ['en'];
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setDefaultCurrency(String currency) async {
    _defaultCurrency = currency;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultCurrencyKey, currency);
  }

  Future<void> setDefaultLanguages(List<String> languages) async {
    _defaultLanguages = languages;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_defaultLanguagesKey, languages);
  }

  /// Available currencies
  static const List<Map<String, String>> currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'KRW', 'name': 'Korean Won', 'symbol': '₩'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': '\$'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': '\$'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': '\$'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar', 'symbol': '\$'},
    {'code': 'THB', 'name': 'Thai Baht', 'symbol': '฿'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    {'code': 'VND', 'name': 'Vietnamese Dong', 'symbol': '₫'},
  ];

  /// Available OCR languages
  static const List<Map<String, String>> ocrLanguages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'zh', 'name': 'Chinese (Simplified)'},
    {'code': 'zh-tw', 'name': 'Chinese (Traditional)'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'ko', 'name': 'Korean'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'de', 'name': 'German'},
    {'code': 'it', 'name': 'Italian'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'ru', 'name': 'Russian'},
    {'code': 'ar', 'name': 'Arabic'},
    {'code': 'th', 'name': 'Thai'},
    {'code': 'vi', 'name': 'Vietnamese'},
  ];
}
