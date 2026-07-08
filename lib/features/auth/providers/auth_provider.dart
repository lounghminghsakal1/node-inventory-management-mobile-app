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
enum AuthStatus {
  initial,
  checking,
  nodeRequired,
  authenticated,
  unauthenticated,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final NodeModel? node;
  final String? error;
  final bool isLoading;
  final bool otpSent;
  final String? mobileNumber;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.node,
    this.error,
    this.isLoading = false,
    this.otpSent = false,
    this.mobileNumber,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    NodeModel? node,
    String? error,
    bool? isLoading,
    bool? otpSent,
    String? mobileNumber,
    bool clearNode = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      node: clearNode ? null : (node ?? this.node),
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
      otpSent: otpSent ?? this.otpSent,
      mobileNumber: mobileNumber ?? this.mobileNumber,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _checkExistingSession();
    authLogoutSignal.addListener(forceUnauthenticated);
  }

  @override
  void dispose() {
    authLogoutSignal.removeListener(forceUnauthenticated);
    super.dispose();
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
        state = AuthState(status: AuthStatus.nodeRequired, user: session.user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Step 1: Send OTP via WhatsApp to mobile number.
  Future<bool> sendOtp(String mobileNumber) async {
    state = state.copyWith(isLoading: true, error: null, clearError: true);
    try {
      await _repo.sendWhatsAppOtp(SendOtpRequest(mobileNumber: mobileNumber));
      state = state.copyWith(
        isLoading: false,
        otpSent: true,
        mobileNumber: mobileNumber,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Step 2: Verify WhatsApp OTP and login.
  Future<bool> verifyOtp({required String otp}) async {
    state = state.copyWith(isLoading: true, error: null, clearError: true);
    try {
      final user = await _repo.verifyWhatsAppOtp(VerifyOtpRequest(otp: otp));
      state = AuthState(
        status: AuthStatus.nodeRequired,
        user: user,
        otpSent: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Go back to Step 1 (change phone number).
  void resetLoginStep() {
    state = state.copyWith(otpSent: false, error: null, clearError: true);
  }

  /// Login with email + password. Node selection follows separately.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null, clearError: true);
    try {
      final user = await _repo.login(
        LoginRequest(email: email, password: password),
      );
      state = AuthState(status: AuthStatus.nodeRequired, user: user);
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
    await _repo.saveNode(node.id, nodeAdminId: node.nodeAdminId);
    state = AuthState(
      status: AuthStatus.authenticated,
      user: state.user,
      node: node,
      otpSent: state.otpSent,
      mobileNumber: state.mobileNumber,
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void forceUnauthenticated() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
 