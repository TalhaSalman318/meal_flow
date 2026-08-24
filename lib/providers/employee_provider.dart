import 'package:canteen_app/core/services/empolyee_services.dart';
import 'package:flutter/foundation.dart';

import '../models/employee_model.dart';
import '../models/profile_model.dart';

class EmployeeProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  EmployeeModel? _employee;
  ProfileModel? _profile;
  Map<String, dynamic>? _todaysMenu;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  EmployeeModel? get employee => _employee;

  ProfileModel? get profile => _profile;

  Map<String, dynamic>? get todaysMenu => _todaysMenu;

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

  // ============================================================
  // CLEAR DATA
  // ============================================================

  void clearData() {
    _employee = null;
    _profile = null;
    _todaysMenu = null;
    _errorMessage = null;

    notifyListeners();
  }
}
