import 'package:flutter_test/flutter_test.dart';
import 'package:craftai_studio_mobile/core/utils/permission_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPermissionHelper Unit Tests', () {
    test('pickImageSafely validates interface contract', () async {
      expect(AppPermissionHelper.ensureCameraPermission, isA<Function>());
      expect(AppPermissionHelper.pickImageSafely, isA<Function>());
      expect(AppPermissionHelper.showPermissionBlockedDialog, isA<Function>());
    });
  });
}

