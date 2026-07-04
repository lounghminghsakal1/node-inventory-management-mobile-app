import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import 'app_shell.dart';

/// Shared placeholder widget used by features not yet implemented.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  final bool showBack;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showBack
          ? NodeOpsAppBar(showBack: true, title: title)
          : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Icon(icon, size: 44, color: color),
                ),
              ),
              const SizedBox(height: 24),
              Text(title, style: AppTextStyles.headingXL),
              const SizedBox(height: 12),
              Text(
                description,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.construction_rounded, size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(
                      'Coming Soon',
                      style: AppTextStyles.labelMedium.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
