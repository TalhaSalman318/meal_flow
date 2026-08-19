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
          routes: {AppRoutes.splash: (_) => const SplashView()},
        );
      },
    );
  }
}
