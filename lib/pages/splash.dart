import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'webview.dart'; // Import your WebView page
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http; // Add this import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Offset _splashOffset = const Offset(0, 0);
  Offset _progressBarOffset = const Offset(0, 0);
  Offset _smallLogoOffset = const Offset(0, 0);


  @override
  void initState() {
    super.initState();
    // Check login status after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    final cookiesData = await readCookies();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if cookies exist and are valid
    if (cookiesData != null && cookiesData['cookies'].isNotEmpty) {
      // Convert dynamic keys and values to String
      Map<String, String> stringCookies = (cookiesData['cookies'] as Map).map(
            (key, value) => MapEntry(key.toString(), value.toString()),
      );

      // Check if cookies are still valid
      final bool validCookies = await _checkCookieValidity(stringCookies);

      if (validCookies) {
        // Retrieve the last saved URL or use default if not found
        String? lastPage = prefs.getString('savedUrl');

        // If lastPage is null or empty, redirect to login page
        if (lastPage == null || lastPage.isEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        } else {
          // Navigate to WebView with the last page
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
        // Cookies are invalid, go to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } else {
      // No cookies, go to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }


  Future<void> _logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);  // Set login state to false
    await _clearCookies();  // Clear cookies on logout
  }

  Future<void> _clearCookies() async {
    final file = await _cookieFile;
    if (await file.exists()) {
      await file.delete();  // Remove the cookies file
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _splashOffset += details.delta;
                });
              },
              child: Center(
                child: Transform.translate(
                  offset: _splashOffset,
                  child: Image.asset(
                    'assets/splash.png',
                    height: 160,
                    width: 300,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 520,
              left: MediaQuery.of(context).size.width / 2 - 100,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _progressBarOffset += details.delta;
                  });
                },
                child: Transform.translate(
                  offset: _progressBarOffset,
                  child: SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      color: Color(0xFFffd800),
                      backgroundColor: Colors.grey.withOpacity(0.5),
                      value: null,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: 50,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _smallLogoOffset += details.delta;
                  });
                },
                child: Transform.translate(
                  offset: _smallLogoOffset,
                  child: Image.asset(
                    'assets/small.png',
                    height: 100,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
