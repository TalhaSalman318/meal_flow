class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';

  // Employee
  static const String employeeHome = '/employee/home';
  static const String meals = '/employee/meals';
  static const String mealHistory = '/employee/meal-history';
  static const String calendar = '/employee/calendar';
  static const String guestMeal = '/employee/guest-meal';
  static const String employeeMenus = '/employee/menus';
  static const String ledger = '/employee/ledger';
  static const String profile = '/employee/profile';

  // Vendor
  static const String vendorDashboard = '/vendor/dashboard';
  static const String vendorMenus = '/vendor/menus';
  static const String addMenu = '/vendor/add-menu';
  static const String vendorMeals = '/vendor/meals';
  static const String vendorOrders = '/vendor/orders';
  static const String vendorCalendar = '/vendor/calendar';
  static const String vendorEarnings = '/vendor/earnings';
  static const String vendorProfile = '/vendor/profile';
}
