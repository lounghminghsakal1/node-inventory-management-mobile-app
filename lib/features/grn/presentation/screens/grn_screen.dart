import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/placeholder_screen.dart';

class GrnScreen extends StatelessWidget {
  const GrnScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'GRN',
        icon: Icons.inventory_2_rounded,
        color: AppColors.secondary,
        description:
            'Goods Receipt Note — Initiate PO-based GRN with batch/serial/untracked inwarding. Coming soon.',
      );
}
