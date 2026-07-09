import 'package:dio/dio.dart' show Dio, DioException;
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../home/data/models/dashboard_stats.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';

class AuthRepository {
  // ignore: unused_field
  final Dio _dio;
  final SecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  /// Send OTP via WhatsApp to the user's mobile number.
  Future<bool> sendWhatsAppOtp(SendOtpRequest request) async {
    if (request.mobileNumber.isEmpty || request.mobileNumber.length < 8) {
      throw Exception('Please enter a valid mobile number');
    }

    try {
      final response = await _dio.post(
        ApiEndpoints.sendOtp,
        data: request.toJson(),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Verify WhatsApp OTP and persist the 5 auth tokens returned in response.
  Future<UserModel> verifyWhatsAppOtp(VerifyOtpRequest request) async {
    if (request.otp.isEmpty) {
      throw Exception('Please enter verification code');
    }

    try {
      final response = await _dio.post(
        ApiEndpoints.verifyOtp,
        data: request.toJson(),
      );

      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }

      // Extract tokens from response headers or JSON body
      final tokens = AuthTokens.fromResponse(
        headers: response.headers,
        data: response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : null,
      );

      final userData = response.data is Map
          ? (response.data['data'] ?? response.data['user'] ?? response.data)
          : {};
      final userModel = UserModel.fromJson(userData as Map<String, dynamic>);

      if (tokens.isValid) {
        await _storage.saveAuthTokens(
          accessToken: tokens.accessToken,
          client: tokens.client,
          expiry: tokens.expiry,
          tokenType: tokens.tokenType,
          uid: tokens.uid,
        );
      } else if (tokens.accessToken.isNotEmpty) {
        await _storage.saveAuthTokens(
          accessToken: tokens.accessToken,
          client: tokens.client,
          expiry: tokens.expiry,
          tokenType: tokens.tokenType,
          uid: userModel.email,
        );
      }

      await _storage.saveUserId(userModel.id);
      await _storage.saveUserName(userModel.name);
      return userModel;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Login with email and password, and persist tokens/cookies returned from server.
  Future<UserModel> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }

      // Extract tokens from response headers or JSON body
      final tokens = AuthTokens.fromResponse(
        headers: response.headers,
        data: response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : null,
      );

      final dataMap = response.data is Map ? response.data as Map : {};
      final innerData = dataMap['data'] is Map ? dataMap['data'] as Map : dataMap;
      final userData = innerData['admin'] ?? innerData['user'] ?? innerData;
      final userModel = UserModel.fromJson(userData as Map<String, dynamic>);

      if (tokens.isValid) {
        await _storage.saveAuthTokens(
          accessToken: tokens.accessToken,
          client: tokens.client,
          expiry: tokens.expiry,
          tokenType: tokens.tokenType,
          uid: tokens.uid,
        );
      } else if (tokens.accessToken.isNotEmpty) {
        await _storage.saveAuthTokens(
          accessToken: tokens.accessToken,
          client: tokens.client,
          expiry: tokens.expiry,
          tokenType: tokens.tokenType,
          uid: userModel.email.isNotEmpty ? userModel.email : request.email,
        );
      }

      await _storage.saveUserId(userModel.id);
      await _storage.saveUserName(userModel.name);
      return userModel;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Fetch the list of nodes this admin has access to by calling /my_nodes.
  /// Called right after login — no Node-Admin-Id header is needed yet.
  Future<List<NodeModel>> getAccessibleNodes() async {
    try {
      final response = await _dio.get(ApiEndpoints.myNodes);
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      if (response.data is Map<String, dynamic>) {
        final dataList = response.data['data'] as List<dynamic>? ?? [];
        return dataList
            .map((e) => NodeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (_) {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch splash/dashboard data after a node has been selected.
  /// The Node-Admin-Id header is automatically added by the Dio interceptor.
  Future<SplashData> getSplashData() async {
    try {
      final response = await _dio.get(ApiEndpoints.splashScreen);
      if (response.data is Map && response.data['status'] == 'failure') {
        throw ApiException.fromResponseData(response.data, response.statusCode);
      }
      final data = (response.data['data'] ?? {}) as Map<String, dynamic>;
      return SplashData.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Persist the selected node.
  Future<void> saveNode(String nodeId, {String? nodeAdminId}) async {
    await _storage.saveNodeId(nodeId);
    if (nodeAdminId != null && nodeAdminId.isNotEmpty) {
      await _storage.saveNodeAdminId(nodeAdminId);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore network errors during logout
    } finally {
      await _storage.clearAll();
    }
  }

  Future<bool> isLoggedIn() => _storage.isLoggedIn();

  Future<({UserModel? user, NodeModel? node})> restoreSession() async {
    final token =
        await _storage.getAccessToken() ?? await _storage.getAuthToken();
    if (token == null) return (user: null, node: null);

    final userId = await _storage.getUserId() ?? await _storage.getUid();
    final userName = await _storage.getUserName();
    final nodeId = await _storage.getNodeId();
    final nodeAdminId = await _storage.getNodeAdminId();

    if (userId == null) return (user: null, node: null);

    final user = UserModel(
      id: userId,
      name: userName ?? 'User',
      email: userId,
      role: 'Node Admin',
      nodeId: nodeId ?? '',
    );

    // nodeId may be null if user logged in but never selected a node
    NodeModel? node;
    if (nodeId != null) {
      node = NodeModel(
        id: nodeId,
        nodeAdminId: nodeAdminId ?? '',
        name: 'Selected Node ($nodeId)',
        code: 'active',
        location: '',
      );
    }

    return (user: user, node: node);
  }
}
