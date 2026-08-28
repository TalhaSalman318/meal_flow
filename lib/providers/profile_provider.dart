import 'package:flutter/foundation.dart';

import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';
import '../core/errors/app_error.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository = ProfileRepository();

  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileModel? get profile => _profile;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isEmployee => _profile?.isEmployee ?? false;

  bool get isVendor => _profile?.isVendor ?? false;

  Future<bool> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await _repository.getCurrentProfile();

      _profile = profile;

      _isLoading = false;
      notifyListeners();

      return profile != null;
    } catch (error) {
      _error = AppError.message(
        error,
        fallback: 'Unable to load your profile. Please try again.',
      );
      _isLoading = false;
      notifyListeners();

      return false;
    }
  }

  void clearProfile() {
    _profile = null;
    _error = null;
    notifyListeners();
  }
}
