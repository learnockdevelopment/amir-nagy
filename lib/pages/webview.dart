import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'network.dart';
import 'login.dart';
import 'package:intl/intl.dart';

class WebViewExample extends StatefulWidget {
  final String targetUrl;
  final Map<String, String> cookies;

  WebViewExample({required this.targetUrl, required this.cookies});

  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample>
    with WidgetsBindingObserver {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  final CookieManager _cookieManager = CookieManager.instance();
  String _currentUrl = '';
  DateTime? lastPressed;
  List<String> _navigationHistory = []; // Track the navigation history
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  // Variable to store the initial Moodle session
//float
  late String deviceId = '';
  double posX = 100; // Initial X position
  double posY = 100; // Initial Y position
  Random random = Random();
  Timer? timer;
  Size? screenSize; // Store the screen size
  Timer? visibilityTimer; // Timer for managing visibility
  bool isVisible = true; // Control visibility

  @override
  void initState() {
    getDeviceId();
    super.initState();
    if (!mounted) return;

    _randomlyReposition(); // Set initial position

    // Set a timer to reposition the widget every 2 seconds
    timer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (!mounted) return;

      _randomlyReposition();
    });

    // Set a timer to toggle visibility every 3 seconds
    visibilityTimer = Timer.periodic(Duration(seconds: 0), (timer) {
      if (!mounted) return;
    });
    WidgetsBinding.instance.addObserver(this);
    _initializeWebView();
    _setCookies(widget.cookies); // Set cookies when initializing
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        _showNoNetworkDialog();
      }
    });
  }

  @override
  void dispose() {
    if (!mounted) return;

    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (!mounted) return;

    super.didChangeDependencies();
    screenSize =
        MediaQuery.of(context).size; // Get the current screen size here
  }

  Future<void> _initializeWebView() async {
    _webViewController?.loadUrl(
        urlRequest: URLRequest(url: Uri.parse(widget.targetUrl)));
  }

  Future<void> _setCookies(Map<String, String> cookies) async {
    final cookieManager = CookieManager.instance();
    for (var entry in cookies.entries) {
      await cookieManager.setCookie(
        url: Uri.parse(widget.targetUrl),
        name: entry.key,
        value: entry.value,
      );
    }
  }

  void _updateNavigationHistory(String url) {
    if (_navigationHistory.isEmpty || _navigationHistory.last != url) {
      _navigationHistory.add(url);
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
    if (_navigationHistory.length > 1) {
      // Remove the last entry from the navigation history and load the previous URL
      _navigationHistory.removeLast();
      String previousUrl = _navigationHistory.last;
      _webViewController?.loadUrl(
          urlRequest: URLRequest(url: Uri.parse(previousUrl)));
      return Future.value(false); // Don't exit the app
    } else {
      // Prompt exit confirmation if history is empty
      DateTime now = DateTime.now();
      if (lastPressed == null ||
          now.difference(lastPressed!) > Duration(seconds: 2)) {
        lastPressed = now;
        Fluttertoast.showToast(msg: 'Press again to exit');
        return Future.value(false);
      }
      return Future.value(true);
    }
  }

  // Start a timer to update position and visibility every 5 seconds
  void _randomlyReposition() {
    if (!mounted) return;

    if (screenSize != null) {
      // Ensure screenSize is not null
      setState(() {
        // Generate a random position within screen bounds
        posX = random.nextDouble() *
            (screenSize!.width - 150); // Adjust for widget width
        posY = random.nextDouble() *
            (screenSize!.height - 70); // Adjust for widget height
      });
    }
  }

  Future<void> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String id = 'Unknown Device ID';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        id = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        id = iosInfo.identifierForVendor ?? 'Unknown Device ID';
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfo.macOsInfo;
        id = macOsInfo.systemGUID ?? 'Unknown Device ID';
      }
    } catch (e) {
      id = 'Error retrieving ID';
    }

    if (mounted) {
      setState(() {
        deviceId = id;
      });
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
                        initialUrlRequest:
                            URLRequest(url: Uri.parse(widget.targetUrl)),
                        onWebViewCreated: (controller) {
                          _webViewController = controller;
                        },
                        onLoadStart: (controller, url) {
                          setState(() {
                            _isLoading = true;
                            _currentUrl = url.toString();
                          });
                        },
                        onLoadStop: (controller, url) async {
                          if (url != null) {
                            setState(() {
                              _isLoading = false;
                              _currentUrl = url.toString();
                            });
                            // Update navigation history and save the current URL
                            _updateNavigationHistory(_currentUrl);
                            await _saveCurrentUrl(_currentUrl);
                          }
                        },
                        onProgressChanged: (controller, progress) {
                          setState(() {
                            _isLoading = progress < 100;
                          });
                        },
                      ),
                      Positioned(
                        left: posX,
                        top: posY,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              // Update position based on drag
                              posX += details.delta.dx;
                              posY += details.delta.dy;

                              // Ensure the widget stays within screen bounds
                              posX = posX.clamp(
                                  0.0,
                                  screenSize!.width -
                                      150); // Adjust according to widget width
                              posY = posY.clamp(
                                  0.0,
                                  screenSize!.height -
                                      70); // Adjust according to widget height
                            });
                          },
                          child: Container(
                            width: 150, // Set a fixed width for the box
                            height: 70, // Set a fixed height for the box
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    deviceId,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${DateFormat('yyyy-MM-dd').format(DateTime.now())}', // Updated to show date and time
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${DateFormat('HH:mm:ss a').format(DateTime.now())}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.amber),
                              backgroundColor: Colors.yellow,
                            ),
                          ),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 7,
                            color: Color(0xFF672c7b),
                            width: MediaQuery.of(context).size.width,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: MediaQuery.of(context).size.width / 2,
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    height: 10,
                                    color: Colors.amber,
                                  ),
                                ),
                                Align(
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 500),
                                    width: _isLoading
                                        ? MediaQuery.of(context).size.width
                                        : 0,
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
                                image: AssetImage('assets/bar.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildIcon('assets/logout.svg', '',
                                    isLogout: true),
                                _buildIcon('assets/profile.svg',
                                    'https://lms.amirnagy.com/user/profile'),
                                _buildIcon('assets/dashboard.svg',
                                    'https://lms.amirnagy.com/my/'),
                                _buildIcon('assets/calendar.svg',
                                    'https://lms.amirnagy.com/calendar/view.php?view=month'),
                                _buildIcon('assets/courses.svg',
                                    'https://lms.amirnagy.com/course/'),
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
              color: Color(0xFF672c7b),
              fontSize: 11,
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
          if (isLogout) {
            await _logout();
          } else {
            _webViewController?.loadUrl(
                urlRequest: URLRequest(url: Uri.parse(url)));
            setState(() {
              _currentUrl = url;
            });
            _saveCurrentUrl(url);
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

    if (confirmLogout == true) {
      await _cookieManager.deleteAllCookies();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showNoNetworkDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('خطأ في الشبكة'),
          content: const Text('برجاء فحص شبكة الإنترنت'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeWebView();
              },
              child: Text('تحديث'),
            ),
          ],
        );
      },
    );
  }
}
