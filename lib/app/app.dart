import 'package:canteen_app/views/auth/login/login_view.dart';
import 'package:canteen_app/views/employee/home/home_view.dart';
import 'package:canteen_app/views/vendor/dashboard/vendor_dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
            AppRoutes.splash: (_) => const SplashView(),

            AppRoutes.login: (_) => const LoginView(),
            AppRoutes.employeeHome: (_) => const HomeView(),

            AppRoutes.vendorDashboard: (_) => const VendorDashboardView(),
          },
        );
      },
    );
  }
}
