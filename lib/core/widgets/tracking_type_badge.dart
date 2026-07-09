import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class TrackingTypeBadge extends StatelessWidget {
  final String trackingType;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const TrackingTypeBadge({
    super.key,
    required this.trackingType,
    this.fontSize = 10.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    final type = trackingType.trim().toLowerCase();

    final Color bg = AppColors.getTrackingBgColor(type);
    final Color text = AppColors.getTrackingTextColor(type);

    String label = 'UNTRACKED';
    if (type == 'batch' || type.contains('batch')) {
      label = 'BATCH';
    } else if (type == 'serial' || type.contains('serial')) {
      label = 'SERIAL';
    } else if (type.isNotEmpty && type != 'none' && type != 'untracked') {
      label = trackingType.toUpperCase();
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withValues(alpha: 0.25), width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: text,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
