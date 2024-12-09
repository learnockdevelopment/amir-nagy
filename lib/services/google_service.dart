import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../pages/webview.dart';
import 'device_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['profile', 'email']);
  final DeviceService _deviceService = DeviceService();
  bool _isLoading = false;

  Future<Map<String, String>> signInWithGoogle(BuildContext context) async {
    await Firebase.initializeApp();

    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      _dismissLoadingDialog(context);
      _showErrorDialog(
          context, 'لا توجد اتصال بالإنترنت. يرجى التحقق من إعدادات الشبكة.');
      return {};
    }

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();

      if (googleSignInAccount == null) {
        return {};
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;
      _showLoadingDialog(context);

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (googleSignInAuthentication.idToken != null) {
        String idToken = googleSignInAuthentication.idToken!;
        Map<String, String> cookieMap =
            await _sendEncodedTokenAndUrl(idToken, context);
        _dismissLoadingDialog(context);

        if (cookieMap.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewExample(
                targetUrl: 'https://lms.elprof.cloud',
                cookies: cookieMap,
              ),
            ),
          );
          return cookieMap;
        }
      }
    } catch (error) {
      _dismissLoadingDialog(context);
      _showErrorDialog(context, 'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى.');
    }
    return {};
  }

  Future<Map<String, String>> _sendEncodedTokenAndUrl(
      String idToken, BuildContext context) async {
    final String apiUrl =
        "https://moodle-login.vercel.app/api/moodle-login-google";
    _showLoadingDialog(context);
    String? deviceId = await _deviceService.getDeviceId();

    Map<String, String> cookiesMap = {};

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idToken': idToken,
            'moodleUrl': "https://lms.elprof.cloud",
            'device_id': deviceId,
          }),
        );

        if (response.statusCode == 200) {
          await _googleSignIn.signOut();
          final responseBody = jsonDecode(response.body);
          List<dynamic> cookiesList = responseBody['cookies'];

          cookiesMap = {
            for (var cookie in cookiesList) cookie['key']: cookie['value']
          };
          return cookiesMap;
        } else if (response.statusCode == 403) {
          final responseJson =
              jsonDecode(response.body) as Map<String, dynamic>;

          if (responseJson['error'] == 'Device mismatch detected') {
            _dismissLoadingDialog(context);
            _showDeviceMismatchPrompt(context);
            return {};
          }
        } else if (response.statusCode == 500 || response.statusCode == 404) {
          await Future.delayed(Duration(seconds: 1));
          continue;
        } else {
          _dismissLoadingDialog(context);
          return cookiesMap;
        }
      } catch (error) {
        _dismissLoadingDialog(context);
        _showErrorDialog(context, 'حدث خطأ في الشبكة. يرجى المحاولة مرة أخرى.');
        return cookiesMap;
      }
    }

    _dismissLoadingDialog(context);
    return cookiesMap;
  }

  void _showLoadingDialog(BuildContext context) {
    if (!_isLoading) {
      _isLoading = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber)),
                SizedBox(width: 20),
                Text('جاري تسجيل الدخول...'),
              ],
            ),
          );
        },
      );
    }
  }

  void _dismissLoadingDialog(BuildContext context) {
    if (_isLoading) {
      _isLoading = false;
      Navigator.of(context).pop();
    }
  }

  void _showDeviceMismatchPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تم اكتشاف عدم تطابق الجهاز'),
          content: Text(
              'لا يمكنك تسجيل الدخول باستخدام هذا الجهاز. يرجى استخدام جهاز آخر.'),
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
