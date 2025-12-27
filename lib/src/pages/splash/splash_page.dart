import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/controller/splash_controller/splash_controller.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashController());

    return Scaffold(
      backgroundColor: const Color(0xFF645CFF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF645CFF), Color(0xFF8C52FF)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/app_logo_white.png',
                width: 220,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
