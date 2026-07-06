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

  // ── Auth Tokens (WhatsApp Login / Token Auth) ──────────────────────────────
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: AppConstants.keyAccessToken, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: AppConstants.keyAccessToken);

  Future<void> saveClient(String client) =>
      _storage.write(key: AppConstants.keyClient, value: client);

  Future<String?> getClient() =>
      _storage.read(key: AppConstants.keyClient);

  Future<void> saveExpiry(String expiry) =>
      _storage.write(key: AppConstants.keyExpiry, value: expiry);

  Future<String?> getExpiry() =>
      _storage.read(key: AppConstants.keyExpiry);

  Future<void> saveTokenType(String tokenType) =>
      _storage.write(key: AppConstants.keyTokenType, value: tokenType);

  Future<String?> getTokenType() =>
      _storage.read(key: AppConstants.keyTokenType);

  Future<void> saveUid(String uid) =>
      _storage.write(key: AppConstants.keyUid, value: uid);

  Future<String?> getUid() =>
      _storage.read(key: AppConstants.keyUid);

  Future<void> saveAuthTokens({
    required String accessToken,
    required String client,
    required String expiry,
    required String tokenType,
    required String uid,
  }) async {
    await saveAccessToken(accessToken);
    await saveClient(client);
    await saveExpiry(expiry);
    await saveTokenType(tokenType);
    await saveUid(uid);
    // Also save as general auth token for backwards compatibility
    await saveAuthToken(accessToken);
  }

  Future<void> deleteAuthTokens() async {
    await _storage.delete(key: AppConstants.keyAccessToken);
    await _storage.delete(key: AppConstants.keyClient);
    await _storage.delete(key: AppConstants.keyExpiry);
    await _storage.delete(key: AppConstants.keyTokenType);
    await _storage.delete(key: AppConstants.keyUid);
    await deleteAuthToken();
    await deleteCookie();
  }

  // ── Cookie (Session / OTP verification) ───────────────────────────────────
  Future<void> saveCookie(String cookie) =>
      _storage.write(key: AppConstants.keyCookie, value: cookie);

  Future<String?> getCookie() =>
      _storage.read(key: AppConstants.keyCookie);

  Future<void> deleteCookie() =>
      _storage.delete(key: AppConstants.keyCookie);

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
    final token = await getAccessToken() ?? await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
