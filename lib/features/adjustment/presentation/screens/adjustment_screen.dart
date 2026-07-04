import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/placeholder_screen.dart';

class AdjustmentScreen extends StatelessWidget {
  const AdjustmentScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Adjustment',
        icon: Icons.tune_rounded,
        color: AppColors.accent,
        description:
            'Adjust inventory quantities at your node — add or remove stock with reason codes. Coming soon.',
        showBack: true,
      );
}
