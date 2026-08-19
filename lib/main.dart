import 'package:canteen_app/app/app.dart';
import 'package:canteen_app/home_screen.dart';
import 'package:canteen_app/views/splash/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xhqndcvspzmfckhpbbtf.supabase.co',
    publishableKey: 'sb_publishable_QaEoXoHkml1q8BiJ0DGHDG_vYvuIv1k',
  );

  debugPrint('Supabase connected');

  runApp(const MyApp());
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

          home: const MealFlowApp(),
        );
      },
    );
  }
}
