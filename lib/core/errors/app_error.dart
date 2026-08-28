import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppError {
  AppError._();

  static String message(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    _log(error);

    if (error is AuthException) {
      final text = error.message.toLowerCase();
      final code = error.code?.toLowerCase();
      if (code == 'invalid_credentials' ||
          text.contains('invalid login credentials')) {
        return 'Email or password is incorrect.';
      }
      if (code == 'user_already_exists' ||
          text.contains('already registered')) {
        return 'This email is already registered.';
      }
      if (code == 'email_address_invalid' || text.contains('invalid email')) {
        return 'Please enter a valid email address.';
      }
      if (code == 'weak_password' || text.contains('password')) {
        return 'Please use a stronger password.';
      }
      if (code == 'session_missing' || text.contains('session')) {
        return 'Your session could not be established. Please try again.';
      }
      return fallback;
    }

    if (error is PostgrestException) {
      final text = error.message.toLowerCase();
      if (error.code == '42501' ||
          text.contains('row-level security') ||
          text.contains('permission denied')) {
        return 'You do not have permission to complete this request.';
      }
      if (error.code == '23505' ||
          text.contains('duplicate key') ||
          text.contains('already exists')) {
        return 'This record already exists.';
      }
      if (error.code == '23503') return 'A related record could not be found.';
      if (error.code == 'PGRST116') {
        return 'The requested record was not found.';
      }
      if (error.code == 'PGRST202' || error.code == '42883') {
        return 'This feature is not available on the server yet.';
      }
      return fallback;
    }

    if (error is TimeoutException || _typeContains(error, 'timeout')) {
      return 'The connection is taking too long. Please try again.';
    }

    if (_typeContains(error, 'socket') ||
        _typeContains(error, 'network') ||
        _typeContains(error, 'connection')) {
      return 'No internet connection. Please check your internet and try again.';
    }

    return fallback;
  }

  static void _log(Object error) {
    if (!kDebugMode) return;
    if (error is PostgrestException) {
      debugPrint(
        '[ERROR] PostgREST: code=${error.code}, message="${error.message}", details="${error.details}", hint="${error.hint}"',
      );
    } else if (error is AuthException) {
      debugPrint(
        '[ERROR] Auth: code=${error.code}, message="${error.message}", statusCode=${error.statusCode}',
      );
    } else {
      debugPrint('[ERROR] ${error.runtimeType}: $error');
    }
  }

  static bool _typeContains(Object error, String value) =>
      error.runtimeType.toString().toLowerCase().contains(value);
}
