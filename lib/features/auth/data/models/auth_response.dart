import 'package:dio/dio.dart' show Headers;

// ── Auth Tokens (WhatsApp Login / Token Auth) ─────────────────────────────────
class AuthTokens {
  final String accessToken;
  final String client;
  final String expiry;
  final String tokenType;
  final String uid;

  const AuthTokens({
    required this.accessToken,
    required this.client,
    required this.expiry,
    required this.tokenType,
    required this.uid,
  });

  /// Try extracting from HTTP response headers first, then fallback to JSON body map.
  factory AuthTokens.fromResponse({required Headers headers, Map<String, dynamic>? data}) {
    String? getVal(String key) {
      final fromHeader = headers.value(key);
      if (fromHeader != null && fromHeader.isNotEmpty) return fromHeader;
      if (data != null && data[key] != null) return data[key].toString();
      if (data != null && data['tokens'] is Map && data['tokens'][key] != null) {
        return data['tokens'][key].toString();
      }
      if (data != null && data['data'] is Map) {
        final d = data['data'] as Map;
        if (d['tokens'] is Map && d['tokens'][key] != null) {
          return d['tokens'][key].toString();
        }
        if (d[key] != null) return d[key].toString();
      }
      if (data != null && data['headers'] is Map && data['headers'][key] != null) {
        return data['headers'][key].toString();
      }
      return null;
    }

    return AuthTokens(
      accessToken: getVal('access-token') ?? getVal('accessToken') ?? '',
      client: getVal('client') ?? '',
      expiry: getVal('expiry') ?? '',
      tokenType: getVal('token-type') ?? getVal('tokenType') ?? 'Bearer',
      uid: getVal('uid') ?? '',
    );
  }

  bool get isValid => accessToken.isNotEmpty && uid.isNotEmpty;
}

// ── Node ──────────────────────────────────────────────────────────────────────
class NodeModel {
  final String id;
  final String nodeAdminId;
  final String name;
  final String code;
  final String location;
  final String status;

  const NodeModel({
    required this.id,
    this.nodeAdminId = '',
    required this.name,
    required this.code,
    required this.location,
    this.status = 'active',
  });

  factory NodeModel.fromJson(Map<String, dynamic> json) => NodeModel(
        id: (json['node_id'] ?? json['id'] ?? '').toString(),
        nodeAdminId: (json['id'] ?? json['node_admin_id'] ?? '').toString(),
        name: (json['node_name'] ?? json['name'] ?? '').toString(),
        code: (json['node_type'] ?? json['code'] ?? '').toString(),
        location: (json['location'] ?? json['status'] ?? '').toString(),
        status: (json['status'] ?? 'active').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'node_admin_id': nodeAdminId,
        'name': name,
        'code': code,
        'location': location,
        'status': status,
      };

  // ── Dummy nodes ─────────────────────────────────────────────────────────────
  static const List<NodeModel> dummyNodes = [
    NodeModel(id: '1', name: 'Warehouse Alpha', code: 'WH-A', location: 'Chennai'),
    NodeModel(id: '2', name: 'Warehouse Beta', code: 'WH-B', location: 'Bangalore'),
    NodeModel(id: '3', name: 'Distribution Hub', code: 'DH-1', location: 'Mumbai'),
    NodeModel(id: '4', name: 'Retail Store North', code: 'RS-N', location: 'Delhi'),
  ];
}

// ── User ──────────────────────────────────────────────────────────────────────
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String nodeId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.nodeId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? json['user_name'] ?? 'User').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? 'Node Admin').toString(),
        nodeId: (json['nodeId'] ?? json['node_id'] ?? '').toString(),
      );

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
