import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_android_developer_mode/flutter_android_developer_mode.dart';
import 'package:amir/pages/warning.dart';
import 'package:root_checker_plus/root_checker_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:amir/pages/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp();
}

Future<void> initializeApp() async {
  // await screenRestrictions();
  bool isEmulator = await checkIfEmulator();
  bool isRooted = await checkIfRooted();

  runApp(MyApp(
    isEmulator: isEmulator,
    isRooted: isRooted,
  ));
}

// Future<void> screenRestrictions() async {
//   await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
// }

Future<bool> checkIfEmulator() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return !androidInfo.isPhysicalDevice;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return !iosInfo.isPhysicalDevice;
  }
  return false;
}

Future<bool> checkIfDeveloperModeEnabled() async {
  try {
    return await FlutterAndroidDeveloperMode.isAndroidDeveloperModeEnabled;
  } catch (e) {
    return false;
  }
}

Future<bool> checkIfRooted() async {
  if (Platform.isAndroid) {
    return await _checkAndroidRooted();
  } else {
    return false;
  }
}

Future<bool> _checkAndroidRooted() async {
  try {
    bool isRooted = (await RootCheckerPlus.isRootChecker())!;
    bool isDevMode = (await RootCheckerPlus.isDeveloperMode())!;
    return isRooted || isDevMode;
  } catch (e) {
    return false;
  }
}

Future<String> getAppVersion() async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return info.version;
}

bool isVersionSupported(String currentVersion, String minRequiredVersion) {
  return currentVersion.compareTo(minRequiredVersion) >= 0;
}

class MyApp extends StatelessWidget {
  final bool isEmulator;
  final bool isRooted;

  const MyApp({
    Key? key,
    required this.isEmulator,
    required this.isRooted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ُAmir Nagy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: _getHomePage(),
    );
  }

  Widget _getHomePage() {
    if (isEmulator || isRooted) {
      return WarningPage(); // Show WarningPage for invalid conditions
    } else {
      return SplashScreen();
    }
  }
}
