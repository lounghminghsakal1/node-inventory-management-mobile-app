import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF080B18);
  static const Color surface = Color(0xFF0F1427);
  static const Color card = Color(0xFF161D35);
  static const Color cardElevated = Color(0xFF1C2540);
  static const Color cardBorder = Color(0xFF252E50);

  // ── Brand Primary ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF5B8AF6);
  static const Color primaryDark = Color(0xFF3B6ADE);
  static const Color primaryLight = Color(0xFF8AABFF);

  // ── Accent ─────────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF00D4FF);
  static const Color accent = Color(0xFFA855F7);
  static const Color accentGreen = Color(0xFF10B981);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFEFF2FF);
  static const Color textSecondary = Color(0xFF8892B0);
  static const Color textMuted = Color(0xFF4A5578);
  static const Color textDisabled = Color(0xFF2A3055);

  // ── Shipment Status ────────────────────────────────────────────────────────
  static const Color statusCreated = Color(0xFF64748B);
  static const Color statusAllocated = Color(0xFF3B82F6);
  static const Color statusInvoiced = Color(0xFFA855F7);
  static const Color statusDispatched = Color(0xFFF59E0B);
  static const Color statusDelivered = Color(0xFF22C55E);
  static const Color statusReturnInitiated = Color(0xFFEF4444);
  static const Color statusReturnCompleted = Color(0xFF6366F1);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5B8AF6), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF080B18), Color(0xFF0D1226)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF5B8AF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C2540), Color(0xFF131929)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
