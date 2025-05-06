import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static int? userID;
  static String? displayName;
  static String? email;

  // Simpan ke SharedPreferences
  static Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (userID != null) {
      await prefs.setInt('userID', userID!);
    }
    if (displayName != null) {
      await prefs.setString('displayName', displayName!);
    }
    if (email != null) {
      await prefs.setString('email', email!);
    }
  }

  // Load dari SharedPreferences
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getInt('userID');
    displayName = prefs.getString('displayName');
    email = prefs.getString('email');
  }

  // Hapus Session (Logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userID');
    await prefs.remove('displayName');
    await prefs.remove('email');
    userID = null;
    displayName = null;
    email = null;
  }
}
