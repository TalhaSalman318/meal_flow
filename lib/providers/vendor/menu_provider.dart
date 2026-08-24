import 'package:flutter/foundation.dart';

import '../../core/services/vendor_menu_service.dart';
import '../../models/menu_model.dart';

class VendorMenuProvider extends ChangeNotifier {
  final List<MenuModel> _menus = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  MenuModel? _duplicateMenu;

  List<MenuModel> get menus => List.unmodifiable(_menus);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  MenuModel? get duplicateMenu => _duplicateMenu;
  bool get isEmpty => !_isLoading && _menus.isEmpty && _errorMessage == null;

  Future<bool> loadMenus() async {
    _isLoading = true;
    _errorMessage = null;
    _duplicateMenu = null;
    notifyListeners();

    try {
      final rows = await VendorMenuService.getMyMenus();
      _menus
        ..clear()
        ..addAll(rows.map(MenuModel.fromMap));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      VendorMenuService.logError(error);
      _errorMessage = 'Unable to load your menus. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createMenu({
    required DateTime menuDate,
    required String title,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final existingMenu = await VendorMenuService.getMenuForDate(menuDate);
      if (existingMenu != null) {
        _duplicateMenu = MenuModel.fromMap(existingMenu);
        _errorMessage = 'A menu already exists for this date.';
        notifyListeners();
        return false;
      }
    } catch (error) {
      VendorMenuService.logError(error);
      _errorMessage = 'Unable to check the selected menu date.';
      notifyListeners();
      return false;
    }

    return _save(
      () => VendorMenuService.createMenu(
        menuDate: menuDate,
        title: title,
        description: description,
        imageUrl: imageUrl,
      ),
    );
  }

  Future<bool> updateMenu({
    required String menuId,
    required DateTime menuDate,
    required String title,
    String? description,
    String? imageUrl,
  }) async {
    return _save(
      () => VendorMenuService.updateMenu(
        menuId: menuId,
        menuDate: menuDate,
        title: title,
        description: description,
        imageUrl: imageUrl,
      ),
    );
  }

  Future<bool> deleteMenu(String menuId) async {
    if (kDebugMode) {
      debugPrint('[Vendor Menu Delete] PROVIDER START menuId=$menuId');
    }

    return _save(() => VendorMenuService.deleteMenu(menuId));
  }

  Future<bool> addMenu({
    required DateTime menuDate,
    required String title,
    String? description,
    String? imageUrl,
  }) {
    return createMenu(
      menuDate: menuDate,
      title: title,
      description: description,
      imageUrl: imageUrl,
    );
  }

  Future<bool> refreshMenus() => loadMenus();

  Future<bool> _save(Future<void> Function() operation) async {
    _isSaving = true;
    _errorMessage = null;
    _duplicateMenu = null;
    notifyListeners();

    try {
      await operation();
      _isSaving = false;
      await loadMenus();
      return true;
    } catch (error) {
      VendorMenuService.logError(error);
      _errorMessage = 'Unable to save menu changes. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
