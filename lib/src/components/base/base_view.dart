import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

abstract class BaseView<T extends GetxController> extends StatelessWidget {
  const BaseView({super.key});

  T get controller;
  Widget buildBody(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildBody(context),
        Obx(() {
          final bool isLoading = (controller as dynamic).isLoading.value;

          return isLoading
              ? Container(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.4),
                  child: const Center(
                    child: Center(
                      child: SpinKitCubeGrid(
                        color: Color(0xFF645CFF),
                        size: 50.0,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink();
        }),
      ],
    );
  }
}
