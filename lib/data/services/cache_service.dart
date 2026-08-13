import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _prefix = 'app_cache_';

  /// Simpan data JSON ke SharedPreferences
  static Future<void> saveCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(data);
      await prefs.setString('$_prefix$key', jsonString);
    } catch (_) {}
  }

  /// Ambil data JSON dari SharedPreferences
  static Future<dynamic> getCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('$_prefix$key');
      if (jsonString != null && jsonString.isNotEmpty) {
        return jsonDecode(jsonString);
      }
    } catch (_) {}
    return null;
  }

  /// Hapus cache tertentu
  static Future<void> removeCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$key');
    } catch (_) {}
  }

  /// Hapus seluruh cache API saat pengguna logout
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
