import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds (White backgrounds & soft cool white) ──────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFF8FAFC);
  static const Color cardElevated = Color(0xFFF1F5F9);
  static const Color cardBorder = Color.fromARGB(255, 1, 82, 163); // Medium blue for outlines and borders

//  Color(0xFF60A5FA);
  // ── Brand Primary (Dark blue for important text & focus texts) ─────────────
  static const Color primary = Color(0xFF1E40AF);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF3B82F6);

  // ── Accent (Medium blue for animations & accents) ──────────────────────────
  static const Color secondary = Color(0xFF3B82F6);
  static const Color accent = Color(0xFF4F46E5);
  static const Color accentGreen = Color(0xFF10B981);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF3B82F6);

  // ── Text (Black or gray shades for text and other details) ─────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  // ── Shipment Status ────────────────────────────────────────────────────────
  static const Color statusCreated = Color(0xFF64748B);
  static const Color statusAllocated = Color(0xFF2563EB);
  static const Color statusPacked = Color(0xFF0284C7);
  static const Color statusInvoiced = Color(0xFF7C3AED);
  static const Color statusDispatched = Color(0xFFD97706);
  static const Color statusDelivered = Color(0xFF16A34A);
  static const Color statusReturnInitiated = Color(0xFFDC2626);
  static const Color statusReturnCompleted = Color(0xFF4F46E5);

  // ── Tracking Type Colors ───────────────────────────────────────────────────
  static const Color trackingBatchBg = Color(0xFFEDE9FE); // Soft purple/violet
  static const Color trackingBatchText = Color(0xFF6D28D9); // Dark purple/violet

  static const Color trackingSerialBg = Color(0xFFE0F2FE); // Soft sky blue/cyan
  static const Color trackingSerialText = Color(0xFF0369A1); // Dark sky blue/cyan

  static const Color trackingUntrackedBg = Color(0xFFF1F5F9); // Soft slate gray
  static const Color trackingUntrackedText = Color(0xFF475569); // Dark slate gray

  static Color getTrackingBgColor(String? type) {
    final t = type?.toLowerCase().trim() ?? '';
    if (t == 'batch' || t.contains('batch')) return trackingBatchBg;
    if (t == 'serial' || t.contains('serial')) return trackingSerialBg;
    return trackingUntrackedBg;
  }

  static Color getTrackingTextColor(String? type) {
    final t = type?.toLowerCase().trim() ?? '';
    if (t == 'batch' || t.contains('batch')) return trackingBatchText;
    if (t == 'serial' || t.contains('serial')) return trackingSerialText;
    return trackingUntrackedText;
  }

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
