import 'package:dio/dio.dart' show Dio;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';

class AuthRepository {
  // ignore: unused_field
  final Dio _dio;
  final SecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  /// Simulate login — replace body with real API call when backend is ready.
  Future<UserModel> login(LoginRequest request) async {
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

    // ── Real API call (uncomment when backend ready) ───────────────────────
    // final response = await _dio.post(
    //   ApiEndpoints.login,
    //   data: request.toJson(),
    // );
    // final data = response.data as Map<String, dynamic>;
    // await _storage.saveAuthToken(data['token'] as String);
    // return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Fetch the list of nodes this user has access to.
  /// Replace the mock with a real API call when backend is ready.
  Future<List<NodeModel>> getAccessibleNodes() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 900));

    // ── Mock response ──────────────────────────────────────────────────────
    return NodeModel.dummyNodes;

    // ── Real API call (uncomment when backend ready) ───────────────────────
    // final response = await _dio.get(ApiEndpoints.nodes);
    // final list = response.data as List<dynamic>;
    // return list.map((e) => NodeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Persist the selected node.
  Future<void> saveNode(String nodeId) => _storage.saveNodeId(nodeId);

  Future<void> logout() async {
    await _storage.clearAll();
  }

  Future<bool> isLoggedIn() => _storage.isLoggedIn();

  Future<({UserModel? user, NodeModel? node})> restoreSession() async {
    final token = await _storage.getAuthToken();
    if (token == null) return (user: null, node: null);

    final userId = await _storage.getUserId();
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
