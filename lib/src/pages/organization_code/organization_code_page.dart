import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/components/base/base_view.dart';
import 'package:ivo_service_app/src/components/widgets/custom_text_field.dart';
import 'package:ivo_service_app/src/components/widgets/primary_button.dart';
import 'package:ivo_service_app/src/controller/auth_controller/auth_controller.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';

class OrganizationCodePage extends BaseView<AuthController> {
  OrganizationCodePage({super.key});

  @override
  final AuthController controller = Get.put(AuthController());

  @override
  Widget buildBody(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        automaticallyImplyActions: false,
        title: const Text("Mijn glazenwasser"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Voer de code van uw glazenwasser in",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Voer de unieke code in die u van uw glazenwasser heeft ontvangen om uw account te koppelen",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: controller.codeController,
                            label: "Code van de glazenwasser",
                            placeholder: "Code hier invoeren",
                            prefixIcon: Icons.domain,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(5),
                            ],
                            onChanged: (val) {
                              if (val.length == 5) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                controller.fetchOrg(val.trim());
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 54,
                          width: 54,
                          child: Obx(
                            () => ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundColor: colorScheme.primary,
                                elevation: 0,
                              ),
                              onPressed: controller.isLoading.value
                                  ? null
                                  : () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      controller.fetchOrg(
                                        controller.codeController.text.trim(),
                                      );
                                    },
                              child: controller.isLoading.value
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Icon(Icons.search, size: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    Obx(() {
                      final org = controller.organization.value;
                      if (org == null) return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 30),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "U meldt zich aan bij:",
                              style: theme.textTheme.labelMedium,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  height: 56,
                                  width: 56,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                    image: org.logo.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(org.logo),
                                            fit: BoxFit.cover,
                                            onError: (_, _) {},
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        org.name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            size: 16,
                                            color: Colors.green.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Organisatie geverifieerd",
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: Colors.green.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    const Spacer(),

                    Obx(
                      () => PrimaryButton(
                        text: "Volgende",
                        isLoading: controller.isLoading.value,
                        onPressed: (controller.organization.value == null)
                            ? null
                            : () async {
                                Get.toNamed(
                                  AppRoutes.login,
                                  arguments: controller.codeController.text
                                      .trim(),
                                );
                              },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}
