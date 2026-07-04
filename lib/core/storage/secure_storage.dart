import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage(this._storage);

  // ── Auth Token ─────────────────────────────────────────────────────────────
  Future<void> saveAuthToken(String token) =>
      _storage.write(key: AppConstants.keyAuthToken, value: token);

  Future<String?> getAuthToken() =>
      _storage.read(key: AppConstants.keyAuthToken);

  Future<void> deleteAuthToken() =>
      _storage.delete(key: AppConstants.keyAuthToken);

  // ── Refresh Token ──────────────────────────────────────────────────────────
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: AppConstants.keyRefreshToken, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: AppConstants.keyRefreshToken);

  // ── Selected Node ──────────────────────────────────────────────────────────
  Future<void> saveNodeId(String nodeId) =>
      _storage.write(key: AppConstants.keySelectedNodeId, value: nodeId);

  Future<String?> getNodeId() =>
      _storage.read(key: AppConstants.keySelectedNodeId);

  // ── User Info ──────────────────────────────────────────────────────────────
  Future<void> saveUserId(String id) =>
      _storage.write(key: AppConstants.keyUserId, value: id);

  Future<String?> getUserId() =>
      _storage.read(key: AppConstants.keyUserId);

  Future<void> saveUserName(String name) =>
      _storage.write(key: AppConstants.keyUserName, value: name);

  Future<String?> getUserName() =>
      _storage.read(key: AppConstants.keyUserName);

  // ── Clear All ──────────────────────────────────────────────────────────────
  Future<void> clearAll() => _storage.deleteAll();

  Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
