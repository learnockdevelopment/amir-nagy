import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../pages/webview.dart';
import 'device_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EmailLoginService {
  final DeviceService _deviceService = DeviceService();

  Future<void> login({
    required String email,
    required String password,
    required String targetUrl,
    required BuildContext context,
  }) async {
    final loginUrl =
        Uri.parse('https://moodle-login.vercel.app/api/moodle-login');
    String? deviceId = await _deviceService.getDeviceId();

    // Check for network connectivity
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // Hide loading dialog if it was shown
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Hide loading dialog
      }
      _showErrorDialog(context,
          'لا يوجد اتصال بالإنترنت. يرجى التحقق من إعدادات الشبكة الخاصة بك.');
      return; // Exit the function if there's no network
    }

    // Initialize ValueNotifier and show loading dialog
    final messageNotifier = ValueNotifier<String>("جاري تسجيل الدخول...");
    _showLoadingDialog(context, messageNotifier);

    try {
      final loginFormValues = {
        'username': email,
        'password': password,
        'url': targetUrl,
        'device_id': deviceId,
      };

      var response = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginFormValues),
      );

      _handleResponse(response, targetUrl, context, messageNotifier);
    } catch (e) {
      // Hide loading dialog if it was shown
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Hide loading dialog
      }
      _showErrorDialog(context, 'حدث خطأ: $e');
    }
  }

  void _handleResponse(http.Response response, String targetUrl,
      BuildContext context, ValueNotifier<String> messageNotifier) {
    // Hide loading dialog
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // Hide loading dialog
    }

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['message'] == 'Login successful') {
        final cookies = responseJson['cookies'] as List<dynamic>;
        Map<String, String> cookieMap = {
          for (var cookie in cookies) cookie['key']: cookie['value']
        };

        // Proceed to WebView with cookies
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) =>
                WebViewExample(targetUrl: targetUrl, cookies: cookieMap),
          ));
        });
      } else {
        // _showErrorDialog(context, 'Unexpected response: ${responseJson['message']}');
      }
    } else if (response.statusCode == 403) {
      _showDeviceMismatchPrompt(context);
    } else if (response.statusCode == 401) {
      _showInvalidLoginCredentialsPrompt(context);
    } else {
      _showErrorDialog(context, 'خطأ في الخادم');
    }
  }

  void _showLoadingDialog(
      BuildContext context, ValueNotifier<String> messageNotifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber)),
              SizedBox(width: 20),
              ValueListenableBuilder<String>(
                valueListenable: messageNotifier,
                builder: (context, message, child) {
                  return Text(message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeviceMismatchPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تعارض في الجهاز'),
          content: Text(
              'الجهاز الحالي غير مسموح له بتسجيل الدخول. يرجى استخدام جهاز آخر.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('موافق'),
            ),
          ],
        );
      },
    );
  }

  void _showInvalidLoginCredentialsPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('بيانات تسجيل الدخول غير صحيحة'),
          content: Text(
              'بيانات تسجيل الدخول الخاصة بك غير صحيحة. يرجى التحقق من اسم المستخدم وكلمة المرور الخاصة بك.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('موافق'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('خطأ'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('موافق'),
            ),
          ],
        );
      },
    );
  }
}
