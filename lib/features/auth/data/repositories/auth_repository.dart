import 'package:dio/dio.dart' show Dio, DioException;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/secure_storage.dart';
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

      print("jdfdsjj ${response.toString()}");
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

  /// Simulate login — replace body with real API call when backend is ready.
  Future<UserModel> login(LoginRequest request) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1200));

      // ── Dummy auth check ───────────────────────────────────────────────────
      if (request.username != AppConstants.dummyUsername ||
          request.password != AppConstants.dummyPassword) {
        throw Exception('Invalid username or password');
      }

      final user = UserModel(
        id: 'user_001',
        name: 'Arjun Sharma',
        email: '${request.username}@nodeops.com',
        role: 'Node Admin',
        nodeId: '',
      );

      // Persist session (node not yet selected)
      await _storage.saveAuthToken(AppConstants.dummyToken);
      await _storage.saveUserId(user.id);
      await _storage.saveUserName(user.name);

      return user;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Fetch the list of nodes this user has access to.
  /// Replace the mock with a real API call when backend is ready.
  Future<List<NodeModel>> getAccessibleNodes() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 900));

    // ── Mock response ──────────────────────────────────────────────────────
    return NodeModel.dummyNodes;
  }

  /// Persist the selected node.
  Future<void> saveNode(String nodeId) => _storage.saveNodeId(nodeId);

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isLoggedIn() => _storage.isLoggedIn();

  Future<({UserModel? user, NodeModel? node})> restoreSession() async {
    final token =
        await _storage.getAccessToken() ?? await _storage.getAuthToken();
    if (token == null) return (user: null, node: null);

    final userId = await _storage.getUserId() ?? await _storage.getUid();
    final userName = await _storage.getUserName();
    final nodeId = await _storage.getNodeId();

    if (userId == null) return (user: null, node: null);

    final user = UserModel(
      id: userId,
      name: userName ?? 'User',
      email: 'admin@nodeops.com',
      role: 'Node Admin',
      nodeId: nodeId ?? '',
    );

    // nodeId may be null if user logged in but never selected a node
    NodeModel? node;
    if (nodeId != null) {
      node = NodeModel.dummyNodes.firstWhere(
        (n) => n.id == nodeId,
        orElse: () => NodeModel.dummyNodes.first,
      );
    }

    return (user: user, node: node);
  }
}
