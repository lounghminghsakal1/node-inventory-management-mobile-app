class AppConstants {
  AppConstants._();

  static const String appName = 'NodeOps';
  static const String appVersion = '1.0.0';

  // Secure storage keys
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyAccessToken = 'access_token';
  static const String keyClient = 'client';
  static const String keyExpiry = 'expiry';
  static const String keyTokenType = 'token_type';
  static const String keyUid = 'uid';
  static const String keyCookie = 'cookie';
  static const String keySelectedNodeId = 'selected_node_id';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';

  // Dummy credentials
  static const String dummyUsername = 'admin';
  static const String dummyPassword = 'password123';
  static const String dummyMobile = '9876543210';
  static const String dummyOtp = '123456';
  static const String dummyToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy';
  static const String dummyClient = 'dummy_client_id_12345';
  static const String dummyExpiry = '1893456000';
  static const String dummyTokenType = 'Bearer';

  // Tracking types
  static const String trackingBatch = 'batch';
  static const String trackingSerial = 'serial';
  static const String trackingUntracked = 'untracked';

  // Shipment statuses
  static const String statusCreated = 'created';
  static const String statusAllocated = 'allocated';
  static const String statusInvoiced = 'invoiced';
  static const String statusDispatched = 'dispatched';
  static const String statusDelivered = 'delivered';
  static const String statusReturnInitiated = 'return_initiated';
  static const String statusReturnCompleted = 'return_completed';

  // UI
  static const double borderRadius = 12.0;
  static const double borderRadiusLarge = 20.0;
  static const double cardPadding = 16.0;
  static const double screenPadding = 20.0;
}
