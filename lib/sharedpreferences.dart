import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {

  static String userEmailKey = "USEREMAILKEY";
  static String userIdKey = "USERIDKEY";

  // To save data from shared preferences



  Future<bool> saveUserEmail(String getUserEmail) async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return preference.setString(userEmailKey, getUserEmail);
  }

  Future<bool> saveUserId(String getUserId) async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return preference.setString(userIdKey, getUserId);
  }




  // For Getting data from shared preferences



  Future<String?> getUserEmail() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(userEmailKey);
  }

  Future<String?> getUserId() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(userIdKey);
  }


}