import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'webview.dart'; // Import your WebView page

class NetworkPage extends StatefulWidget {
  final String targetUrl; // The target URL for the WebView
  final Map<String, String> cookieMap; // Cookies to be used in the WebView

  const NetworkPage(
      {Key? key, required this.targetUrl, required this.cookieMap})
      : super(key: key);

  @override
  _NetworkPageState createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _closeApp() {
    SystemNavigator.pop(); // Close the app
  }

  Future<void> _initializeWebView() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    // Check network connectivity
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      // Stay on the page and show a failure message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد شبكة. يرجى التحقق من الاتصال الخاص بك.'),
        ),
      );
    } else {
      // Network is available, navigate to the WebView page
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WebViewExample(
            targetUrl: widget.targetUrl, // Pass the target URL
            cookies: widget.cookieMap, // Pass the cookies
          ),
        ),
      );
    }
  }

  Future<void> _refreshPage() async {
    await _initializeWebView(); // Re-run the network check and WebView initialization
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl, // Apply RTL direction
        child: Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey.shade900, Colors.black87],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/error.png',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 30),
                const Text(
                  'لا توجد شبكة',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                const Text(
                  'برجاء فحص الشبكة الخاصة بك.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, // Loading indicator color
                      )
                    : Column(
                        children: [
                          ElevatedButton(
                            onPressed: _refreshPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    30), // Rounded corners
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                            ),
                            child: const Text(
                              'تحديث',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _closeApp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    30), // Rounded corners
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                            ),
                            child: const Text(
                              'إغلاق التطبيق',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
