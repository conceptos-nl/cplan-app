import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ivo_service_app/src/controller/profile_controller/profile_controller.dart';
import 'package:ivo_service_app/src/model/profile_model/profile_model.dart';
import 'package:ivo_service_app/src/routes/app_pages.dart';
import 'package:ivo_service_app/src/routes/app_routes.dart';

const _subject = 'U heeft nog een factuur openstaan';

ProfileModel _profile({bool withMessage277 = true}) => ProfileModel.fromJson({
      'success': true,
      'messages': [
        if (withMessage277)
          {
            'id': '277',
            'subject': _subject,
            'body': 'Beste heer/mevrouw',
            'date': '2026-02-19 14:30:52',
            'read': '0',
          },
      ],
    });

/// No network, no lifecycle hooks: just a profile and a scripted reload.
class _FakeProfileController extends ProfileController {
  _FakeProfileController(ProfileModel initial, {this.afterReload}) {
    profile.value = initial;
  }

  final ProfileModel? afterReload;
  int reloads = 0;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  // ignore: must_call_super
  void onClose() {}

  @override
  Future<void> markMessageAsRead(String messageId) async {}

  @override
  Future<void> fetchUserProfile({bool showLoading = true}) async {
    reloads++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (afterReload != null) profile.value = afterReload;
  }
}

Future<_FakeProfileController> _openFromPush(
  WidgetTester tester,
  _FakeProfileController controller,
) async {
  Get.put<ProfileController>(controller);
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: '/start',
      getPages: [
        GetPage(name: '/start', page: () => const Scaffold()),
        ...AppPages.routes.where(
          (r) => r.name.startsWith(AppRoutes.messageDetail),
        ),
      ],
    ),
  );
  // Exactly what NotificationService does on a tap: no arguments.
  Get.toNamed('${AppRoutes.messageDetail}/277');
  await tester.pump();
  await tester.pump();
  return controller;
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('push for a loaded message shows it', (tester) async {
    await _openFromPush(tester, _FakeProfileController(_profile()));
    await tester.pumpAndSettle();

    expect(find.text(_subject), findsOneWidget);
  });

  testWidgets('still shows it after a later navigation resets Get.parameters',
      (tester) async {
    final controller =
        await _openFromPush(tester, _FakeProfileController(_profile()));
    await tester.pumpAndSettle();

    Get.parameters = {}; // what any other named navigation does
    controller.profile.value = _profile(); // e.g. the post-read refresh
    await tester.pumpAndSettle();

    expect(find.text(_subject), findsOneWidget);
    expect(find.text('Bericht niet gevonden'), findsNothing);
  });

  testWidgets('message newer than the loaded list: spinner, reload, message',
      (tester) async {
    final controller = await _openFromPush(
      tester,
      _FakeProfileController(
        _profile(withMessage277: false),
        afterReload: _profile(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Bericht niet gevonden'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text(_subject), findsOneWidget);
    expect(controller.reloads, 1);
  });

  testWidgets('unknown message: one reload, then "Bericht niet gevonden"',
      (tester) async {
    final controller = await _openFromPush(
      tester,
      _FakeProfileController(_profile(withMessage277: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bericht niet gevonden'), findsOneWidget);
    expect(controller.reloads, 1);
  });
}
