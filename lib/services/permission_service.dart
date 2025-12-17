import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> checkCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
