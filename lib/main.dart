import 'package:canteen_app/app/routes/app_routes.dart';
import 'package:canteen_app/core/services/supabase_service.dart';
import 'package:canteen_app/providers/auth_provider.dart';
import 'package:canteen_app/providers/employee_provider.dart';
import 'package:canteen_app/providers/profile_provider.dart';
import 'package:canteen_app/providers/vendor/vendor_home_provider.dart';
import 'package:canteen_app/providers/vendor/menu_provider.dart';
import 'package:canteen_app/views/auth/login/login_view.dart';
import 'package:canteen_app/views/auth/signup/signup_view.dart';
import 'package:canteen_app/views/home/empolyee_home_view.dart';
import 'package:canteen_app/views/employee/meal_history/meal_history_view.dart';
import 'package:canteen_app/views/employee/guest_meal/guest_meal_view.dart';
import 'package:canteen_app/views/employee/menus/employee_menus_view.dart';
import 'package:canteen_app/views/splash/splash_view.dart';
import 'package:canteen_app/views/vendor/dashboard/vendor_dashboard_view.dart';
import 'package:canteen_app/views/vendor/menus/add_menu_view.dart';
import 'package:canteen_app/views/vendor/menus/menus_view.dart';
import 'package:canteen_app/views/vendor/meals/vendor_meals_view.dart';
import 'package:canteen_app/views/profile/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:canteen_app/app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  debugPrint('Supabase connected');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => VendorHomeProvider()),
        ChangeNotifierProvider(create: (_) => VendorMenuProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),

      minTextAdapt: true,

      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,

          initialRoute: AppRoutes.splash,

          routes: {
            AppRoutes.splash: (context) => const SplashView(),
            AppRoutes.login: (context) => const LoginView(),

            AppRoutes.signup: (context) => const SignupView(),
            AppRoutes.employeeHome: (context) => const EmployeeHomeView(),
            AppRoutes.mealHistory: (context) => const MealHistoryView(),
            AppRoutes.guestMeal: (context) => const GuestMealView(),
            AppRoutes.employeeMenus: (context) => const EmployeeMenusView(),
            AppRoutes.vendorDashboard: (context) => const VendorDashboardView(),
            AppRoutes.vendorMenus: (context) => const VendorMenusView(),
            AppRoutes.vendorMeals: (context) => const VendorMealsView(),
            AppRoutes.addMenu: (context) => const AddMenuView(),
            AppRoutes.profile: (context) => const ProfileView(),
            AppRoutes.vendorProfile: (context) => const ProfileView(),
          },
        );
      },
    );
  }
}
