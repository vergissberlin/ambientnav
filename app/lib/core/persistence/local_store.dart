/// Minimal key/value persistence abstraction so features don't depend on a
/// concrete storage engine. Swappable (Hive now, Drift later) and trivially
/// faked in tests via [InMemoryLocalStore].
abstract interface class LocalStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

/// In-memory implementation used in tests and as a safe default before Hive is
/// initialized.
class InMemoryLocalStore implements LocalStore {
  final Map<String, String> _data = {};

  @override
  String? getString(String key) => _data[key];

  @override
  Future<void> setString(String key, String value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);
}
