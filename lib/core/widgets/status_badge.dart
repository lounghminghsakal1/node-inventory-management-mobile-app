import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool large;

  const StatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    final fontSize = large ? 12.0 : 10.0;
    final hPad = large ? 10.0 : 8.0;
    final vPad = large ? 5.0 : 3.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: config.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: config.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getConfig(String status) {
    switch (status) {
      case AppConstants.statusCreated:
        return _StatusConfig(AppColors.statusCreated, 'Created');
      case AppConstants.statusAllocated:
        return _StatusConfig(AppColors.statusAllocated, 'Allocated');
      case AppConstants.statusInvoiced:
        return _StatusConfig(AppColors.statusInvoiced, 'Invoiced');
      case AppConstants.statusDispatched:
        return _StatusConfig(AppColors.statusDispatched, 'Dispatched');
      case AppConstants.statusDelivered:
        return _StatusConfig(AppColors.statusDelivered, 'Delivered');
      case AppConstants.statusReturnInitiated:
        return _StatusConfig(AppColors.statusReturnInitiated, 'Return Initiated');
      case AppConstants.statusReturnCompleted:
        return _StatusConfig(AppColors.statusReturnCompleted, 'Return Completed');
      default:
        return _StatusConfig(AppColors.textMuted, status);
    }
  }
}

class _StatusConfig {
  final Color color;
  final String label;
  const _StatusConfig(this.color, this.label);
}
