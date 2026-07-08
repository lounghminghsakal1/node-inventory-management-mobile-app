import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import '../network/dio_client.dart';

export '../network/dio_client.dart'
    show dioProvider, secureStorageProvider, authLogoutSignal;

final secureStorageWrapperProvider = Provider<SecureStorage>((ref) {
  final raw = ref.read(secureStorageProvider);
  return SecureStorage(raw);
});
