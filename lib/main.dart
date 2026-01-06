import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/controller/auth_controller/link_service.dart';
import 'package:ivo_service_app/src/repo/profile_repo/profile_repo.dart';
import 'package:ivo_service_app/src/routes/app_pages.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:ivo_service_app/src/utils/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final String? messageId = message.data['id']?.toString();

  if (messageId != null) {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final orgId = prefs.getString('org_id');

    if (token != null && orgId != null) {
      final repo = ProfileRepository();

      await repo.updateStatus(
        orgId: orgId,
        token: token,
        messageId: messageId,
        received: true,
      );
      final profile = await repo.fetchProfile(orgId: orgId, token: token);

      if (profile != null) {
        final unreadCount = profile.messages
            .where((m) => m.readStatus == "0")
            .length;
        if (await AppBadgePlus.isSupported()) {
          AppBadgePlus.updateBadge(unreadCount);
        }
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Get.putAsync(() => LinkService().init());
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
    );
  }
}
