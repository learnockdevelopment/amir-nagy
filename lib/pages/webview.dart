import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'network.dart';
import 'login.dart';

class WebViewExample extends StatefulWidget {
  final String targetUrl;
  final Map<String, String> cookies;

  WebViewExample({required this.targetUrl, required this.cookies});

  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> with WidgetsBindingObserver {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  final CookieManager _cookieManager = CookieManager.instance();
  String _currentUrl = '';
  DateTime? lastPressed;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebView();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        _showNoNetworkDialog();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initializeWebView() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showNoNetworkDialog();
      return;
    }

    // Retrieve saved cookies from SharedPreferences
    Map<String, String> savedCookies = await _loadSavedCookies();

    // Combine saved cookies with initial cookies from the widget
    Map<String, String> combinedCookies = Map.from(widget.cookies);
    combinedCookies.addAll(savedCookies);

    // Set cookies in the WebView
    await _setCookies(combinedCookies);

    // Load the target URL
    _webViewController?.loadUrl(urlRequest: URLRequest(url: Uri.parse(widget.targetUrl)));
  }

  Future<void> _setCookies(Map<String, String> cookies) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var entry in cookies.entries) {
      await _cookieManager.setCookie(
        url: Uri.parse(widget.targetUrl),
        name: entry.key,
        value: entry.value,
      );
      // Save cookies in SharedPreferences
      prefs.setString(entry.key, entry.value);
    }
  }

  Future<Map<String, String>> _loadSavedCookies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, String> cookies = {};

    // Retrieve all saved cookies from SharedPreferences
    for (String key in prefs.getKeys()) {
      String? value = prefs.getString(key);
      if (value != null) {
        cookies[key] = value;
      }
    }

    return cookies;
  }

  Future<bool> _onWillPop() async {
    if (await _webViewController?.canGoBack() ?? false) {
      _webViewController?.goBack();
      return Future.value(false);
    } else {
      DateTime now = DateTime.now();
      if (lastPressed == null || now.difference(lastPressed!) > Duration(seconds: 2)) {
        lastPressed = now;
        Fluttertoast.showToast(msg: 'Press again to exit');
        return Future.value(false);
      }
      return Future.value(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      InAppWebView(
                        initialUrlRequest: URLRequest(url: Uri.parse(widget.targetUrl)),
                        onWebViewCreated: (controller) {
                          _webViewController = controller;
                        },
                        onLoadStart: (controller, url) {
                          setState(() {
                            _isLoading = true;
                            _currentUrl = url.toString();
                          });
                        },
                        onLoadStop: (controller, url) {
                          setState(() {
                            _isLoading = false;
                            _currentUrl = url.toString();
                          });
                          _saveCurrentUrl(_currentUrl);
                        },
                        onProgressChanged: (controller, progress) {
                          setState(() {
                            _isLoading = progress < 100;
                          });
                        },
                      ),
                      if (_isLoading)
                        Positioned(
                          bottom: 34,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            color: Colors.amber,
                            child: LinearProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                              backgroundColor: Colors.yellow,
                            ),
                          ),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 7,
                            color: Colors.amber,
                            width: MediaQuery.of(context).size.width,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: MediaQuery.of(context).size.width / 2,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width / 2,
                                    height: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                Align(
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 500),
                                    width: _isLoading ? MediaQuery.of(context).size.width : 0,
                                    height: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 17,
                            color: Colors.yellow,
                            child: Row(
                              children: [
                                _buildNavText('تسجيل خروج'),
                                _buildNavText('الملف الشخصي'),
                                _buildNavText('لوحة التحكم'),
                                _buildNavText('التقويم'),
                                _buildNavText('المقررات المتاحة'),
                              ],
                            ),
                          ),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/bar.jpeg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildIcon('assets/logout.svg', '', isLogout: true),
                                _buildIcon('assets/profile.svg', 'https://lms.amirnagy.com/user/profile.php'),
                                _buildIcon('assets/dashboard.svg', 'https://lms.amirnagy.com/my/'),
                                _buildIcon('assets/calendar.svg', 'https://lms.amirnagy.com/calendar/view.php?view=month'),
                                _buildIcon('assets/courses.svg', 'https://lms.amirnagy.com/course/'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveCurrentUrl(String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedUrl', url);
  }

  Widget _buildNavText(String text) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.yaldevi(
            textStyle: TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String assetPath, String url, {bool isLogout = false}) {
    bool isSelected = _currentUrl == url && !isLogout;
    return Expanded(
      child: InkWell(
        onTap: () async {
          if (await _isNetworkAvailable()) {
            if (isLogout) {
              await _logout();
            } else {
              _webViewController?.loadUrl(urlRequest: URLRequest(url: Uri.parse(url)));
              setState(() {
                _currentUrl = url;
              });
              _saveCurrentUrl(url);
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NetworkPage(targetUrl: widget.targetUrl, cookieMap: widget.cookies),
              ),
            );
          }
        },
        child: Center(
          child: SvgPicture.asset(
            assetPath,
            height: isLogout ? 35 : 40,
            color: isSelected ? Colors.yellow : Colors.white,
          ),
        ),
      ),
    );
  }

  Future<bool> _isNetworkAvailable() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> _logout() async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('تسجيل خروج'),
          content: Text('هل أنت متأكد من تسجيل الخروج'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('لا'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('نعم'),
            ),
          ],
        );
      },
    );

    if (confirmLogout ?? false) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clears all stored preferences

      // Clear WebView cookies
      await _clearCookies(); // Call the clear cookies method

      // Navigate back to the login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()), // Replace with your actual LoginPage
      );
    }
  }

  Future<void> _clearCookies() async {
    CookieManager cookieManager = CookieManager.instance();
    await cookieManager.deleteAllCookies(); // Deletes all cookies for the WebView
  }


  void _showNoNetworkDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NetworkPage(targetUrl: widget.targetUrl, cookieMap: widget.cookies),
      ),
    );
  }
}
