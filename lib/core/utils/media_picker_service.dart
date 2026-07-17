import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class MediaSelection {
  final String path;
  final String name;

  MediaSelection({required this.path, required this.name});
}

class MediaPickerService {
  static Future<MediaSelection?> showMediaPicker(BuildContext context) async {
    return await showModalBottomSheet<MediaSelection>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return const _MediaPickerBottomSheet();
      },
    );
  }
}

class _MediaPickerBottomSheet extends StatefulWidget {
  const _MediaPickerBottomSheet({Key? key}) : super(key: key);

  @override
  State<_MediaPickerBottomSheet> createState() =>
      _MediaPickerBottomSheetState();
}

class _MediaPickerBottomSheetState extends State<_MediaPickerBottomSheet> {
  bool _isProcessing = false;

  Future<void> _pickFromFileSystem(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: false,
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null) {
        if (!mounted) return;
        Navigator.pop(
          context,
          MediaSelection(
            path: result.files.single.path!,
            name: result.files.single.name,
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _takePhoto(BuildContext context) async {
    final picker = ImagePicker();
    List<XFile> capturedImages = [];
    bool captureMore = true;

    while (captureMore) {
      final photo = await picker.pickImage(source: ImageSource.camera);
      if (photo == null) {
        captureMore = false;
        break;
      }

      capturedImages.add(photo);

      if (!mounted) return;

      // Ask user if they want to capture another page or finish
      final bool? continueCapture = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text("Photo Captured", style: AppTextStyles.headingMedium),
          content: Text(
            "Do you want to capture another page to include in this document?",
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(
                "Finish",
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(
                "Capture Another",
                style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      captureMore = continueCapture ?? false;
    }

    if (capturedImages.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    try {
      if (capturedImages.length == 1) {
        // Return single image directly
        final singleImage = capturedImages.first;
        if (mounted) {
          Navigator.pop(
            context,
            MediaSelection(path: singleImage.path, name: singleImage.name),
          );
        }
      } else {
        // Multiple images, convert to PDF
        final pdf = pw.Document();
        for (final img in capturedImages) {
          final imageBytes = await img.readAsBytes();

          // Compress the image before adding to PDF
          final compressedBytes = await FlutterImageCompress.compressWithList(
            imageBytes,
            minWidth: 1080,
            minHeight: 1080,
            quality: 70,
          );

          final pdfImage = pw.MemoryImage(compressedBytes);
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.zero,
              build: (pw.Context ctx) {
                return pw.Center(
                  child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
                );
              },
            ),
          );
        }

        final dir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'scan_$timestamp.pdf';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(await pdf.save());

        if (mounted) {
          Navigator.pop(
            context,
            MediaSelection(path: file.path, name: fileName),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                "Processing images...",
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Upload Media", style: AppTextStyles.headingLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.folder_outlined,
                color: AppColors.primary,
              ),
            ),
            title: Text("Pick from Files", style: AppTextStyles.labelMedium),
            subtitle: Text(
              "Upload a photo or PDF from your device",
              style: AppTextStyles.bodySmall,
            ),
            onTap: () => _pickFromFileSystem(context),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
            ),
            title: Text("Take Photo", style: AppTextStyles.labelMedium),
            subtitle: Text(
              "Use camera to capture documents",
              style: AppTextStyles.bodySmall,
            ),
            onTap: () => _takePhoto(context),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
