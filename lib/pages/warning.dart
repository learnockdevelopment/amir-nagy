import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io'; // For Platform checks

class WarningPage extends StatefulWidget {
  const WarningPage({Key? key}) : super(key: key);

  @override
  _WarningPageState createState() => _WarningPageState();
}

class _WarningPageState extends State<WarningPage> {
  // Function to open system or app settings based on platform
  Future<void> _openSettings() async {
    final String url = Platform.isAndroid
        ? 'app-settings:' // Android specific URL scheme for settings
        : 'App-Prefs:'; // iOS specific URL scheme for app settings

    // Check if the URL can be launched and launch it
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // If URL can't be launched, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الإعدادات')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl, // Apply RTL direction
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade900, Colors.black],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/error.png',
                    width: 250,
                    height: 250,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'خطأ',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'قد يكون هذا الخطأ ناتجًا عن:\n'
                    '- استخدام المحاكي.\n'
                    '- استخدام جهاز مُهكر.\n'
                    'يرجى التحقق وحل أي من المشاكل المذكورة. للحصول على مزيد من المساعدة، اتصل بنا على:\n'
                    'learnock@gmail.com',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey.shade300,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _openSettings, // Call to open settings
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      backgroundColor: Colors.orangeAccent.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: Text(
                      'الذهاب إلى الإعدادات',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
