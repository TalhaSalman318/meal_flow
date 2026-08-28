import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/vendor_menu_service.dart';
import '../../core/services/vendor_service.dart';
import '../../models/menu_model.dart';
import '../../models/meal_record_model.dart';
import '../../models/guest_meal_model.dart';
import '../../models/profile_model.dart';
import '../../models/vendor_model.dart';
import '../../core/errors/app_error.dart';

class VendorHomeProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  ProfileModel? _profile;
  VendorModel? _vendor;
  MenuModel? _todaysMenu;
  bool _isGeneratingMeals = false;
  String? _mealGenerationError;
  List<MealRecordModel> _todaysMeals = [];
  bool _isLoadingMeals = false;
  final Set<String> _servingMealIds = <String>{};
  String? _mealError;
  List<GuestMealModel> _todaysGuestMeals = [];
  bool _isLoadingGuestMeals = false;
  String? _guestMealError;
  int? _activeEmployeeCount;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProfileModel? get profile => _profile;
  VendorModel? get vendor => _vendor;
  MenuModel? get todaysMenu => _todaysMenu;
  bool get hasData => _profile != null && _vendor != null;
  bool get isGeneratingMeals => _isGeneratingMeals;
  String? get mealGenerationError => _mealGenerationError;
  List<MealRecordModel> get todaysMeals => List.unmodifiable(_todaysMeals);
  bool get isLoadingMeals => _isLoadingMeals;
  Set<String> get servingMealIds => Set.unmodifiable(_servingMealIds);
  String? get mealError => _mealError;
  int get totalMeals => _todaysMeals.length;
  int get plannedMeals => _countStatus('PLANNED');
  int get servedMeals => _countStatus('SERVED');
  int get cancelledMeals => _countStatus('CANCELLED');
  int get pausedMeals => _countStatus('PAUSED');
  List<GuestMealModel> get todaysGuestMeals =>
      List.unmodifiable(_todaysGuestMeals);
  bool get isLoadingGuestMeals => _isLoadingGuestMeals;
  String? get guestMealError => _guestMealError;
  int? get activeEmployeeCount => _activeEmployeeCount;
  double get todaysRevenue =>
      _todaysMeals.fold<double>(0, (total, meal) => total + meal.rate) +
      _todaysGuestMeals.fold<double>(0, (total, meal) => total + meal.amount);

  int _countStatus(String status) =>
      _todaysMeals.where((meal) => meal.status == status).length;

  Future<bool> loadVendorData() async {
    if (kDebugMode) {
      debugPrint('[Vendor Dashboard] VENDOR LOAD START');
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profileData = await VendorService.getCurrentProfile();

      if (kDebugMode) {
        debugPrint(
          '[Vendor Dashboard] PROFILE FETCHED: '
          'id=${profileData?['id']} role=${profileData?['role']}',
        );
      }

      if (profileData == null) {
        _errorMessage = 'Profile not found.';
      } else if ((profileData['role'] as String?)?.toUpperCase() != 'VENDOR') {
        _errorMessage = 'This account is not a vendor account.';
      } else {
        final vendorData = await VendorService.getCurrentVendor();

        if (vendorData == null) {
          _errorMessage = 'Vendor record not found.';
        } else {
          final todaysMenuData = await VendorMenuService.getTodaysMenu();

          if (kDebugMode) {
            debugPrint(
              '[Vendor Dashboard] VENDOR LOAD SUCCESS: '
              'id=${vendorData['id']} code=${vendorData['vendor_code']}',
            );
          }

          _profile = ProfileModel.fromMap(profileData);
          _vendor = VendorModel.fromMap(vendorData);
          _todaysMenu = todaysMenuData == null
              ? null
              : MenuModel.fromMap(todaysMenuData);
          await Future.wait([
            loadTodaysMeals(),
            loadTodaysGuestMeals(),
            _loadActiveEmployeeCount(),
          ]);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _errorMessage ??= 'Vendor record not found.';
    } catch (error) {
      _errorMessage = AppError.message(
        error,
        fallback: 'Unable to load vendor data. Please try again.',
      );

      if (kDebugMode) {
        debugPrint('[VendorHomeProvider] ERROR: $error');
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> _loadActiveEmployeeCount() async {
    try {
      _activeEmployeeCount = await VendorService.loadActiveEmployeeCount();
    } catch (error) {
      _activeEmployeeCount = null;
      if (kDebugMode) {
        debugPrint('[Vendor Dashboard] ACTIVE EMPLOYEE COUNT ERROR: $error');
      }
    }
  }

  Future<Map<String, dynamic>?> generateTodaysMeals() async {
    if (_isGeneratingMeals) return null;

    _isGeneratingMeals = true;
    _mealGenerationError = null;
    notifyListeners();

    try {
      final result = await VendorService.generateMealsForDate(DateTime.now());
      await refreshTodaysMeals();
      return result;
    } catch (error) {
      _mealGenerationError =
          error is PostgrestException && error.code == '42501'
          ? 'You do not have permission to generate meals.'
          : AppError.message(
              error,
              fallback: 'Unable to generate today\'s meals.',
            );
      if (kDebugMode) {
        debugPrint('[Vendor Meal Generation] ERROR: $error');
      }
      return null;
    } finally {
      _isGeneratingMeals = false;
      notifyListeners();
    }
  }

  Future<void> loadTodaysMeals() async {
    if (_isLoadingMeals) return;
    _isLoadingMeals = true;
    _mealError = null;
    notifyListeners();
    try {
      final records = await VendorService.loadTodaysMeals();
      _todaysMeals = records.map(MealRecordModel.fromMap).toList();
    } catch (error) {
      _todaysMeals = [];
      _mealError = error is PostgrestException && error.code == '42501'
          ? 'You do not have permission to view today\'s meals.'
          : AppError.message(error, fallback: 'Unable to load today\'s meals.');
      if (kDebugMode) {
        debugPrint('[Vendor Meals] ERROR: $error');
      }
    } finally {
      _isLoadingMeals = false;
      notifyListeners();
    }
  }

  Future<void> loadTodaysGuestMeals() async {
    if (_isLoadingGuestMeals) return;
    _isLoadingGuestMeals = true;
    _guestMealError = null;
    notifyListeners();
    try {
      final rows = await VendorService.loadTodaysGuestMeals();
      _todaysGuestMeals = rows.map(GuestMealModel.fromMap).toList();
    } catch (error) {
      _todaysGuestMeals = [];
      _guestMealError = error is PostgrestException && error.code == '42501'
          ? 'You do not have permission to view guest meals.'
          : AppError.message(
              error,
              fallback: 'Unable to load today\'s guest meals.',
            );
      if (kDebugMode) debugPrint('[Vendor Guest Meals] ERROR: $error');
    } finally {
      _isLoadingGuestMeals = false;
      notifyListeners();
    }
  }

  Future<bool> serveMeal(String mealId) async {
    if (_servingMealIds.contains(mealId)) return false;
    _servingMealIds.add(mealId);
    _mealError = null;
    notifyListeners();
    try {
      final result = await VendorService.markMealServed(mealId);
      final index = _todaysMeals.indexWhere((meal) => meal.id == mealId);
      if (index != -1) {
        final servedAt = result['served_at'];
        _todaysMeals[index] = _todaysMeals[index].copyWith(
          status: 'SERVED',
          servedAt: servedAt is String ? DateTime.tryParse(servedAt) : null,
          updatedAt: DateTime.now(),
        );
      }
      notifyListeners();
      return true;
    } catch (error) {
      _mealError = _serveError(error);
      if (kDebugMode) {
        debugPrint('[Vendor Meals] ERROR: $error');
      }
      return false;
    } finally {
      _servingMealIds.remove(mealId);
      notifyListeners();
    }
  }

  Future<void> refreshTodaysMeals() => loadTodaysMeals();

  Future<void> refreshTodaysGuestMeals() => loadTodaysGuestMeals();

  String _serveError(Object error) {
    final message = error is PostgrestException ? error.message : '$error';
    final lower = message.toLowerCase();
    if (error is PostgrestException && error.code == '42501') {
      return 'You do not have permission to serve meals.';
    }
    if (lower.contains('already served')) return 'Meal is already served.';
    if (lower.contains('cancelled')) return 'Cancelled meals cannot be served.';
    if (lower.contains('not found')) return 'Meal not found.';
    return AppError.message(error, fallback: 'Unable to serve meal.');
  }

  void clearData() {
    _profile = null;
    _vendor = null;
    _todaysMenu = null;
    _mealGenerationError = null;
    _todaysMeals = [];
    _mealError = null;
    _todaysGuestMeals = [];
    _guestMealError = null;
    _activeEmployeeCount = null;
    _errorMessage = null;
    notifyListeners();
  }
}
