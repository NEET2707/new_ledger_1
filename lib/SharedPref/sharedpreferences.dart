import 'package:shared_preferences/shared_preferences.dart';

enum PrefKey { pin, password, userEmail, userId, currencySymbol }

class SharedPreferenceHelper {
  static late SharedPreferences _sharedPreferences;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  // Static methods for generic save, get, delete operations
  static Future<void> save({required String value, required PrefKey prefKey}) async {
    await _sharedPreferences.setString(prefKey.name, value);
  }

  static String? get({required PrefKey prefKey}) {
    return _sharedPreferences.getString(prefKey.name);
  }

  static Future<void> deleteSpecific({required PrefKey prefKey}) async {
    await _sharedPreferences.remove(prefKey.name);
  }

  static Future<void> deleteAll() async {
    await _sharedPreferences.clear();
  }

  // Non-static methods for user-specific data
  Future<bool> saveUserEmail(String getUserEmail) async {
    return await _sharedPreferences.setString(PrefKey.userEmail.name, getUserEmail);
  }

  Future<bool> saveUserId(String getUserId) async {
    return await _sharedPreferences.setString(PrefKey.userId.name, getUserId);
  }

  Future<String?> getUserEmail() async {
    return _sharedPreferences.getString(PrefKey.userEmail.name);
  }

  Future<String?> getUserId() async {
    return _sharedPreferences.getString(PrefKey.userId.name);
  }

  // Methods for handling PIN and password (added to PrefKey enum)
  Future<bool> savePin(String pin) async {
    return await _sharedPreferences.setString(PrefKey.pin.name, pin);
  }

  Future<String?> getPin() async {
    return _sharedPreferences.getString(PrefKey.pin.name);
  }

  Future<bool> savePassword(String password) async {
    return await _sharedPreferences.setString(PrefKey.password.name, password);
  }

  Future<String?> getPassword() async {
    return _sharedPreferences.getString(PrefKey.password.name);
  }

}
