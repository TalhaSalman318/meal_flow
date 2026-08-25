import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';
import '../../models/subscription_model.dart';
import '../../models/subscription_pause_model.dart';

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

  static Future<List<Map<String, dynamic>>> getActiveVendors() async {
    final result = await _client
        .from('vendors')
        .select('id, vendor_code, vendor_name, status')
        .eq('status', 'ACTIVE')
        .order('vendor_name');
    return (result as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> addGuestMeal({
    required String guestType,
    required String guestName,
    String? vendorId,
    required DateTime mealDate,
    required String mealType,
    required double amount,
    String? notes,
  }) async {
    if (kDebugMode) {
      debugPrint('[Employee Guest Meal] ADD START');
    }
    try {
      final result = await _client.rpc(
        'create_guest_meal',
        params: {
          'p_guest_type': guestType,
          'p_guest_name': guestName.trim(),
          'p_vendor_id': vendorId,
          'p_meal_date': _dateOnly(mealDate),
          'p_meal_type': mealType,
          'p_amount': amount,
          'p_notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
        },
      );
      final data = result is List && result.isNotEmpty ? result.first : result;
      final response = Map<String, dynamic>.from(data as Map);
      if (kDebugMode)
        debugPrint('[Employee Guest Meal] ADD SUCCESS: $response');
      return response;
    } catch (error) {
      if (kDebugMode) debugPrint('[Employee Guest Meal] ERROR: $error');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getGuestMeals({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (kDebugMode) debugPrint('[Employee Guest Meal] LOAD START');
    final employeeId = await _getCurrentEmployeeId();
    var query = _client
        .from('guest_meals')
        .select(
          'id, employee_id, guest_type, guest_name, vendor_id, meal_date, meal_type, amount, notes, created_at',
        )
        .eq('employee_id', employeeId);
    if (startDate != null) query = query.gte('meal_date', _dateOnly(startDate));
    if (endDate != null) query = query.lte('meal_date', _dateOnly(endDate));
    final result = await query
        .order('meal_date', ascending: false)
        .order('created_at', ascending: false);
    if (kDebugMode) debugPrint('[Employee Guest Meal] RESULT: $result');
    return (result as List).cast<Map<String, dynamic>>();
  }

  static Future<String> _getCurrentEmployeeId() async {
    final employee = await getCurrentEmployee();
    if (employee == null) {
      throw StateError('Employee record not found.');
    }
    return employee['id'] as String;
  }

  static Future<Map<String, dynamic>?> getCurrentSubscription() async {
    final result = await _client
        .from('subscriptions')
        .select(
          'id, employee_id, start_date, end_date, daily_rate, status, '
          'created_at, updated_at',
        )
        .order('start_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (result == null) {
      return null;
    }

    final subscription = SubscriptionModel.fromMap(result);
    final pauses = await _client
        .from('subscription_pauses')
        .select('id, subscription_id, start_date, end_date, reason, created_at')
        .eq('subscription_id', subscription.id)
        .order('start_date', ascending: false);

    return {
      'subscription': result,
      'pauses': (pauses as List)
          .map((pause) => SubscriptionPauseModel.fromMap(pause))
          .toList(),
    };
  }

  static Future<void> activateSubscription() async {
    final employeeId = await _getCurrentEmployeeId();
    final today = DateTime.now();
    final endDate = DateTime(today.year, today.month + 1, 0);

    await _client.from('subscriptions').insert({
      'employee_id': employeeId,
      'start_date': _dateOnly(today),
      'end_date': _dateOnly(endDate),
      'daily_rate': 400,
      'status': 'ACTIVE',
    });
  }

  static Future<void> pauseSubscription({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (kDebugMode) {
      debugPrint('[Employee Subscription] PAUSE START');
    }

    final data = await getCurrentSubscription();
    if (data == null) {
      throw StateError('No subscription found.');
    }

    final subscription = SubscriptionModel.fromMap(data['subscription']);
    final requestedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final requestedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    if (requestedEnd.isBefore(requestedStart)) {
      throw ArgumentError('Pause dates are invalid.');
    }

    final subscriptionStart = DateTime(
      subscription.startDate.year,
      subscription.startDate.month,
      subscription.startDate.day,
    );
    final subscriptionEnd = DateTime(
      subscription.endDate.year,
      subscription.endDate.month,
      subscription.endDate.day,
    );
    if (requestedStart.isBefore(subscriptionStart) ||
        requestedEnd.isAfter(subscriptionEnd)) {
      throw StateError('Pause dates must be within the subscription period.');
    }

    final pauses = data['pauses'] as List<SubscriptionPauseModel>;
    final overlaps = pauses.any(
      (pause) =>
          !requestedEnd.isBefore(pause.startDate) &&
          !requestedStart.isAfter(pause.endDate),
    );
    if (overlaps) {
      throw StateError('The selected dates are already paused.');
    }

    await _client.from('subscription_pauses').insert({
      'subscription_id': subscription.id,
      'start_date': _dateOnly(requestedStart),
      'end_date': _dateOnly(requestedEnd),
      'reason': 'Employee requested pause',
    });

    if (kDebugMode) {
      debugPrint('[Employee Subscription] PAUSE SUCCESS');
    }
  }

  static Future<void> resumeSubscription() async {
    if (kDebugMode) {
      debugPrint('[Employee Subscription] RESUME START');
    }

    final data = await getCurrentSubscription();
    if (data == null) {
      throw StateError('No subscription found.');
    }

    final subscription = SubscriptionModel.fromMap(data['subscription']);
    final pauses = data['pauses'] as List<SubscriptionPauseModel>;
    SubscriptionPauseModel? currentPause;
    for (final pause in pauses) {
      if (pause.covers(DateTime.now())) {
        currentPause = pause;
        break;
      }
    }

    if (currentPause == null) {
      return;
    }

    final today = DateTime.now();
    final pauseStart = DateTime(
      currentPause.startDate.year,
      currentPause.startDate.month,
      currentPause.startDate.day,
    );
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (pauseStart.isAtSameMomentAs(todayOnly)) {
      await _client
          .from('subscription_pauses')
          .delete()
          .eq('id', currentPause.id)
          .eq('subscription_id', subscription.id);
      if (kDebugMode) {
        debugPrint('[Employee Subscription] RESUME SUCCESS');
      }
      return;
    }

    final yesterday = today.subtract(const Duration(days: 1));
    await _client
        .from('subscription_pauses')
        .update({'end_date': _dateOnly(yesterday)})
        .eq('id', currentPause.id)
        .eq('subscription_id', subscription.id);

    if (kDebugMode) {
      debugPrint('[Employee Subscription] RESUME SUCCESS');
    }
  }

  static Future<void> cancelSubscription() async {
    final data = await getCurrentSubscription();
    if (data == null) {
      throw StateError('No subscription found.');
    }

    final subscription = SubscriptionModel.fromMap(data['subscription']);
    if (subscription.status == 'CANCELLED') {
      return;
    }

    await _client
        .from('subscriptions')
        .update({'status': 'CANCELLED'})
        .eq('id', subscription.id);
  }

  static Future<Map<String, dynamic>?> getTodaysMeal() async {
    if (kDebugMode) {
      debugPrint('[Employee Meal] LOAD START');
    }

    try {
      final employeeId = await _getCurrentEmployeeId();
      final result = await _client
          .from('meal_records')
          .select('''
            id,
            employee_id,
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
          .eq('employee_id', employeeId)
          .eq('meal_date', _dateOnly(DateTime.now()))
          .maybeSingle();

      if (kDebugMode) {
        debugPrint('[Employee Meal] TODAY MEAL RESULT: $result');
      }
      return result;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Employee Meal] ERROR: $error');
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getMealHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    if (end.isBefore(start)) {
      throw ArgumentError('The meal history date range is invalid.');
    }

    if (kDebugMode) {
      debugPrint('[Employee Meal History] MONTH: ${start.year}-${start.month}');
    }

    final employeeId = await _getCurrentEmployeeId();
    final result = await _client
        .from('meal_records')
        .select('''
          id,
          employee_id,
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
        .eq('employee_id', employeeId)
        .gte('meal_date', _dateOnly(start))
        .lte('meal_date', _dateOnly(end))
        .order('meal_date', ascending: true);

    if (kDebugMode) {
      debugPrint('[Employee Meal History] RESULT: $result');
    }
    return (result as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getLedgerHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    if (end.isBefore(start)) {
      throw ArgumentError('The ledger date range is invalid.');
    }

    final employeeId = await _getCurrentEmployeeId();
    final result = await _client
        .from('ledger')
        .select('''
          id,
          employee_id,
          transaction_date,
          transaction_type,
          description,
          debit,
          credit,
          reference_id,
          created_at
        ''')
        .eq('employee_id', employeeId)
        .gte('transaction_date', _dateOnly(start))
        .lte('transaction_date', _dateOnly(end))
        .order('transaction_date', ascending: true)
        .order('created_at', ascending: true);

    return (result as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getMealHistoryPauses({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    if (end.isBefore(start)) {
      throw ArgumentError('The pause date range is invalid.');
    }

    final employeeId = await _getCurrentEmployeeId();
    final subscriptions = await _client
        .from('subscriptions')
        .select('id')
        .eq('employee_id', employeeId)
        .lte('start_date', _dateOnly(end))
        .gte('end_date', _dateOnly(start));
    final subscriptionIds = (subscriptions as List)
        .map((subscription) => subscription['id'] as String)
        .toList();

    if (subscriptionIds.isEmpty) return [];

    final pauses = await _client
        .from('subscription_pauses')
        .select('id, subscription_id, start_date, end_date, reason, created_at')
        .inFilter('subscription_id', subscriptionIds)
        .lte('start_date', _dateOnly(end))
        .gte('end_date', _dateOnly(start));
    return (pauses as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> cancelTodaysMeal() async {
    if (kDebugMode) {
      debugPrint('[Employee Meal] CANCEL START');
    }

    try {
      final result = await _client.rpc('cancel_my_today_meal');
      final data = result is List ? result.first : result;
      final meal = Map<String, dynamic>.from(data as Map);

      if (kDebugMode) {
        debugPrint('[Employee Meal] CANCEL SUCCESS: $meal');
      }
      return meal;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Employee Meal] CANCEL ERROR: $error');
      }
      rethrow;
    }
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

  static Future<List<Map<String, dynamic>>> getMenusForMonth(
    DateTime month,
  ) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);
    final result = await _client
        .from('menus')
        .select(
          'id, menu_date, title, description, image_url, created_by, created_at, updated_at',
        )
        .gte('menu_date', _dateOnly(firstDay))
        .lt('menu_date', _dateOnly(nextMonth))
        .order('menu_date', ascending: true);
    return (result as List).cast<Map<String, dynamic>>();
  }

  static String _dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
