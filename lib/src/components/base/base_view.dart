import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/controller/base_controller/base_controller.dart';

abstract class BaseView<T extends BaseController> extends StatelessWidget {
  const BaseView({super.key});

  T get controller;
  Widget buildBody(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildBody(context),
        Obx(() {
          if (!Get.isRegistered<T>()) {
            return const SizedBox.shrink();
          }

          final bool isLoading = controller.isLoading.value;

          return isLoading
              ? Container(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.4),
                  child: const Center(
                    child: SpinKitCubeGrid(
                      color: Color(0xFF645CFF),
                      size: 50.0,
                    ),
                  ),
                )
              : const SizedBox.shrink();
        }),
      ],
    );
  }
}