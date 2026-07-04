// ── Node ──────────────────────────────────────────────────────────────────────
class NodeModel {
  final String id;
  final String name;
  final String code;
  final String location;

  const NodeModel({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
  });

  factory NodeModel.fromJson(Map<String, dynamic> json) => NodeModel(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        location: json['location'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'location': location,
      };

  // ── Dummy nodes ─────────────────────────────────────────────────────────────
  static const List<NodeModel> dummyNodes = [
    NodeModel(id: 'node_1', name: 'Warehouse Alpha', code: 'WH-A', location: 'Chennai'),
    NodeModel(id: 'node_2', name: 'Warehouse Beta', code: 'WH-B', location: 'Bangalore'),
    NodeModel(id: 'node_3', name: 'Distribution Hub', code: 'DH-1', location: 'Mumbai'),
    NodeModel(id: 'node_4', name: 'Retail Store North', code: 'RS-N', location: 'Delhi'),
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
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        nodeId: json['nodeId'] as String,
      );

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
