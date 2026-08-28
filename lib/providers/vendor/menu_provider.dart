import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/vendor_menu_service.dart';
import '../../models/menu_model.dart';
import '../../core/errors/app_error.dart';

class VendorMenuProvider extends ChangeNotifier {
  final List<MenuModel> _menus = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  MenuModel? _duplicateMenu;
  DateTime _selectedMonth = DateTime.now();

  List<MenuModel> get menus => List.unmodifiable(_menus);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  MenuModel? get duplicateMenu => _duplicateMenu;
  DateTime get selectedMonth => _selectedMonth;
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
      _errorMessage = AppError.message(
        error,
        fallback: 'Unable to load your menus. Please try again.',
      );
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadMenusForMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month, 1);
    _isLoading = true;
    _errorMessage = null;
    _duplicateMenu = null;
    notifyListeners();

    try {
      final rows = await VendorMenuService.getMenusForMonth(_selectedMonth);
      _menus
        ..clear()
        ..addAll(rows.map(MenuModel.fromMap));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      VendorMenuService.logError(error);
      _errorMessage = AppError.message(
        error,
        fallback: 'Unable to load your menus. Please try again.',
      );
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeMonth(int offset) => loadMenusForMonth(
    DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1),
  );

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
      _errorMessage = _menuError(error);
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
      _errorMessage = _menuError(error);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  String _menuError(Object error) {
    if (error is AuthException) {
      return 'Your session has expired. Please log in again.';
    }
    if (error is PostgrestException) {
      if (error.code == '23505') return 'This date already has a menu.';
      if (error.code == '42501') {
        return "You don't have permission to manage menus.";
      }
    }
    return AppError.message(error);
  }
}
