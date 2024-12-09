import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:amir/pages/webview.dart';
import '../services/google_service.dart';
import '../services/microsoft_service.dart';
import '../services/normal_login.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final EmailLoginService _loginService = EmailLoginService();
  BuildContext? _savedContext; // Store context reference

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _savedContext = context; // Save the context in a stable lifecycle phase
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToWebView(Map<String, String> cookies) {
    // Perform navigation here, passing the cookies
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return WebViewExample(
            targetUrl: "https://lms.amirnagy.com",
            cookies: cookies, // Pass the cookies here
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.rtl, // Set the direction to RTL
        child: Scaffold(
          body: SafeArea(
            child: Container(
              color: Colors.black,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'assets/login.png',
                        height: 210,
                        width: 300.0,
                      ),
                      SizedBox(height: 7),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            Container(
                              width:
                                  500, // Set the container width to control alignment
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'اسم المستخدم',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      hintText: 'اسم المستخدم',
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12.0,
                                      ), // Adjust height here
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      errorStyle: TextStyle(
                                        color: Colors
                                            .yellow, // Change this to the desired color
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'رجاء أدخل اسم المستخدم'; // Validator message text
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              width:
                                  500, // Set the container width to control alignment
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'كلمة المرور',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8.0),
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      hintText: 'كلمة المرور',
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12.0,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      errorStyle: TextStyle(
                                        color: Colors
                                            .yellow, // Change this to the desired color
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'رجاء أدخل كلمة السر';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 50),
                            Container(
                              width: 500, // Set width of the button
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    String targetUrl =
                                        'https://lms.amirnagy.com';

                                    // Call normal login method
                                    await _loginService.login(
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                      targetUrl: targetUrl,
                                      context: context,
                                    );
                                  }
                                },
                                label: Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow,
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            // Center(
                            //   child: Text(
                            //     'أو',
                            //     style: TextStyle(
                            //       color: Colors.yellow,
                            //       fontSize: 16,
                            //       fontWeight: FontWeight.bold,
                            //     ),
                            //   ),
                            // ),
                            // SizedBox(height: 10),
                            // Container(
                            //   width: 500, // Set width of the button
                            //   child: ElevatedButton.icon(
                            //     onPressed: () async {
                            //       // CAll google login
                            //       await GoogleSignInService()
                            //           .signInWithGoogle(context);
                            //     },
                            //     icon: SvgPicture.asset(
                            //       'assets/google_logo.svg',
                            //       height: 20,
                            //     ),
                            // label: Text(
                            //   'تسجيل الدخول عن طريق',
                            //   style: TextStyle(
                            //       color: Colors.black,
                            //       fontWeight: FontWeight.bold),
                            // ),
                            // style: ElevatedButton.styleFrom(
                            //   backgroundColor: Colors.white,
                            //   padding: EdgeInsets.symmetric(vertical: 10),
                            //   shape: RoundedRectangleBorder(
                            //     borderRadius: BorderRadius.circular(10),
                            //   ),
                            //   textStyle: TextStyle(
                            //     fontSize: 18.0,
                            //   ),
                            // ),
                            // ),
                            // ),
                          ],
                        ),
                      ),
                      SizedBox(height: 150),
                      Text(
                        'Amir Nagy  © 2024 Designed by Learnock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
