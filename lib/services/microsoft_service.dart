import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'device_service.dart';

class MicrosoftLoginService {
  final String clientId = '1315eca5-7000-4be4-86ee-390086101071';
  final String redirectUri =
      'https://elprof-d9368.firebaseapp.com/__/auth/handler';
  final String tenantId = '5cf499ef-0906-4766-9e38-7b3e6fa8ed5f';
  final String scope = 'https://graph.microsoft.com/User.Read';
  final DeviceService _deviceService = DeviceService();

  // Define a callback to send cookies after successful login
  final Function(Map<String, String> cookies)? onLoginSuccess;

  MicrosoftLoginService({this.onLoginSuccess});

  Future<void> signInWithMicrosoft(BuildContext context) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // Hide loading dialog if it was shown
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Hide loading dialog
      }
      _showErrorDialog(context,
          'No internet connection. Please check your network settings.');
      return; // Exit the function if there's no network
    }

    final String authUrl =
        'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&scope=$scope';

    print("Opening Microsoft login dialog...");
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        InAppWebViewController? webViewController; // To hold the controller

        return AlertDialog(
          content: Container(
            width: double.maxFinite,
            height: 500,
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: Uri.parse(authUrl)),
              onWebViewCreated: (controller) {
                webViewController = controller; // Assign the controller
              },
              onLoadStop: (controller, url) async {
                print("Page loaded: $url");
                if (url.toString().startsWith(redirectUri)) {
                  Uri uri = Uri.parse(url.toString());
                  if (uri.queryParameters.containsKey('code')) {
                    String code = uri.queryParameters['code']!;
                    print("Authorization code received: $code");

                    // Close the dialog and perform the token exchange
                    Navigator.of(dialogContext).pop();

                    await _exchangeCodeForAccessToken(code, context);

                    // Clear the WebView data after the dialog is closed
                    await webViewController?.clearCache();
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _exchangeCodeForAccessToken(
      String code, BuildContext context) async {
    final String apiUrl = "https://new-folder-three-sage.vercel.app/api/auth";

    print('DEBUG: Exchanging code for access token...');
    try {
      final response = await http.post(
        Uri.parse(
            'https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'scope': scope,
        },
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        String accessToken = responseData['access_token'];

        // Send token and cookies back via the callback function
        await _sendEncodedTokenAndUrl(accessToken, context);
      } else {
        throw Exception('Failed to obtain access token: ${response.body}');
      }
    } catch (e) {
      print('DEBUG: Error during token exchange: $e');
      throw e;
    }
  }

  Future<void> _sendEncodedTokenAndUrl(
      String accessToken, BuildContext context) async {
    final String apiUrl =
        "https://moodle-login.vercel.app/api/moodle-login-microsoft";
    String? deviceId = await _deviceService.getDeviceId();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': accessToken,
          'moodleUrl': "https://lms.elprof.cloud",
          'device_id': deviceId,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};

        Map<String, String> cookies = {};
        try {
          cookies = {
            'MoodleSession': responseBody['cookies'].firstWhere(
                (cookie) => cookie['key'] == 'MoodleSession')['value']
          };
        } catch (e) {
          print("MoodleSession cookie not found.");
        }

        if (onLoginSuccess != null) {
          onLoginSuccess!(cookies); // Pass the cookies
        }
      } else {
        if (response.statusCode == 403) {
          _showDeviceMismatchPrompt(context);
        }
      }
    } catch (e) {
      print("An error occurred: $e");
      // Handle the error gracefully
    }
  }

  void _showDeviceMismatchPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Device Mismatch'),
          content: Text(
              'Your current device does not allowed to login. Please use the other one.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
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
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
