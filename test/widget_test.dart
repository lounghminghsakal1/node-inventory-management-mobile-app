import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:node_management_app/app/app.dart';
import 'package:node_management_app/core/providers/core_providers.dart';
import 'package:node_management_app/core/storage/secure_storage.dart';
import 'package:node_management_app/features/auth/data/models/auth_response.dart';
import 'package:node_management_app/features/auth/data/models/login_request.dart';
import 'package:node_management_app/features/auth/data/repositories/auth_repository.dart';
import 'package:node_management_app/features/auth/providers/auth_provider.dart';

class MockAuthRepository extends AuthRepository {
  MockAuthRepository(super.dio, super.storage);

  @override
  Future<bool> sendWhatsAppOtp(SendOtpRequest request) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  @override
  Future<UserModel> verifyWhatsAppOtp(VerifyOtpRequest request) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const UserModel(
      id: '3',
      name: 'Leoo',
      email: 'minghsakalloungh@gmail.com',
      role: 'Node Admin',
      nodeId: '',
    );
  }
}

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('App smoke test — renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => MockAuthRepository(
                ref.read(dioProvider),
                SecureStorage(ref.read(secureStorageProvider)),
              )),
        ],
        child: const NodeOpsApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    // App should render without throwing
    expect(tester.takeException(), isNull);
  });

  testWidgets('WhatsApp OTP login flow transitions from mobile input to OTP verification',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => MockAuthRepository(
                ref.read(dioProvider),
                SecureStorage(ref.read(secureStorageProvider)),
              )),
        ],
        child: const NodeOpsApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Step 1: Mobile number input is present
    expect(find.text('WhatsApp Login'), findsOneWidget);
    expect(find.text('Send OTP via WhatsApp'), findsOneWidget);

    // Enter phone number
    await tester.enterText(find.byType(TextFormField).first, '9876543210');
    await tester.tap(find.text('Send OTP via WhatsApp'));
    await tester.pump(); // trigger setState / loading
    await tester.pump(const Duration(milliseconds: 500)); // wait for mock sendWhatsAppOtp delay

    // Step 2: OTP verification input is present
    expect(find.text('Verify Code'), findsOneWidget);
    expect(find.text('Verify & Login'), findsOneWidget);
  });
}
