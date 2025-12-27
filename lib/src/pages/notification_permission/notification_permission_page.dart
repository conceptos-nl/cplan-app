import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/components/widgets/primary_button.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionPage extends StatefulWidget {
  const NotificationPermissionPage({super.key});

  @override
  State<NotificationPermissionPage> createState() =>
      _NotificationPermissionPageState();
}

class _NotificationPermissionPageState
    extends State<NotificationPermissionPage> {
  Future<void> _requestPermission() async {
    var status = await Permission.notification.status;

    if (!status.isGranted) {
      status = await Permission.notification.request();
    }

    if (status.isGranted) {
      _nextPage();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      _nextPage();
    }
  }

  void _nextPage() {
    final String nextRoute =
        Get.arguments as String? ?? AppRoutes.organizationCode;
    Get.offAllNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        size: 72,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  "Blijf op de hoogte",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  "Schakel meldingen in om aankondigingen van ons te ontvangen en te weten wanneer uw factuur gereed is",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.8,
                    ),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                PrimaryButton(
                  text: "Meldingen inschakelen",
                  onPressed: _requestPermission,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _nextPage,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                    foregroundColor: theme.textTheme.bodyMedium?.color,
                  ),
                  child: const Text(
                    "Nu niet",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
