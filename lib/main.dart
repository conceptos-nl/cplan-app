import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/controller/auth_controller/notification_service.dart';
import 'package:ivo_service_app/src/controller/auth_controller/link_service.dart';
import 'package:ivo_service_app/src/controller/splash_controller/splash_controller.dart';
import 'package:ivo_service_app/src/routes/app_pages.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:ivo_service_app/src/utils/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Get.putAsync(() => NotificationService().init(), permanent: true);
    await Get.putAsync(() => LinkService().init(), permanent: true);
    Get.put(SplashController(), permanent: true);
  } catch (e) {
    debugPrint("Global Service initialization failure: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Glazenwasser',
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('Page not found')),
        ),
      ),
    );
  }
}