import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/dashboard_stats.dart';

final splashDataProvider = FutureProvider<SplashData>((ref) async {
  ref.watch(authProvider.select((s) => s.node?.id));
  final authRepo = ref.read(authRepositoryProvider);
  return await authRepo.getSplashData();
});

final nodeStatsProvider = FutureProvider<NodeStats>((ref) async {
  ref.watch(authProvider.select((s) => s.node?.id));
  final authRepo = ref.read(authRepositoryProvider);
  return await authRepo.getNodeStats();
});
