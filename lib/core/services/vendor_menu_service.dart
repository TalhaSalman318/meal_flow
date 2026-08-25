import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class VendorMenuService {
  VendorMenuService._();

  static SupabaseClient get _client => SupabaseService.client;

  static String get _currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('You must be signed in to manage menus.');
    }
    return user.id;
  }

  static Future<List<Map<String, dynamic>>> getMyMenus() async {
    final userId = _currentUserId;
    return _client
        .from('menus')
        .select(
          'id, menu_date, title, description, image_url, created_by, created_at, updated_at',
        )
        .eq('created_by', userId)
        .order('menu_date', ascending: false);
  }

  static Future<List<Map<String, dynamic>>> getMenusForMonth(
    DateTime month,
  ) async {
    final userId = _currentUserId;
    final firstDay = DateTime(month.year, month.month, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    final result = await _client
        .from('menus')
        .select(
          'id, menu_date, title, description, image_url, created_by, created_at, updated_at',
        )
        .eq('created_by', userId)
        .gte('menu_date', _dateOnly(firstDay))
        .lt('menu_date', _dateOnly(nextMonth))
        .order('menu_date', ascending: true);
    return (result as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getMenus() => getMyMenus();

  static Future<Map<String, dynamic>?> getTodaysMenu() async {
    final userId = _currentUserId;
    final today = DateTime.now();
    final date =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    return _client
        .from('menus')
        .select(
          'id, menu_date, title, description, image_url, created_by, created_at, updated_at',
        )
        .eq('created_by', userId)
        .eq('menu_date', date)
        .maybeSingle();
  }

  static Future<Map<String, dynamic>?> getMenuForDate(DateTime menuDate) async {
    final userId = _currentUserId;
    return _client
        .from('menus')
        .select(
          'id, menu_date, title, description, image_url, created_by, created_at, updated_at',
        )
        .eq('created_by', userId)
        .eq('menu_date', _dateOnly(menuDate))
        .maybeSingle();
  }

  static Future<void> createMenu({
    required DateTime menuDate,
    required String title,
    String? description,
    String? imageUrl,
  }) async {
    final userId = _currentUserId;
    await _client.from('menus').insert({
      'menu_date': _dateOnly(menuDate),
      'title': title.trim(),
      'description': _nullableText(description),
      'image_url': _nullableText(imageUrl),
      'created_by': userId,
    });
  }

  static Future<void> updateMenu({
    required String menuId,
    required DateTime menuDate,
    required String title,
    String? description,
    String? imageUrl,
  }) async {
    final userId = _currentUserId;
    await _client
        .from('menus')
        .update({
          'menu_date': _dateOnly(menuDate),
          'title': title.trim(),
          'description': _nullableText(description),
          'image_url': _nullableText(imageUrl),
        })
        .eq('id', menuId)
        .eq('created_by', userId);
  }

  static Future<void> deleteMenu(String menuId) async {
    final userId = _currentUserId;
    if (kDebugMode) {
      debugPrint('[Vendor Menu Delete] START menuId=$menuId userId=$userId');
    }

    final deletedRows = await _client
        .from('menus')
        .delete()
        .eq('id', menuId)
        .eq('created_by', userId)
        .select('id, created_by');

    if (kDebugMode) {
      debugPrint(
        '[Vendor Menu Delete] RESPONSE '
        'deletedRows=${deletedRows.length} menuId=$menuId userId=$userId',
      );
    }

    if (deletedRows.isEmpty) {
      throw StateError(
        'No menu was deleted. Verify the menu owner matches the current user '
        'and that the menus DELETE RLS policy allows Vendor-owned deletes.',
      );
    }

    if (kDebugMode) {
      debugPrint('[Vendor Menu Delete] SUCCESS menuId=$menuId');
    }
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String? _nullableText(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static void logError(Object error) {
    if (kDebugMode) {
      debugPrint('[Vendor Menu] ERROR: $error');
    }
  }
}
