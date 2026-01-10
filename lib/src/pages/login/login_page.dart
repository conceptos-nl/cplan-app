import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/components/widgets/custom_text_field.dart';
import 'package:ivo_service_app/src/components/widgets/primary_button.dart';
import 'package:ivo_service_app/src/controller/auth_controller/auth_controller.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _accessCodeController = TextEditingController();
  final AuthController controller = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final String? orgCodeArg = Get.arguments as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inloggen"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Obx(() {
          final org = controller.organization.value;
          final isLoading = controller.isLoading.value;
          final orgReady = org != null;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (orgReady) ...[
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(org.logo),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          org.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  Text(
                    "Hallo",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                Text(
                  "Voer uw klantnummer en toegangscode in om u aan te melden bij uw account",
                  textAlign: orgReady ? TextAlign.center : TextAlign.start,
                ),

                const SizedBox(height: 32),

                CustomTextField(
                  controller: _userIdController,
                  label: "Klantnummer",
                  placeholder: "Vul uw klantnummer in",
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _accessCodeController,
                  label: "Code",
                  placeholder: "Vul uw toegangscode in",
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),

                const SizedBox(height: 40),
                PrimaryButton(
                  text: "Volgende",
                  onPressed: (!orgReady || isLoading)
                      ? null
                      : () async {
                          final success = await controller.login(
                            _userIdController.text.trim(),
                            _accessCodeController.text.trim(),
                            explicitOrgCode: orgCodeArg,
                          );
                          if (!success) {
                            _accessCodeController.clear();
                          }
                        },
                ),

                const SizedBox(height: 24),
              ],
            ).paddingAll(24),
          );
        }),
      ),
    );
  }
}
