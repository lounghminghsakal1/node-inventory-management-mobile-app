import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/secure_storage.dart';
import '../data/models/auth_response.dart';
import '../data/models/login_request.dart';
import '../data/repositories/auth_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(dioProvider);
  final storage = SecureStorage(ref.read(secureStorageProvider));
  return AuthRepository(dio, storage);
});

// ── State ─────────────────────────────────────────────────────────────────────
enum AuthStatus { initial, checking, nodeRequired, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final NodeModel? node;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.node,
    this.error,
    this.isLoading = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    NodeModel? node,
    String? error,
    bool? isLoading,
    bool clearNode = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      node: clearNode ? null : (node ?? this.node),
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    state = state.copyWith(status: AuthStatus.checking, isLoading: true);
    try {
      final session = await _repo.restoreSession();
      if (session.user != null && session.node != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: session.user,
          node: session.node,
        );
      } else if (session.user != null) {
        // Has credentials but no node saved yet
        state = AuthState(
          status: AuthStatus.nodeRequired,
          user: session.user,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Login with username + password only. Node selection follows separately.
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.login(
        LoginRequest(username: username, password: password),
      );
      state = AuthState(
        status: AuthStatus.nodeRequired,
        user: user,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Called from the Node Selection screen after the user picks a node.
  Future<void> selectNode(NodeModel node) async {
    await _repo.saveNode(node.id);
    state = AuthState(
      status: AuthStatus.authenticated,
      user: state.user,
      node: node,
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
