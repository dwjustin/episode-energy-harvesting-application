import 'package:permission_handler/permission_handler.dart';

Future<bool> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ].request();

  bool allGranted = true;
  statuses.forEach((permission, status) {
    if (!status.isGranted) {
      print('${permission.toString()} is not granted');
      allGranted = false;
    }
  });

  return allGranted;
}