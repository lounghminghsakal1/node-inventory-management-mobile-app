import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuditDraftService {
  static String _getKey(String auditId, String itemId) {
    return 'audit_draft_${auditId}_item_$itemId';
  }

  static Future<void> saveDraft(
      String auditId, String itemId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(auditId, itemId);
    await prefs.setString(key, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getDraft(
      String auditId, String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(auditId, itemId);
    final str = prefs.getString(key);
    if (str != null) {
      try {
        return jsonDecode(str) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearDraft(String auditId, String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(auditId, itemId);
    await prefs.remove(key);
  }
}
