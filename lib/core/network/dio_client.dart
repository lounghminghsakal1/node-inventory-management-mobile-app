import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../utils/snackbar_utils.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

export 'api_exception.dart';

class AuthLogoutSignal extends ChangeNotifier {
  void trigger() => notifyListeners();
}

final authLogoutSignal = AuthLogoutSignal();

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void _showGlobalErrorSnackBar(String message) {
  if (message.isEmpty) return;
  Future.microtask(() {
    showTopSnackBarFromNavigatorKey(
      rootNavigatorKey,
      message,
      isError: true,
    );
  });
}

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);
  return _buildDio(storage);
});

final secureStorageProvider = Provider<FlutterSecureStorage>((_) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

Dio _buildDio(FlutterSecureStorage storage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Auth token & platform header interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Attach platform header to every API request
        options.headers['platform'] = 'node_app';

        // Read all 5 auth token fields and cookie from secure storage
        final accessToken = await storage.read(
          key: AppConstants.keyAccessToken,
        );
        final client = await storage.read(key: AppConstants.keyClient);
        final expiry = await storage.read(key: AppConstants.keyExpiry);
        final tokenType = await storage.read(key: AppConstants.keyTokenType);
        final uid = await storage.read(key: AppConstants.keyUid);
        final cookie = await storage.read(key: AppConstants.keyCookie);

        if (cookie != null && cookie.isNotEmpty) {
          options.headers['cookie'] = cookie;
          options.headers['Cookie'] = cookie;
          debugPrint('Attached Cookie: $cookie');
        }

        if (accessToken != null) {
          options.headers['access-token'] = accessToken;
          // Maintain Authorization header for backwards compatibility
          options.headers['Authorization'] =
              '${tokenType ?? "Bearer"} $accessToken';
        }
        if (client != null) options.headers['client'] = client;
        if (expiry != null) options.headers['expiry'] = expiry;
        if (tokenType != null) options.headers['token-type'] = tokenType;
        if (uid != null) options.headers['uid'] = uid;

        // Fallback for legacy token if access_token is not set
        if (accessToken == null) {
          final legacyToken = await storage.read(
            key: AppConstants.keyAuthToken,
          );
          if (legacyToken != null) {
            options.headers['Authorization'] = 'Bearer $legacyToken';
          }
        }

        // Skip Node-Admin-Id for /my_nodes — user hasn't selected a node yet
        final isMyNodes = options.path.contains('/my_nodes');
        if (!isMyNodes) {
          final nodeAdminId =
              await storage.read(key: AppConstants.keyNodeAdminId) ??
              await storage.read(key: AppConstants.keyUserId);
          if (nodeAdminId != null && nodeAdminId.isNotEmpty) {
            options.headers['Node-Admin-Id'] = nodeAdminId;
          }
        }

        return handler.next(options);
      },
      onResponse: (response, handler) async {
        await _saveCookiesFromResponse(storage, response);
        if (response.data is Map) {
          final status = response.data['status']?.toString().toLowerCase();
          if (status == 'failure' || status == 'error') {
            final errorMsg =
                ApiException.extractErrorMessage(response.data) ??
                'Something went wrong';
            _showGlobalErrorSnackBar(errorMsg);
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                error: errorMsg,
                message: errorMsg,
              ),
            );
          }
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response != null) {
          await _saveCookiesFromResponse(storage, error.response!);
        }
        if (error.response?.statusCode == 401) {
          // Token expired / unauthorized / forbidden — clear all auth tokens and redirect to login
          await storage.delete(key: AppConstants.keyAccessToken);
          await storage.delete(key: AppConstants.keyClient);
          await storage.delete(key: AppConstants.keyExpiry);
          await storage.delete(key: AppConstants.keyTokenType);
          await storage.delete(key: AppConstants.keyUid);
          await storage.delete(key: AppConstants.keyAuthToken);
          await storage.delete(key: AppConstants.keyCookie);
          await storage.delete(key: AppConstants.keyNodeAdminId);
          await storage.delete(key: AppConstants.keyUserId);

          authLogoutSignal.trigger();
        }

        final extractedMsg =
            ApiException.extractErrorMessage(error.response?.data) ??
            error.message ??
            'Something went wrong';

        if (error.response?.data is Map) {
          final status = error.response!.data['status']
              ?.toString()
              .toLowerCase();
          if (status == 'failure' || status == 'error') {
            _showGlobalErrorSnackBar(extractedMsg);
          } else if (error.response?.data['message'] != null ||
              error.response?.data['error'] != null ||
              error.response?.data['errors'] != null) {
            _showGlobalErrorSnackBar(extractedMsg);
          }
        } else if (error.type == DioExceptionType.badResponse) {
          _showGlobalErrorSnackBar(extractedMsg);
        }

        final modifiedError = error.copyWith(
          error: extractedMsg,
          message: extractedMsg,
        );

        return handler.next(modifiedError);
      },
    ),
  );

  // Logging interceptor (debug only)
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => debugPrint(o.toString()),
    ),
  );

  return dio;
}

