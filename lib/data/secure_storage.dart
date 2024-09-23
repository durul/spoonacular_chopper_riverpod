import 'package:flutter_secure_storage/flutter_secure_storage.dart';

///
/// Wrapper helper around [FlutterSecureStorage]
///
class SecureStorage {
  final _storage = const FlutterSecureStorage();

  ///
  /// Write value to [FlutterSecureStorage]
  ///
  Future write(String key, String value) async {
    return _storage.write(key: key, value: value);
  }

  ///
  /// Read value from [FlutterSecureStorage]
  ///
  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  ///
  /// Delete value from [FlutterSecureStorage]
  ///
  Future delete(String key) async {
    return _storage.delete(key: key);
  }

  Future<bool> hasKey(String key) async {
    return _storage.containsKey(key: key);
  }
}
