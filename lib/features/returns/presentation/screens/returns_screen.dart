import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/placeholder_screen.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Returns',
        icon: Icons.assignment_return_rounded,
        color: AppColors.warning,
        description:
            'Accept and process return/replacement shipments with or without inventory. Coming soon.',
      );
}
