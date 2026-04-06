import 'package:shared_preferences/shared_preferences.dart';

import 'blackbox_storage_adapter.dart';

/// Built-in adapter for [SharedPreferences].
///
/// ```dart
/// BlackBox.setup(
///   storageAdapters: [SharedPrefsStorageAdapter()],
/// );
/// ```
class SharedPrefsStorageAdapter extends BlackBoxStorageAdapter {
  @override
  String get name => 'SharedPreferences';

  @override
  Future<Map<String, dynamic>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final result = <String, dynamic>{};
    for (final key in keys) {
      result[key] = prefs.get(key);
    }
    return result;
  }

  @override
  Future<void> write(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else {
      await prefs.setString(key, value.toString());
    }
  }

  @override
  Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
