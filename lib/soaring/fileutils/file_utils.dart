

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// Used to check for directory access for tunpoint(s) import/export to download directory
// Just relevant for Android, iOS no issue
// Note Android 30+ can't see files in Downloads (say to import into another phone app)
// Can only see via Android file transfer :(
Future<void> checkFileAccess({required Function permissionGrantedFunction,
  required Function requestPermissionFunction,
  required Function permissionDeniedFunction}) async {
  if (Platform.isIOS ){
    permissionGrantedFunction();
    return;
  }
  PermissionStatus status;
  if (Platform.isAndroid) {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    final AndroidDeviceInfo info = await deviceInfoPlugin.androidInfo;
    if ((info.version.sdkInt) >= 30) {
      permissionGrantedFunction();
      return;
    } else {
      status = await Permission.storage.request();
    }
  } else {
    status = await Permission.storage.request();
  }
  //var status = await Permission.storage.status;
  if (status == PermissionStatus.denied) {
    var statusGranted = await Permission.storage.request().isGranted;
    // We didn't ask for permission yet or the permission has been denied before but not permanently.
    if (statusGranted) {
      // Fire event to export turnpoints
      permissionGrantedFunction();
    } else {
      permissionDeniedFunction();
    }
  }
  if (status == PermissionStatus.permanentlyDenied) {
    // display msg to user they need to go to settings to re-enable
   permissionDeniedFunction;
  }
  if (status == PermissionStatus.granted) {
    permissionGrantedFunction();
  }
}