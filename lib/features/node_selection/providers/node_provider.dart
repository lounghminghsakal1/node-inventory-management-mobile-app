import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';

/// Fetches accessible nodes from the repository.
final nodeListProvider = FutureProvider<List<NodeModel>>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.getAccessibleNodes();
});