// ignore: avoid_print
void debugPrint(String msg) {
  // ignore: avoid_print
  print('[DIO] $msg');
}

Future<void> _saveCookiesFromResponse(
  FlutterSecureStorage storage,
  Response response,
) async {
  final List<String> rawCookies = [];

  // 1. Check response headers
  final headerCookies = response.headers['set-cookie'];
  if (headerCookies != null) {
    for (final c in headerCookies) {
      if (c.isNotEmpty) rawCookies.add(c);
    }
  }

  // 2. Check response body if it's a Map
  if (response.data is Map) {
    final data = response.data as Map;
    for (final key in ['cookie', 'cookies', 'set-cookie', 'Set-Cookie']) {
      final val = data[key];
      if (val is String && val.isNotEmpty) {
        rawCookies.add(val);
      } else if (val is List) {
        for (final item in val) {
          if (item is String && item.isNotEmpty) {
            rawCookies.add(item.toString());
          }
        }
      }
    }
    if (data['headers'] is Map) {
      final headersMap = data['headers'] as Map;
      for (final key in ['cookie', 'cookies', 'set-cookie', 'Set-Cookie']) {
        final val = headersMap[key];
        if (val is String && val.isNotEmpty) {
          rawCookies.add(val);
        } else if (val is List) {
          for (final item in val) {
            if (item is String && item.isNotEmpty) {
              rawCookies.add(item.toString());
            }
          }
        }
      }
    }
  }

  if (rawCookies.isEmpty) return;

  // Read existing stored cookie string and parse into map
  final existingCookieStr = await storage.read(key: AppConstants.keyCookie);
  final cookieMap = <String, String>{};
  if (existingCookieStr != null && existingCookieStr.isNotEmpty) {
    final parts = existingCookieStr.split(';');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty || !trimmed.contains('=')) continue;
      final idx = trimmed.indexOf('=');
      final name = trimmed.substring(0, idx).trim();
      final val = trimmed.substring(idx + 1).trim();
      if (name.isNotEmpty) {
        cookieMap[name] = val;
      }
    }
  }

  // Parse new cookies and update map
  for (final rawCookie in rawCookies) {
    final pairStr = rawCookie.split(';').first.trim();
    if (pairStr.isEmpty || !pairStr.contains('=')) continue;
    final idx = pairStr.indexOf('=');
    final name = pairStr.substring(0, idx).trim();
    final val = pairStr.substring(idx + 1).trim();
    if (name.isNotEmpty) {
      cookieMap[name] = val;
    }
  }

  if (cookieMap.isNotEmpty) {
    final updatedCookieStr = cookieMap.entries
        .map((e) => '${e.key}=${e.value}')
        .join('; ');
    await storage.write(key: AppConstants.keyCookie, value: updatedCookieStr);
    debugPrint('Saved/Updated Cookie: $updatedCookieStr');
  }
}
