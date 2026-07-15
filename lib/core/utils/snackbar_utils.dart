import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart' as tsb;
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// Shows a success snackbar at the top of the screen.
void showTopSuccessSnackBar(BuildContext context, String message) {
  tsb.showTopSnackBar(
    Overlay.of(context),
    AppSnackBar.success(message: message),
    displayDuration: const Duration(seconds: 2),
  );
}

/// Shows an error snackbar at the top of the screen.
void showTopErrorSnackBar(BuildContext context, String message) {
  tsb.showTopSnackBar(
    Overlay.of(context),
    AppSnackBar.error(message: message),
    displayDuration: const Duration(seconds: 3),
  );
}

/// Shows a generic info snackbar at the top of the screen.
void showTopSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Color textColor = Colors.white,
  Duration duration = const Duration(seconds: 3),
  IconData? icon,
}) {
  tsb.showTopSnackBar(
    Overlay.of(context),
    AppSnackBar.info(
      message: message,
      backgroundColor: backgroundColor,
      icon: icon,
    ),
    displayDuration: duration,
  );
}

/// Shows a top snackbar using a navigator key — for use without a BuildContext
/// (e.g., from the global Dio interceptor).
void showTopSnackBarFromNavigatorKey(
  GlobalKey<NavigatorState> navigatorKey,
  String message, {
  bool isError = true,
}) {
  final overlay = navigatorKey.currentState?.overlay;
  if (overlay == null) return;
  tsb.showTopSnackBar(
    overlay,
    isError
        ? AppSnackBar.error(message: message)
        : AppSnackBar.info(message: message),
    displayDuration: const Duration(seconds: 4),
  );
}

/// A highly polished, professional-grade snackbar widget tailored for the app.
class AppSnackBar extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;

  const AppSnackBar({
    super.key,
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
  });

  factory AppSnackBar.success({required String message}) {
    return AppSnackBar(
      message: message,
      backgroundColor: const Color(0xFFE6F4EA), // Very light green
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
    );
  }

  factory AppSnackBar.error({required String message}) {
    return AppSnackBar(
      message: message,
      backgroundColor: const Color(0xFFFDE8E8), // Very light red
      icon: Icons.error_rounded,
      iconColor: AppColors.error,
    );
  }

  factory AppSnackBar.info({
    required String message,
    Color? backgroundColor,
    IconData? icon,
  }) {
    return AppSnackBar(
      message: message,
      backgroundColor: backgroundColor ?? const Color(0xFFE0F2FE), // Very light blue
      icon: icon ?? Icons.info_rounded,
      iconColor: AppColors.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    decoration: TextDecoration.none, // Explicitly remove underline
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
