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
import 'package:node_management_app/core/utils/snackbar_utils.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../home/providers/home_provider.dart';

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
  final Map<String, List<String>> _lineItemPhotos = {};
  final Map<String, bool> _isUploadingLineItemPhoto = {};

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
    final asyncShipment = ref.watch(shipmentByIdProvider(widget.shipmentId));
    final shipment = asyncShipment.valueOrNull;
    final splash = ref.watch(splashDataProvider).valueOrNull;
    final bool isLineItemLevelPhotoEnabled = splash?.captureShipmentLineItemPhotos ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const NodeOpsAppBar(showBack: true, title: 'Dispatch Shipment'),
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
                  bottom: BorderSide(color: AppColors.cardBorder),
                ),
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
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_shipping_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
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
                    if (isLineItemLevelPhotoEnabled &&
                        shipment != null &&
                        shipment.lineItems.isNotEmpty) ...[
                      Text(
                        'Line Items Photos (Required)',
                        style: AppTextStyles.headingMedium,
                      ),
                      const SizedBox(height: 16),
                      ...shipment.lineItems.map((item) {
                        final photos = _lineItemPhotos[item.id] ?? [];
                        final isUploading =
                            _isUploadingLineItemPhoto[item.id] ?? false;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: AppTextStyles.labelLarge,
                                    ),
                                    if (item.product.sku.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'SKU: ${item.product.sku}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (photos.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => _showLineItemImagePopup(context, item.product.name, photos.first),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.remove_red_eye_outlined, color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _lineItemPhotos[item.id]!.clear();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.delete_outline, color: AppColors.error),
                                      ),
                                    ),
                                  ],
                                )
                              else if (isUploading)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                )
                              else
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _pickAndUploadLineItemFile(item.id),
                                  icon: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    'Add',
                                    style: TextStyle(color: AppColors.primary),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 28),
                    ],

                    Text(
                      'Driver Information',
                      style: AppTextStyles.headingMedium,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Driver Name * ',
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
                      label: 'Phone Number * ',
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
                      label: 'Vehicle Number * ',
                      hint: 'e.g. TN 09 AB 1234',
                      controller: _vehicleCtrl,
                      prefixIcon: Icons.directions_car_outlined,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [VehicleNumberFormatter()],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vehicle number is required';
                        }

                        final value = v.trim().toUpperCase();

                        final normalReg = RegExp(
                          r'^[A-Z]{2}\s?\d{2}\s?[A-Z]{1,2}\s?\d{4}$',
                        );

                        final bhReg = RegExp(
                          r'^\d{2}\s?BH\s?\d{4}\s?[A-Z]{2}$',
                        );

                        if (!normalReg.hasMatch(value) &&
                            !bhReg.hasMatch(value)) {
                          return 'Enter a valid vehicle number';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Distance (in km/meters) *',
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
                      icon: const Icon(
                        Icons.add_rounded,
                        color: AppColors.primary,
                      ),
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
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Media ${idx + 1} uploaded successfully!',
                                    style: AppTextStyles.labelMedium,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      media.dispose();
                                      _uploadedMedia.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              label: 'Media Title * ',
                              hint: 'e.g. Truck loaded image',
                              controller: media.titleCtrl,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Title is required'
                                  : null,
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
                        icon: const Icon(
                          Icons.upload_file,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          _uploadedMedia.isEmpty
                              ? 'Upload Media (Image/PDF)'
                              : 'Upload Another Media',
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
                          color: AppColors.warning.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Once dispatched, the status cannot be reversed. Ensure all details are correct.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.warning,
                              ),
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
                        isLoading: _isLoading || _isUploadingMedia,
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

  Future<void> _pickAndUploadLineItemFile(String itemId) async {
    try {
      final result = await MediaPickerService.showMediaPicker(context);
      if (result != null) {
        setState(() => _isUploadingLineItemPhoto[itemId] = true);
        final filePath = result.path;
        final fileName = result.name;
        final url = await ref
            .read(shipmentRepositoryProvider)
            .uploadMedia(
              shipmentId: widget.shipmentId,
              actionType: 'dispatch',
              filePath: filePath,
              fileName: fileName,
            );
        setState(() {
          _lineItemPhotos[itemId] = [...(_lineItemPhotos[itemId] ?? []), url];
          _isUploadingLineItemPhoto[itemId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingLineItemPhoto[itemId] = false);
        showTopErrorSnackBar(context, 'Media upload failed: ${e.toString()}');
      }
    }
  }

  void _showLineItemImagePopup(BuildContext context, String title, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.headingSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: url.toLowerCase().endsWith('.pdf')
                    ? SizedBox(
                        height: 400,
                        width: double.infinity,
                        child: SfPdfViewer.network(
                          url,
                          canShowScrollHead: false,
                          canShowScrollStatus: false,
                        ),
                      )
                    : Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Unable to preview this file type.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
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
        final url = await ref
            .read(shipmentRepositoryProvider)
            .uploadMedia(
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
        showTopErrorSnackBar(context, 'Media upload failed: ${e.toString()}');
      }
    }
  }

  Future<void> _dispatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uploadedMedia.isEmpty) {
      showTopErrorSnackBar(
        context,
        'Please upload at least one media to proceed with dispatch.',
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
        "images": _uploadedMedia
            .map(
              (m) => {
                "title": m.titleCtrl.text.trim(),
                if (m.descCtrl.text.trim().isNotEmpty)
                  "description": m.descCtrl.text.trim(),
                "image_url": m.url,
              },
            )
            .toList(),
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

      final splash = ref.read(splashDataProvider).valueOrNull;
      final bool isLineItemLevelPhotoEnabled = splash?.captureShipmentLineItemPhotos ?? false;
      if (isLineItemLevelPhotoEnabled && _lineItemPhotos.isNotEmpty) {
        final lineItemsPayload = _lineItemPhotos.entries
            .where((e) => e.value.isNotEmpty)
            .map(
              (e) => {
                "id": int.tryParse(e.key) ?? e.key,
                "photo_urls": e.value,
              },
            )
            .toList();
        if (lineItemsPayload.isNotEmpty) {
          payload["shipment_line_items"] = lineItemsPayload;
        }
      }

      await ref
          .read(shipmentRepositoryProvider)
          .markDispatched(shipmentId: widget.shipmentId, payload: payload);

      if (mounted) {
        ref.invalidate(shipmentByIdProvider(widget.shipmentId));
        ref.invalidate(shipmentListProvider);
        showTopSuccessSnackBar(
          context,
          'Shipment marked as dispatched successfully!',
        );
        context.pop(); // back to detail
      }
    } catch (e) {
      if (mounted) {
        showTopErrorSnackBar(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class VehicleNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove spaces and convert to uppercase
    String text = newValue.text.replaceAll(RegExp(r'\s+'), '').toUpperCase();

    // Maximum possible length:
    // TN09AB1234 -> 10
    // 21BH1234AA -> 10
    if (text.length > 10) {
      return oldValue;
    }

    // Allow only letters and digits
    if (!RegExp(r'^[A-Z0-9]*$').hasMatch(text)) {
      return oldValue;
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
