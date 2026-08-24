import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => AuthService.currentUser != null;

  // ============================================================
  // LOGIN
  // ============================================================

  Future<bool> login({required String email, required String password}) async {
    if (_isLoading) {
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await AuthService.signIn(email: email, password: password);

      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // SIGNUP
  // ============================================================

  Future<bool> signup({
    required String fullName,
    required String email,
    required String password,
    required String role,

    String? department,
    String? designation,

    String? phone,

    String? vendorName,
    String? contactPerson,
  }) async {
    if (_isLoading) {
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await AuthService.signUp(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        department: department,
        designation: designation,
        phone: phone,
        vendorName: vendorName,
        contactPerson: contactPerson,
      );

      _setLoading(false);
      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
      _setLoading(false);
      return false;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      await AuthService.signOut();
    } finally {
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  String _cleanError(Object error) {
    if (error is AuthException) {
      _logSupabaseError(error);

      final message = error.message;
      final lowerMessage = message.toLowerCase();
      final code = error.code?.toLowerCase();

      if (code == 'user_already_exists' ||
          lowerMessage.contains('already registered') ||
          lowerMessage.contains('already exists')) {
        return 'This email is already registered.';
      }

      if (code == 'email_address_invalid' ||
          lowerMessage.contains('invalid email')) {
        return 'Please enter a valid email address.';
      }

      if (code == 'weak_password' ||
          lowerMessage.contains('password should be at least')) {
        return 'Password must be at least 6 characters.';
      }

      if (code == 'session_missing') {
        return message;
      }

      if (code == 'signup_profile_failed') {
        return message;
      }

      if (code == 'signup_employee_failed') {
        return message;
      }

      if (code == 'signup_vendor_failed') {
        return message;
      }

      return _withSupabaseDetails(message, error.statusCode, error.code);
    }

    if (error is PostgrestException) {
      _logSupabaseError(error);

      final message = error.message;
      final lowerMessage = message.toLowerCase();

      if (error.code == '42501' ||
          lowerMessage.contains('row-level security') ||
          lowerMessage.contains('permission denied')) {
        return 'Supabase rejected the database request because of Row Level Security (RLS). '
            'Check the INSERT policies for profiles, employees, or vendors.';
      }

      if (error.code == '23505') {
        if (lowerMessage.contains('employee_code')) {
          return 'Employee code already exists. Check the employee code trigger.';
        }

        if (lowerMessage.contains('vendor_code')) {
          return 'Vendor code already exists.';
        }

        return 'A record with this information already exists. '
            'Supabase code: 23505.';
      }

      if (error.code == '23503') {
        return 'A related profile record is missing. '
            'Please check the profile/employee relationship.';
      }

      if (error.code == '23502') {
        return 'A required database field is missing. '
            'Check the employees table columns/defaults.';
      }

      return _withSupabaseDetails(message, null, error.code);
    }

    if (error is TimeoutException) {
      return 'The request timed out. Check your internet connection and try again.';
    }

    if (kDebugMode) {
      debugPrint(
        '[Signup unexpected error] '
        '${error.runtimeType}: $error',
      );
    }

    return 'Unexpected error: ${error.runtimeType}';
  }

  // ============================================================
  // SUPABASE ERROR DETAILS
  // ============================================================

  String _withSupabaseDetails(
    String message,
    String? statusCode,
    String? code,
  ) {
    final details = <String>[
      if (statusCode != null) 'statusCode: $statusCode',
      if (code != null) 'code: $code',
    ];

    if (details.isEmpty) {
      return message;
    }

    return '$message (${details.join(', ')})';
  }

  // ============================================================
  // DEBUG LOGGER
  // ============================================================

  void _logSupabaseError(Object error) {
    if (!kDebugMode) {
      return;
    }

    if (error is AuthException) {
      debugPrint(
        '[Supabase auth] '
        '${error.runtimeType}: '
        'message="${error.message}", '
        'statusCode=${error.statusCode}, '
        'code=${error.code}',
      );
    } else if (error is PostgrestException) {
      debugPrint(
        '[Supabase database] '
        '${error.runtimeType}: '
        'message="${error.message}", '
        'code=${error.code}, '
        'details="${error.details}", '
        'hint="${error.hint}"',
      );
    }
  }
}
