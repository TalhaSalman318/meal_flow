import 'package:canteen_app/views/auth/login/login_view.dart';
import 'package:canteen_app/views/auth/signup/signup_view.dart';
import 'package:canteen_app/views/home/empolyee_home_view.dart';
import 'package:canteen_app/views/employee/meal_history/meal_history_view.dart';
import 'package:canteen_app/views/employee/guest_meal/guest_meal_view.dart';
import 'package:canteen_app/views/vendor/dashboard/vendor_dashboard_view.dart';
import 'package:canteen_app/views/vendor/meals/vendor_meals_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../views/employee/menus/employee_menus_view.dart';

import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import '../views/splash/splash_view.dart';

class MealFlowApp extends StatelessWidget {
  const MealFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MealFlow',
          theme: AppTheme.lightTheme,

          initialRoute: AppRoutes.splash,

          routes: {
            // =====================================================
            // AUTH
            // =====================================================
            AppRoutes.splash: (_) => const SplashView(),

            AppRoutes.login: (_) => const LoginView(),

            AppRoutes.signup: (_) => const SignupView(),

            // =====================================================
            // EMPLOYEE
            // =====================================================
            AppRoutes.employeeHome: (_) => const EmployeeHomeView(),
            AppRoutes.mealHistory: (_) => const MealHistoryView(),
            AppRoutes.guestMeal: (_) => const GuestMealView(),
            AppRoutes.employeeMenus: (_) => const EmployeeMenusView(),

            // =====================================================
            // VENDOR
            // =====================================================
            AppRoutes.vendorDashboard: (_) => const VendorDashboardView(),
            AppRoutes.vendorMeals: (_) => const VendorMealsView(),
          },
        );
      },
    );
  }
}
