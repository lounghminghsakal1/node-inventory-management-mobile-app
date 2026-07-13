import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/media_picker_service.dart';
import '../../data/repositories/shipment_repository.dart';
import '../../providers/shipment_provider.dart';

class _KeyValuePair {
  final keyCtrl = TextEditingController();
  final valCtrl = TextEditingController();
  void dispose() {
    keyCtrl.dispose();
    valCtrl.dispose();
  }
}

class _MediaItem {
  final String url;
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();

  _MediaItem(this.url);

  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
  }
}

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
  final _distanceCtrl = TextEditingController();
  final List<_KeyValuePair> _additionalRows = [];
  bool _isLoading = false;
  final List<_MediaItem> _uploadedMedia = [];
  bool _isUploadingMedia = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleCtrl.dispose();
    _distanceCtrl.dispose();
    for (final row in _additionalRows) {
      row.dispose();
    }
    for (final media in _uploadedMedia) {
      media.dispose();
    }
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
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                border: const Border(
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
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(10),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
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
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return newValue.copyWith(text: newValue.text.toUpperCase());
                        }),
                      ],
                      validator: (v) => v == null || v.isEmpty
                          ? 'Vehicle number is required'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Distance (in km/meters)',
                      hint: 'e.g. 1000',
                      controller: _distanceCtrl,
                      prefixIcon: Icons.add_road_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Distance is required'
                          : null,
                    ),
                    const SizedBox(height: 28),

                    // Additional Details Section
                    Text(
                      'Additional Details (Optional)',
                      style: AppTextStyles.headingMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add any extra key-value information for this dispatch',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),

                    ..._additionalRows.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final row = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Key ${idx + 1}',
                                hint: 'e.g. key ${idx + 1}',
                                controller: row.keyCtrl,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppTextField(
                                label: 'Value ${idx + 1}',
                                hint: 'e.g. value ${idx + 1}',
                                controller: row.valCtrl,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                              ),
                              onPressed: () {
                                setState(() {
                                  row.dispose();
                                  _additionalRows.removeAt(idx);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _additionalRows.add(_KeyValuePair());
                        });
                      },
                      icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                      label: const Text(
                        'Add one more row',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Media Upload Section
                    Text(
                      'Dispatch Media (Required)',
                      style: AppTextStyles.headingMedium,
                    ),
                    const SizedBox(height: 14),
                    ..._uploadedMedia.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final media = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.success),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Media ${idx + 1} uploaded successfully!',
                                    style: AppTextStyles.labelMedium,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                  onPressed: () {
                                    setState(() {
                                      media.dispose();
                                      _uploadedMedia.removeAt(idx);
                                    });
                                  },
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              label: 'Media Title',
                              hint: 'e.g. Truck loaded image',
                              controller: media.titleCtrl,
                              validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              label: 'Media Description (Optional)',
                              hint: 'e.g. Back view of the truck',
                              controller: media.descCtrl,
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_isUploadingMedia)
                      const Center(child: CircularProgressIndicator())
                    else
                      OutlinedButton.icon(
                        onPressed: _pickAndUploadFile,
                        icon: const Icon(Icons.upload_file, color: AppColors.primary),
                        label: Text(
                          _uploadedMedia.isEmpty ? 'Upload Media (Image/PDF)' : 'Upload Another Media',
                          style: const TextStyle(color: AppColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
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

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await MediaPickerService.showMediaPicker(context);
      if (result != null) {
        setState(() => _isUploadingMedia = true);
        final filePath = result.path;
        final fileName = result.name;
        final url = await ref.read(shipmentRepositoryProvider).uploadMedia(
          shipmentId: widget.shipmentId,
          actionType: 'dispatch',
          filePath: filePath,
          fileName: fileName,
        );
        setState(() {
          _uploadedMedia.add(_MediaItem(url));
          _isUploadingMedia = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Media upload failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _dispatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one media to proceed with dispatch.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final detailsMap = <String, dynamic>{
        "driver_name": _nameCtrl.text.trim(),
        "driver_number": _phoneCtrl.text.trim(),
        "vehicle_number": _vehicleCtrl.text.trim(),
        "distance": _distanceCtrl.text.trim(),
        "images": _uploadedMedia.map((m) => {
          "title": m.titleCtrl.text.trim(),
          if (m.descCtrl.text.trim().isNotEmpty) "description": m.descCtrl.text.trim(),
          "image_url": m.url,
        }).toList(),
      };
      for (final row in _additionalRows) {
        final k = row.keyCtrl.text.trim();
        final v = row.valCtrl.text.trim();
        if (k.isNotEmpty && v.isNotEmpty) {
          detailsMap[k] = v;
        }
      }
      final payload = <String, dynamic>{
        "shipment_dispatch_details": detailsMap,
      };

      await ref
          .read(shipmentRepositoryProvider)
          .markDispatched(shipmentId: widget.shipmentId, payload: payload);

      if (mounted) {
        ref.invalidate(shipmentByIdProvider(widget.shipmentId));
        ref.invalidate(shipmentListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipment marked as dispatched successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(); // back to detail
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
