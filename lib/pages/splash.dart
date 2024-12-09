import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'webview.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check login status after 3 seconds
    Future.delayed(const Duration(seconds: 3), _checkLoginStatus);
  }

  Future<void> _checkLoginStatus() async {
    final cookiesData = await readCookies();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (cookiesData != null && cookiesData['cookies'].isNotEmpty) {
      Map<String, String> stringCookies = (cookiesData['cookies'] as Map)
          .map((key, value) => MapEntry(key.toString(), value.toString()));

      final bool validCookies = await _checkCookieValidity(stringCookies);

      if (validCookies) {
        String? lastPage = prefs.getString('savedUrl');
        if (lastPage == null || lastPage.isEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewExample(
                targetUrl: lastPage,
                cookies: stringCookies,
              ),
            ),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  Future<Map<String, dynamic>?> readCookies() async {
    try {
      final file = await _cookieFile;
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      return null;
    }
  }

  Future<File> get _cookieFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/cookies.json');
  }

  Future<bool> _checkCookieValidity(Map<String, String> cookies) async {
    try {
      final response = await http.get(
        Uri.parse('https://lms.amirnagy.com/check-session'),
        headers: cookies,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(), // Pushes the logo to the center vertically
            Center(
              child: Image.asset(
                'assets/splash.png',
                height: 210,
                width: 250,
              ),
            ),
            const SizedBox(height: 30), // Space between logo and progress bar
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                color: Colors.blue[900],
                backgroundColor: Colors.grey.withOpacity(0.5),
              ),
            ),
            Spacer(), // Pushes the progress bar up slightly to balance spacing
          ],
        ),
      ),
    );
  }
}
