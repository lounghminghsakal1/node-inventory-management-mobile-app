import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../purchase_orders/providers/purchase_order_provider.dart';

class CreateGrnScreen extends ConsumerStatefulWidget {
  final int poId;
  final String poNumber;

  const CreateGrnScreen({
    super.key,
    required this.poId,
    required this.poNumber,
  });

  @override
  ConsumerState<CreateGrnScreen> createState() => _CreateGrnScreenState();
}

class _CreateGrnScreenState extends ConsumerState<CreateGrnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNoController = TextEditingController();
  
  String? _invoiceDate;
  String? _receivedDate;
  String? _uploadedFileName;
  String? _uploadedFileUrl;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _receivedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _invoiceNoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isInvoiceDate) async {
    final initial = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = formatted;
        } else {
          _receivedDate = formatted;
        }
      });
    }
  }

  void _simulateFileUpload() {
    setState(() {
      _uploadedFileName = "vendor_invoice_${widget.poId}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      _uploadedFileUrl = "https://s3.aws.com/flaer-invoices/$_uploadedFileName";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("File '$_uploadedFileName' uploaded successfully!"),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _handleCreateGrn() async {
    if (!_formKey.currentState!.validate()) return;
    if (_invoiceDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a Vendor Invoice Date"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final grn = await ref.read(grnControllerProvider.notifier).createGrn(
      poId: widget.poId,
      vendorInvoiceDate: _invoiceDate!,
      vendorInvoiceNo: _invoiceNoController.text.trim(),
      receivedDate: _receivedDate!,
      vendorInvoiceS3Url: _uploadedFileUrl,
    );

    if (grn != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("New GRN (${grn.grnNumber}) created successfully!"),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(grnControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: NodeOpsAppBar(
        showBack: true,
        title: "Create GRN (${widget.poNumber})",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Vendor Invoice Details",
                style: AppTextStyles.headingMedium.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter the invoice details provided by the vendor upon delivery.",
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: "Vendor Invoice Number *",
                hint: "e.g., INV-2026-8891",
                controller: _invoiceNoController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Invoice Number is required";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildDatePickerField(
                label: "Vendor Invoice Date *",
                value: _invoiceDate ?? "Select Date",
                isSelected: _invoiceDate != null,
                onTap: () => _selectDate(context, true),
              ),
              const SizedBox(height: 20),
              _buildDatePickerField(
                label: "Goods Received Date *",
                value: _receivedDate ?? "Select Date",
                isSelected: _receivedDate != null,
                onTap: () => _selectDate(context, false),
              ),
              const SizedBox(height: 24),
              Text(
                "Vendor Invoice Image / Document",
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              _buildUploadBox(),
              const SizedBox(height: 40),
              AppButton(
                label: "Create GRN",
                icon: Icons.add_circle_outline,
                isLoading: isLoading,
                onPressed: _handleCreateGrn,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: isSelected
                      ? AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)
                      : AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                ),
                const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadBox() {
    if (_uploadedFileName != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.success),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _uploadedFileName!,
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Uploaded successfully",
                    style: AppTextStyles.caption.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
              onPressed: () => setState(() {
                _uploadedFileName = null;
                _uploadedFileUrl = null;
              }),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _simulateFileUpload,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              "Click to upload Invoice Document",
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              "Supports PDF, PNG, JPG (Max 10MB)",
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
