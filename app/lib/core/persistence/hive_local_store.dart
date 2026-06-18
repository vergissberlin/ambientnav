import 'package:hive_ce_flutter/hive_flutter.dart';

import 'local_store.dart';

/// Hive-backed [LocalStore]. Initialized once at app start.
class HiveLocalStore implements LocalStore {
  HiveLocalStore._(this._box);

  final Box<String> _box;

  static const String _boxName = 'ambientnav';

  static Future<HiveLocalStore> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(_boxName);
    return HiveLocalStore._(box);
  }

  @override
  String? getString(String key) => _box.get(key);

  @override
  Future<void> setString(String key, String value) => _box.put(key, value);

  @override
  Future<void> remove(String key) => _box.delete(key);
}
