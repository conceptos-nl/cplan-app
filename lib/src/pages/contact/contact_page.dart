import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/components/app_bottom_bar/app_bottom_bar.dart';
import 'package:ivo_service_app/src/components/base/base_view.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends BaseView<ProfileController> {
  const ContactPage({super.key});

  @override
  ProfileController get controller => Get.find<ProfileController>();

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        Get.snackbar("Fout", "Kon de link niet openen");
      }
    } catch (e) {
      Get.snackbar("Fout", "Er is iets misgegaan");
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact & Informatie"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      bottomNavigationBar: const AppBottomBar(currentIndex: 4),
      body: Obx(() {
        final org = controller.organization.value;

        if (controller.isLoading.value && org == null) {
          return const SizedBox.shrink();
        }
        if (org == null) {
          return const Center(child: Text("Geen organisatiegegevens gevonden"));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (org.logo.isNotEmpty) ...[
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: NetworkImage(org.logo),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      org.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (org.phone.isNotEmpty || org.email.isNotEmpty) ...[
                _buildSectionHeader(context, "CONTACTGEGEVENS"),
                _buildMenuCard(context, [
                  if (org.phone.isNotEmpty)
                    _buildInfoTile(
                      context,
                      icon: Icons.phone_outlined,
                      label: "Telefoonnummer",
                      value: org.phone,
                    ),
                  if (org.phone.isNotEmpty && org.email.isNotEmpty)
                    _buildDivider(context),
                  if (org.email.isNotEmpty)
                    _buildInfoTile(
                      context,
                      icon: Icons.email_outlined,
                      label: "E-mailadres",
                      value: org.email,
                    ),
                ]),
                const SizedBox(height: 24),
              ],

              if (org.address.isNotEmpty) ...[
                _buildSectionHeader(context, "ADRES"),
                _buildMenuCard(context, [
                  _buildInfoTile(
                    context,
                    icon: Icons.location_on_outlined,
                    label: "Adres",
                    value: org.address,
                  ),
                  _buildDivider(context),
                  _buildInfoTile(
                    context,
                    icon: Icons.map_outlined,
                    label: "Postcode & Plaats",
                    value: "${org.postal}, ${org.city}",
                  ),
                ]),
                const SizedBox(height: 24),
              ],

              if (org.coc.isNotEmpty || org.bankAccount.isNotEmpty) ...[
                _buildSectionHeader(context, "ZAKELIJKE GEGEVENS"),
                _buildMenuCard(context, [
                  if (org.coc.isNotEmpty)
                    _buildInfoTile(
                      context,
                      icon: Icons.business_center_outlined,
                      label: "KvK nummer",
                      value: org.coc,
                    ),
                  if (org.coc.isNotEmpty &&
                      (org.vat.isNotEmpty || org.bankAccount.isNotEmpty))
                    _buildDivider(context),
                  if (org.vat.isNotEmpty)
                    _buildInfoTile(
                      context,
                      icon: Icons.gavel_outlined,
                      label: "BTW nummer",
                      value: org.vat,
                    ),
                  if (org.vat.isNotEmpty && org.bankAccount.isNotEmpty)
                    _buildDivider(context),
                  if (org.bankAccount.isNotEmpty)
                    _buildInfoTile(
                      context,
                      icon: Icons.account_balance_outlined,
                      label: "IBAN",
                      value: org.bankAccount,
                    ),
                ]),
                const SizedBox(height: 32),
              ],

              if (org.isContactActive && org.whatsappUrl.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(org.whatsappUrl),
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Neem contact op",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
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
