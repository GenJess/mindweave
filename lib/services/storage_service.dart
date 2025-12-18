import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get instance {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
    return _prefs!;
  }

  static Future<bool> setString(String key, String value) async {
    return await instance.setString(key, value);
  }

  static String? getString(String key) {
    return instance.getString(key);
  }

  static Future<bool> setStringList(String key, List<String> value) async {
    return await instance.setStringList(key, value);
  }

  static List<String>? getStringList(String key) {
    return instance.getStringList(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    return await instance.setBool(key, value);
  }

  static bool? getBool(String key) {
    return instance.getBool(key);
  }

  static Future<bool> setInt(String key, int value) async {
    return await instance.setInt(key, value);
  }

  static int? getInt(String key) {
    return instance.getInt(key);
  }

  static Future<bool> remove(String key) async {
    return await instance.remove(key);
  }

  static Future<bool> clear() async {
    return await instance.clear();
  }

  // Helper methods for JSON data
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return await setString(key, json.encode(value));
  }

  static Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) async {
    return await setString(key, json.encode(value));
  }

  static List<Map<String, dynamic>>? getJsonList(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    try {
      return (json.decode(jsonString) as List)
          .cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }
}