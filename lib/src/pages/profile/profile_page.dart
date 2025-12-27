import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/components/app_bottom_bar/app_bottom_bar.dart';
import 'package:ivo_service_app/src/components/base/base_view.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfilePage extends BaseView<ProfileController> {
  const ProfilePage({super.key});

  @override
  ProfileController get controller => Get.find<ProfileController>();

  @override
  Widget buildBody(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final customer = controller.profile.value?.customer;

      if (controller.isLoading.value && customer == null) {
        return const Scaffold(body: SizedBox.shrink());
      }
      if (customer == null) {
        return const Scaffold(
          body: Center(child: Text("Geen gegevens gevonden")),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text("Mijn gegevens"),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        bottomNavigationBar: const AppBottomBar(currentIndex: 5),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        _getInitials(customer.name),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Klant #${customer.id}",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSectionHeader(context, "CONTACTGEGEVENS & ADRES"),
              _buildMenuCard(context, [
                _buildInfoTile(
                  context,
                  icon: Icons.phone_outlined,
                  label: "Telefoonnummer",
                  value: customer.phone.isNotEmpty ? customer.phone : "-",
                ),
                _buildDivider(context),
                _buildInfoTile(
                  context,
                  icon: Icons.location_on_outlined,
                  label: "Straat",
                  value:
                      "${customer.address} ${customer.number} ${customer.floor}"
                          .trim(),
                ),
                _buildDivider(context),
                _buildInfoTile(
                  context,
                  icon: Icons.map_outlined,
                  label: "Postcode & Plaats",
                  value: "${customer.postal}, ${customer.city}",
                ),
              ]),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: controller.logout,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: colorScheme.error.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    "Uitloggen",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? "1.0.0";
                  return Text(
                    "Versie $version",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    });
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "";
    List<String> parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return name.length > 1
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.theme.disabledColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, List<Widget> children) {
    final theme = context.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: theme.iconTheme.color, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(height: 1, color: context.theme.dividerColor);
  }
}
