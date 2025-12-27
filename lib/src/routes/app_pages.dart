import 'package:get/get.dart';
import 'package:ivo_service_app/src/pages/contact/contact_page.dart';
import 'package:ivo_service_app/src/pages/home/home_page.dart';
import 'package:ivo_service_app/src/pages/invoice_detail/invoice_detail_page.dart';
import 'package:ivo_service_app/src/pages/invoices/invoices_page.dart';
import 'package:ivo_service_app/src/pages/login/login_page.dart';
// import 'package:ivo_service_app/src/pages/notification_permission/notification_permission_page.dart';
import 'package:ivo_service_app/src/pages/notifications/message_detail_page.dart';
import 'package:ivo_service_app/src/pages/notifications/notification_page.dart';
import 'package:ivo_service_app/src/pages/organization_code/organization_code_page.dart';
import 'package:ivo_service_app/src/pages/profile/profile_page.dart';
import 'package:ivo_service_app/src/pages/schedule_list/schedule_list_page.dart';
import 'package:ivo_service_app/src/pages/splash/splash_page.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;
  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(name: AppRoutes.home, page: () => HomePage()),
    GetPage(name: AppRoutes.login, page: () => LoginPage()),
    GetPage(name: AppRoutes.invoiceList, page: () => InvoicesPage()),
    GetPage(name: AppRoutes.invoiceDetail, page: () => InvoiceDetailPage()),
    GetPage(name: AppRoutes.notifications, page: () => NotificationPage()),
    GetPage(
      name: '${AppRoutes.messageDetail}/:id',
      page: () => MessageDetailPage(),
      transition: Transition.cupertino,
    ),
    GetPage(name: AppRoutes.scheduleList, page: () => ScheduleListPage()),
    // GetPage(
    //   name: AppRoutes.notificationPermission,
    //   page: () => NotificationPermissionPage(),
    // ),
    GetPage(
      name: AppRoutes.organizationCode,
      page: () => OrganizationCodePage(),
    ),
    GetPage(name: AppRoutes.profile, page: () => ProfilePage()),
    GetPage(name: AppRoutes.contactOrganization, page: () => ContactPage()),
  ];
}
