import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class VendorService {
  VendorService._();

  static SupabaseClient get _client => SupabaseService.client;

  static Future<Map<String, dynamic>?> getCurrentVendor() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    return _client
        .from('vendors')
        .select('''
          id,
          profile_id,
          vendor_code,
          vendor_name,
          contact_person,
          phone,
          email,
          status
        ''')
        .eq('profile_id', user.id)
        .maybeSingle();
  }

  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    return _client
        .from('profiles')
        .select('id, email, full_name, role, status')
        .eq('id', user.id)
        .maybeSingle();
  }

  static Future<Map<String, dynamic>> generateMealsForDate(
    DateTime date,
  ) async {
    final mealDate =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    if (kDebugMode) {
      debugPrint('[Vendor Meal Generation] START date=$mealDate');
    }

    try {
      final result = await _client.rpc(
        'generate_meals_for_date',
        params: {'p_meal_date': mealDate},
      );
      final data = result is List && result.isNotEmpty ? result.first : result;
      final response = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};

      if (kDebugMode) {
        debugPrint('[Vendor Meal Generation] RESULT: $response');
      }
      return response;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Vendor Meal Generation] ERROR: $error');
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> loadTodaysMeals() async {
    if (kDebugMode) {
      debugPrint('[Vendor Meals] LOAD START');
    }

    try {
      final today = DateTime.now();
      final date = _dateOnly(today);
      final result = await _client
          .from('meal_records')
          .select('''
            id,
            employee_id,
            employees(
              employee_code,
              profiles(full_name)
            ),
            meal_date,
            meal_type,
            status,
            rate,
            cancelled_at,
            served_at,
            updated_by,
            created_at,
            updated_at
          ''')
          .eq('meal_date', date)
          .order('employee_id', ascending: true)
          .order('created_at', ascending: true);

      if (kDebugMode) {
        debugPrint('[Vendor Meals] RESULT: $result');
      }
      return (result as List).map(_withEmployeeIdentity).toList();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Vendor Meals] ERROR: $error');
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> loadTodaysGuestMeals() async {
    if (kDebugMode) debugPrint('[Vendor Guest Meals] LOAD START');
    try {
      final result = await _client.rpc('get_today_guest_meals_for_vendor');
      final rows = result is List ? result : <dynamic>[result];
      final meals = rows
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      if (kDebugMode) debugPrint('[Vendor Guest Meals] RESULT: $meals');
      return meals;
    } catch (error) {
      if (kDebugMode) debugPrint('[Vendor Guest Meals] ERROR: $error');
      rethrow;
    }
  }

  static Map<String, dynamic> _withEmployeeIdentity(dynamic row) {
    final meal = Map<String, dynamic>.from(row as Map);
    final employee = meal.remove('employees');
    if (employee is Map) {
      final employeeData = Map<String, dynamic>.from(employee);
      final profile = employeeData['profiles'];
      final profileData = profile is Map
          ? Map<String, dynamic>.from(profile)
          : const <String, dynamic>{};
      meal['employee_code'] = employeeData['employee_code'];
      meal['employee_name'] = profileData['full_name'];
    }
    return meal;
  }

  static Future<int> loadActiveEmployeeCount() async {
    final result = await _client
        .from('employees')
        .select('id')
        .eq('status', 'ACTIVE');
    final employeeIds = (result as List)
        .map((row) => (row as Map)['id'])
        .whereType<String>()
        .toSet();
    return employeeIds.length;
  }

  static Future<Map<String, dynamic>> markMealServed(String mealId) async {
    if (kDebugMode) {
      debugPrint('[Vendor Meals] SERVE START mealId=$mealId');
    }

    try {
      final result = await _client.rpc(
        'vendor_mark_meal_served',
        params: {'p_meal_id': mealId},
      );
      final data = result is List && result.isNotEmpty ? result.first : result;
      final response = Map<String, dynamic>.from(data as Map);
      if (kDebugMode) {
        debugPrint('[Vendor Meals] SERVE SUCCESS: $response');
      }
      return response;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Vendor Meals] ERROR: $error');
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
