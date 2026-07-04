import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/placeholder_screen.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Inventory Audit',
        icon: Icons.fact_check_rounded,
        color: AppColors.accentGreen,
        description:
            'Perform inventory audits for your node. Count and verify stock levels. Coming soon.',
      );
}
