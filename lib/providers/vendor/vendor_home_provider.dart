import 'package:flutter/foundation.dart';

import '../../core/services/vendor_menu_service.dart';
import '../../core/services/vendor_service.dart';
import '../../models/menu_model.dart';
import '../../models/profile_model.dart';
import '../../models/vendor_model.dart';

class VendorHomeProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  ProfileModel? _profile;
  VendorModel? _vendor;
  MenuModel? _todaysMenu;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProfileModel? get profile => _profile;
  VendorModel? get vendor => _vendor;
  MenuModel? get todaysMenu => _todaysMenu;
  bool get hasData => _profile != null && _vendor != null;

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
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _errorMessage ??= 'Vendor record not found.';
    } catch (error) {
      _errorMessage = 'Unable to load vendor data. Please try again.';

      if (kDebugMode) {
        debugPrint('[VendorHomeProvider] ERROR: $error');
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void clearData() {
    _profile = null;
    _vendor = null;
    _todaysMenu = null;
    _errorMessage = null;
    notifyListeners();
  }
}
