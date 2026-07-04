import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/shipment.dart';
import '../../providers/shipment_provider.dart';

class DispatchScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const DispatchScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends ConsumerState<DispatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NodeOpsAppBar(
        showBack: true,
        title: 'Dispatch Shipment',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header illustration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F1427), Color(0xFF1A2040)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(
                    bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.local_shipping_rounded,
                          size: 36, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Ready to Dispatch', style: AppTextStyles.headingLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Enter driver details to dispatch this shipment',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Driver Information',
                        style: AppTextStyles.headingMedium),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Driver Name',
                      hint: 'e.g. Ravi Kumar',
                      controller: _nameCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Driver name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Phone Number',
                      hint: 'e.g. 9876543210',
                      controller: _phoneCtrl,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Phone is required';
                        if (v.length < 10) return 'Enter a valid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Vehicle Number',
                      hint: 'e.g. TN 09 AB 1234',
                      controller: _vehicleCtrl,
                      prefixIcon: Icons.directions_car_outlined,
                      textInputAction: TextInputAction.done,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Vehicle number is required'
                          : null,
                    ),
                    const SizedBox(height: 28),

                    // Info box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Once dispatched, the status cannot be reversed. Ensure all details are correct.',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SafeArea(
                      top: false,
                      child: AppButton(
                        label: 'Dispatch Shipment',
                        icon: Icons.local_shipping_rounded,
                        isLoading: _isLoading,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                        ),
                        onPressed: _dispatch,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dispatch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(shipmentListProvider.notifier).dispatch(
            widget.shipmentId,
            DriverDetails(
              name: _nameCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              vehicleNumber: _vehicleCtrl.text.trim().toUpperCase(),
            ),
          );
      if (mounted) {
        context.pop(); // back to detail
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
