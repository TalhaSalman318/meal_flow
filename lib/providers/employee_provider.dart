import 'package:canteen_app/core/services/empolyee_services.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employee_model.dart';
import '../models/meal_record_model.dart';
import '../models/ledger_model.dart';
import '../models/guest_meal_model.dart';
import '../models/menu_model.dart';
import '../models/profile_model.dart';
import '../models/subscription_model.dart';
import '../models/subscription_pause_model.dart';

class EmployeeProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  EmployeeModel? _employee;
  ProfileModel? _profile;
  Map<String, dynamic>? _todaysMenu;
  List<MenuModel> _menus = [];
  DateTime _menuMonth = DateTime.now();
  bool _isMenuLoading = false;
  String? _menuError;
  SubscriptionModel? _subscription;
  List<SubscriptionPauseModel> _subscriptionPauses = [];
  bool _isSubscriptionLoading = false;
  String? _subscriptionError;
  MealRecordModel? _todayMeal;
  bool _isMealLoading = false;
  bool _isMealCancelling = false;
  String? _mealErrorMessage;
  List<MealRecordModel> _mealHistory = [];
  bool _isMealHistoryLoading = false;
  String? _mealHistoryError;
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;
  List<LedgerModel> _ledgerHistory = [];
  List<SubscriptionPauseModel> _mealHistoryPauses = [];
  List<GuestMealModel> _guestMeals = [];
  List<Map<String, dynamic>> _activeVendors = [];
  bool _isLoadingGuestMeals = false;
  bool _isAddingGuestMeal = false;
  String? _guestMealError;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  EmployeeModel? get employee => _employee;

  ProfileModel? get profile => _profile;

  Map<String, dynamic>? get todaysMenu => _todaysMenu;

  List<MenuModel> get menus => List.unmodifiable(_menus);
  DateTime get menuMonth => _menuMonth;
  bool get isMenuLoading => _isMenuLoading;
  String? get menuError => _menuError;

  SubscriptionModel? get subscription => _subscription;

  bool get isSubscriptionLoading => _isSubscriptionLoading;

  String? get subscriptionError => _subscriptionError;

  MealRecordModel? get todayMeal => _todayMeal;

  bool get isMealLoading => _isMealLoading;

  bool get isMealCancelling => _isMealCancelling;

  String? get mealErrorMessage => _mealErrorMessage;

  List<MealRecordModel> get mealHistory => List.unmodifiable(_mealHistory);

  bool get isMealHistoryLoading => _isMealHistoryLoading;

  String? get mealHistoryError => _mealHistoryError;

  DateTime get selectedMonth => _selectedMonth;

  DateTime? get selectedDate => _selectedDate;

  List<LedgerModel> get ledgerHistory => List.unmodifiable(_ledgerHistory);

  List<SubscriptionPauseModel> get mealHistoryPauses =>
      List.unmodifiable(_mealHistoryPauses);

  SubscriptionPauseModel? pauseForDate(DateTime date) {
    for (final pause in _mealHistoryPauses) {
      if (pause.covers(date)) return pause;
    }
    return null;
  }

  double get monthlyMealCharges => _ledgerHistory
      .where((entry) => entry.transactionType == 'MEAL')
      .fold(0, (total, entry) => total + entry.debit);

  double get monthlyCancellationCredits => _ledgerHistory
      .where((entry) => entry.transactionType == 'CANCELLATION')
      .fold(0, (total, entry) => total + entry.credit);

  double get monthlyNetAmount =>
      monthlyMealCharges - monthlyCancellationCredits;

  List<GuestMealModel> get guestMeals => List.unmodifiable(_guestMeals);
  List<Map<String, dynamic>> get activeVendors =>
      List.unmodifiable(_activeVendors);
  bool get isLoadingGuestMeals => _isLoadingGuestMeals;
  bool get isAddingGuestMeal => _isAddingGuestMeal;
  String? get guestMealError => _guestMealError;
  double get guestMealTotal =>
      _guestMeals.fold(0, (total, meal) => total + meal.amount);

  bool get isPaused {
    if (_subscription?.status != 'ACTIVE') return false;
    return _subscriptionPauses.any((pause) => pause.covers(DateTime.now()));
  }

  String get subscriptionStatus {
    if (_subscription == null) return 'NOT SUBSCRIBED';
    if (_subscription!.status == 'CANCELLED') return 'CANCELLED';
    if (_subscription!.status == 'EXPIRED') return 'EXPIRED';
    return isPaused ? 'PAUSED' : 'ACTIVE';
  }

  bool get hasTodaysMenu => _todaysMenu != null;

  bool get hasData => _employee != null && _profile != null;

  // ============================================================
  // LOAD CURRENT EMPLOYEE
  // ============================================================

  Future<bool> loadEmployeeData() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final profileData = await EmployeeService.getCurrentProfile();

      if (profileData == null) {
        _errorMessage = 'Profile not found.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final profileRole = (profileData['role'] as String?)?.toUpperCase();
      if (profileRole != 'EMPLOYEE') {
        _errorMessage = 'This account is not an employee account.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final employeeData = await EmployeeService.getCurrentEmployee();

      if (employeeData == null) {
        _errorMessage = 'Employee record not found.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _profile = ProfileModel.fromMap(profileData);

      _employee = EmployeeModel.fromMap(employeeData);

      if (kDebugMode) {
        debugPrint('[Employee Menu] PROVIDER LOAD START');
      }

      try {
        _todaysMenu = await EmployeeService.getTodaysMenu();

        if (kDebugMode) {
          debugPrint('[Employee Menu] PROVIDER MENU RESULT: $_todaysMenu');
        }
      } catch (error) {
        _todaysMenu = null;

        if (kDebugMode) {
          debugPrint('[Employee Menu] PROVIDER ERROR: $error');
        }
      }

      await loadSubscription();
      await loadTodayMeal();

      _isLoading = false;

      notifyListeners();

      return true;
    } catch (error) {
      _errorMessage = 'Unable to load employee data. Please try again.';

      if (kDebugMode) {
        debugPrint('[EmployeeProvider] ERROR: $error');
      }

      _isLoading = false;

      notifyListeners();

      return false;
    }
  }

  Future<void> loadTodayMeal() async {
    _isMealLoading = true;
    _mealErrorMessage = null;
    notifyListeners();

    try {
      final data = await EmployeeService.getTodaysMeal();
      _todayMeal = data == null ? null : MealRecordModel.fromMap(data);
      if (kDebugMode) {
        debugPrint('[Employee Meal] RESULT: $_todayMeal');
      }
    } catch (error) {
      _todayMeal = null;
      _mealErrorMessage = 'Unable to load today\'s meal.';
      if (kDebugMode) {
        debugPrint('[Employee Meal] ERROR: $error');
      }
    } finally {
      _isMealLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMenusForMonth([DateTime? month]) async {
    if (month != null) {
      _menuMonth = DateTime(month.year, month.month, 1);
    }
    _isMenuLoading = true;
    _menuError = null;
    notifyListeners();
    try {
      final rows = await EmployeeService.getMenusForMonth(_menuMonth);
      _menus = rows.map(MenuModel.fromMap).toList();
    } catch (error) {
      _menus = [];
      _menuError = 'Unable to load menus. Please try again.';
      if (kDebugMode) debugPrint('[Employee Menu] MONTH ERROR: $error');
    } finally {
      _isMenuLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeMenuMonth(int offset) => loadMenusForMonth(
    DateTime(_menuMonth.year, _menuMonth.month + offset, 1),
  );

  Future<bool> cancelTodayMeal() async {
    if (_isMealCancelling) return false;

    _isMealCancelling = true;
    _mealErrorMessage = null;
    notifyListeners();

    try {
      final result = await EmployeeService.cancelTodaysMeal();
      final cancelledAt = result['cancelled_at'];
      _todayMeal = _todayMeal?.copyWith(
        status: 'CANCELLED',
        cancelledAt: cancelledAt is String
            ? DateTime.tryParse(cancelledAt)
            : null,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      await loadTodayMeal();
      if (kDebugMode) {
        debugPrint('[Employee Meal] REFRESHING MEAL HISTORY');
      }
      await refreshMealHistory();
      return true;
    } catch (error) {
      _mealErrorMessage = _mealActionError(error);
      if (kDebugMode) {
        debugPrint('[Employee Meal] ERROR: $error');
      }
      return false;
    } finally {
      _isMealCancelling = false;
      notifyListeners();
    }
  }

  String _mealActionError(Object error) {
    final message = error is PostgrestException ? error.message : '$error';
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('already cancelled')) {
      return "Today's meal is already cancelled.";
    }
    if (lowerMessage.contains('served meal')) {
      return 'A served meal cannot be cancelled.';
    }
    if (lowerMessage.contains('no meal')) {
      return 'No meal is scheduled for today.';
    }
    if (error is PostgrestException && error.code == '42501') {
      return 'You do not have permission to cancel this meal.';
    }
    return 'Unable to cancel today\'s meal.';
  }

  Future<void> loadSubscription() async {
    if (kDebugMode) {
      debugPrint('[Employee Subscription] LOAD START');
    }

    try {
      final data = await EmployeeService.getCurrentSubscription();
      if (data == null) {
        _subscription = null;
        _subscriptionPauses = [];
      } else {
        _subscription = SubscriptionModel.fromMap(data['subscription']);
        _subscriptionPauses = List<SubscriptionPauseModel>.from(data['pauses']);
      }
      _subscriptionError = null;
      if (kDebugMode) {
        debugPrint('[Employee Subscription] RESULT: $subscriptionStatus');
      }
    } catch (error) {
      _subscriptionError = 'Unable to load subscription.';
      if (kDebugMode) {
        debugPrint('[Employee Subscription] ERROR: $error');
      }
    }
    notifyListeners();
  }

  Future<void> loadGuestMeals() async {
    if (_isLoadingGuestMeals) return;
    _isLoadingGuestMeals = true;
    _guestMealError = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final meals = await EmployeeService.getGuestMeals(
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
      );
      _guestMeals = meals.map(GuestMealModel.fromMap).toList();
    } catch (error) {
      _guestMeals = [];
      _guestMealError = 'Unable to load guest meals.';
      if (kDebugMode) debugPrint('[Employee Guest Meal] ERROR: $error');
    } finally {
      _isLoadingGuestMeals = false;
      notifyListeners();
    }
  }

  Future<void> loadActiveVendors() async {
    try {
      _activeVendors = await EmployeeService.getActiveVendors();
      notifyListeners();
    } catch (error) {
      _guestMealError = 'Unable to load available vendors.';
      if (kDebugMode) debugPrint('[Employee Guest Meal] ERROR: $error');
      notifyListeners();
    }
  }

  Future<void> loadGuestMealsForMonth(DateTime month) async {
    if (_isLoadingGuestMeals) return;
    _isLoadingGuestMeals = true;
    _guestMealError = null;
    notifyListeners();
    try {
      final meals = await EmployeeService.getGuestMeals(
        startDate: DateTime(month.year, month.month, 1),
        endDate: DateTime(month.year, month.month + 1, 0),
      );
      _guestMeals = meals.map(GuestMealModel.fromMap).toList();
    } catch (error) {
      _guestMealError = 'Unable to load guest meals.';
      if (kDebugMode) debugPrint('[Employee Guest Meal] ERROR: $error');
    } finally {
      _isLoadingGuestMeals = false;
      notifyListeners();
    }
  }

  Future<bool> addGuestMeal({
    required String guestType,
    required String guestName,
    String? vendorId,
    required DateTime mealDate,
    required String mealType,
    required double amount,
    String? notes,
  }) async {
    if (_isAddingGuestMeal) return false;
    _isAddingGuestMeal = true;
    _guestMealError = null;
    notifyListeners();
    try {
      final result = await EmployeeService.addGuestMeal(
        guestType: guestType,
        guestName: guestName,
        vendorId: vendorId,
        mealDate: mealDate,
        mealType: mealType,
        amount: amount,
        notes: notes,
      );
      final created = GuestMealModel.fromMap(result);
      _guestMeals = [created, ..._guestMeals];
      await loadGuestMeals();
      await refreshMealHistory();
      return true;
    } catch (error) {
      _guestMealError = _guestMealActionError(error);
      if (kDebugMode) debugPrint('[Employee Guest Meal] ERROR: $error');
      return false;
    } finally {
      _isAddingGuestMeal = false;
      notifyListeners();
    }
  }

  Future<void> refreshGuestMeals() => loadGuestMeals();

  String _guestMealActionError(Object error) {
    if (error is PostgrestException && error.code == '42501') {
      return 'You do not have permission to add guest meals.';
    }
    final message = error.toString().toLowerCase();
    if (message.contains('vendor'))
      return 'Please select a valid active vendor.';
    if (message.contains('quantity') || message.contains('amount')) {
      return 'Please enter a valid guest meal amount.';
    }
    return 'Unable to add guest meal.';
  }

  Future<void> loadMealHistory() async {
    if (_isMealHistoryLoading) return;
    _isMealHistoryLoading = true;
    _mealHistoryError = null;
    notifyListeners();
    try {
      final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      final records = await EmployeeService.getMealHistory(
        startDate: start,
        endDate: end,
      );
      _mealHistory = records.map(MealRecordModel.fromMap).toList();
      final ledgerRecords = await EmployeeService.getLedgerHistory(
        startDate: start,
        endDate: end,
      );
      _ledgerHistory = ledgerRecords.map(LedgerModel.fromMap).toList();
      final pauseRecords = await EmployeeService.getMealHistoryPauses(
        startDate: start,
        endDate: end,
      );
      _mealHistoryPauses = pauseRecords
          .map(SubscriptionPauseModel.fromMap)
          .toList();
      if (kDebugMode) {
        debugPrint('[Employee Meal History] RESULT: $_mealHistory');
      }
    } catch (error) {
      _mealHistory = [];
      _ledgerHistory = [];
      _mealHistoryPauses = [];
      _guestMeals = [];
      _activeVendors = [];
      _guestMealError = null;
      _mealHistoryError = 'Unable to load meal history.';
      if (kDebugMode) {
        debugPrint('[Employee Meal History] ERROR: $error');
      }
    } finally {
      _isMealHistoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeMonth(int offset) async {
    if (_isMealHistoryLoading) return;
    _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + offset,
      1,
    );
    _selectedDate = null;
    _ledgerHistory = [];
    await loadMealHistory();
  }

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    if (kDebugMode) {
      debugPrint('[Employee Meal History] SELECTED DATE: $_selectedDate');
    }
    notifyListeners();
  }

  Future<void> refreshMealHistory() async {
    if (kDebugMode) {
      debugPrint('[Employee Meal History] REFRESH START');
      debugPrint(
        '[Employee Meal History] REFRESH MONTH: '
        '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}',
      );
    }
    await loadMealHistory();
    if (kDebugMode) {
      debugPrint('[Employee Meal History] REFRESH RESULT');
      debugPrint('[Employee Meal History] CALENDAR STATE UPDATED');
    }
  }

  Future<bool> activateSubscription() async {
    if (_isSubscriptionLoading) return false;
    return _runSubscriptionAction(() async {
      await EmployeeService.activateSubscription();
      await loadSubscription();
      await _refreshMealHistoryAfterSubscription(
        '[Employee Subscription] ACTIVATE',
      );
    });
  }

  Future<bool> pauseSubscription({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_isSubscriptionLoading) return false;
    return _runSubscriptionAction(() async {
      await EmployeeService.pauseSubscription(
        startDate: startDate,
        endDate: endDate,
      );
      await loadSubscription();
      await _refreshMealHistoryAfterSubscription(
        '[Employee Subscription] PAUSE',
      );
    });
  }

  Future<bool> resumeSubscription() async {
    if (_isSubscriptionLoading) return false;
    return _runSubscriptionAction(() async {
      await EmployeeService.resumeSubscription();
      await loadSubscription();
      await _refreshMealHistoryAfterSubscription(
        '[Employee Subscription] RESUME',
      );
    });
  }

  Future<bool> cancelSubscription() async {
    if (_isSubscriptionLoading) return false;
    return _runSubscriptionAction(() async {
      await EmployeeService.cancelSubscription();
      await loadSubscription();
      await _refreshMealHistoryAfterSubscription(
        '[Employee Subscription] CANCEL',
      );
    });
  }

  Future<void> _refreshMealHistoryAfterSubscription(String operation) async {
    if (kDebugMode) {
      debugPrint('$operation SUCCESS');
      debugPrint('[Employee Subscription] REFRESHING MEAL HISTORY');
    }
    await refreshMealHistory();
  }

  Future<bool> _runSubscriptionAction(Future<void> Function() action) async {
    _isSubscriptionLoading = true;
    _subscriptionError = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      _subscriptionError = error is PostgrestException && error.code == '42501'
          ? 'You do not have permission to update this subscription.'
          : 'Unable to update subscription.';
      if (kDebugMode) {
        debugPrint('[Employee Subscription] ERROR: $error');
      }
      return false;
    } finally {
      _isSubscriptionLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR DATA
  // ============================================================

  void clearData() {
    _employee = null;
    _profile = null;
    _todaysMenu = null;
    _subscription = null;
    _subscriptionPauses = [];
    _subscriptionError = null;
    _todayMeal = null;
    _mealErrorMessage = null;
    _mealHistory = [];
    _mealHistoryError = null;
    _selectedDate = null;
    _errorMessage = null;

    notifyListeners();
  }
}
