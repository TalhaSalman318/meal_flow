import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class EmployeeService {
  EmployeeService._();

  static SupabaseClient get _client => SupabaseService.client;

  // ============================================================
  // GET CURRENT EMPLOYEE
  // ============================================================

  static Future<Map<String, dynamic>?> getCurrentEmployee() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final result = await _client
        .from('employees')
        .select('''
          id,
          profile_id,
          employee_code,
          department,
          designation,
          phone,
          status
        ''')
        .eq('profile_id', user.id)
        .maybeSingle();

    return result;
  }

  // ============================================================
  // GET CURRENT PROFILE
  // ============================================================

  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final result = await _client
        .from('profiles')
        .select('''
          id,
          email,
          full_name,
          role,
          status
        ''')
        .eq('id', user.id)
        .maybeSingle();

    return result;
  }

  // ============================================================
  // GET TODAY'S MENU
  // ============================================================

  static Future<Map<String, dynamic>?> getTodaysMenu() async {
    final today = DateTime.now();
    final date = _dateOnly(today);

    if (kDebugMode) {
      debugPrint('[Employee Menu] TODAY MENU DATE: $date');
    }

    try {
      final result = await _client
          .from('menus')
          .select('''
            id,
            menu_date,
            title,
            description,
            image_url,
            created_by,
            created_at,
            updated_at
          ''')
          .eq('menu_date', date)
          .maybeSingle();

      if (kDebugMode) {
        debugPrint('[Employee Menu] TODAY MENU RESULT: $result');
      }

      return result;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Employee Menu] TODAY MENU ERROR: $error');
      }
      rethrow;
    }
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
