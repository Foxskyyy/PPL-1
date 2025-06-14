import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static int? userID;
  static String? displayName;
  static String? email;
  static int? currentGroupID;
  static String? currentDeviceID;

  // Simpan data session ke SharedPreferences
  static Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (userID != null) await prefs.setInt('userID', userID!);
    if (displayName != null) await prefs.setString('displayName', displayName!);
    if (email != null) await prefs.setString('email', email!);
    if (currentGroupID != null)
      await prefs.setInt('currentGroupID', currentGroupID!);
    if (currentDeviceID != null)
      await prefs.setString('currentDeviceID', currentDeviceID!);
  }

  // Muat data session dari SharedPreferences
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getInt('userID');
    displayName = prefs.getString('displayName');
    email = prefs.getString('email');
    currentGroupID = prefs.getInt('currentGroupID');
    currentDeviceID = prefs.getString('currentDeviceID');
  }

  // Hapus semua data session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userID');
    await prefs.remove('displayName');
    await prefs.remove('email');
    await prefs.remove('currentGroupID');
    await prefs.remove('currentDeviceID');

    userID = null;
    displayName = null;
    email = null;
    currentGroupID = null;
    currentDeviceID = null;
  }

  // Getter async: ambil current group ID
  static Future<int?> getCurrentGroupID() async {
    if (currentGroupID != null) return currentGroupID;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('currentGroupID');
  }

  // Getter async: ambil current device ID
  static Future<String?> getCurrentDeviceID() async {
    if (currentDeviceID != null) return currentDeviceID;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currentDeviceID');
  }

  // Getter async: ambil user ID jika dibutuhkan
  static Future<int?> getUserID() async {
    if (userID != null) return userID;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userID');
  }
}
