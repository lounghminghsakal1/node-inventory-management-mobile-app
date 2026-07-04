import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/auth/providers/auth_provider.dart';

/// A minimal, shared [AppBar] used across all in-app screens.
///
/// - **Title**: Displays the active node name. Tapping it navigates to
///   `/node-select` so the user can switch nodes.
/// - **Back button**: Shown automatically when `Navigator.canPop` is true,
///   or you can pass [showBack] = true to force it.
/// - **Actions**: Logout only.
class NodeOpsAppBar extends ConsumerWidget implements PreferredSizeWidget {
  /// Optional title to override the node name (e.g. for detail screens).
  final String? title;

  /// Force-show the back button (useful in sub-routes that use this bar).
  final bool showBack;

  /// Extra actions to prepend before logout (e.g. status badge in detail screens).
  final List<Widget> extraActions;

  const NodeOpsAppBar({
    super.key,
    this.title,
    this.showBack = false,
    this.extraActions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final nodeName = auth.node?.name ?? 'Select Node';
    final canPop = Navigator.of(context).canPop() || showBack;

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      // ── Leading: back button ─────────────────────────────────────────────
      leading: canPop
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
              onPressed: () => context.pop(),
              tooltip: 'Back',
            )
          : null,
      // ── Title: tappable node name ────────────────────────────────────────
      title: title != null
          ? Text(title!, style: AppTextStyles.headingMedium)
          : GestureDetector(
              onTap: () => context.push('/node-select?back=true'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        nodeName,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
      centerTitle: false,
      // ── Actions ──────────────────────────────────────────────────────────
      actions: [
        ...extraActions,
        IconButton(
          icon: const Icon(
            Icons.logout_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          tooltip: 'Logout',
          onPressed: () => _confirmLogout(context, ref),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.cardBorder),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Logout?', style: AppTextStyles.headingMedium),
        content: Text(
          'You will be returned to the login screen.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: Text('Logout',
                style:
                    AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
