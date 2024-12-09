import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'webview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> get _cookieFile async {
  final path = await _localPath;
  return File('$path/cookies.json');
}

Future<void> writeCookies(Map<String, String> cookies, String url, String lastPage) async {
  final file = await _cookieFile;
  final data = {
    'url': url,
    'cookies': cookies,
    'lastPage': lastPage, // Save the last page visited
  };
  await file.writeAsString(jsonEncode(data));
}

Future<void> saveLastPage(String lastPage) async {
  final file = await _cookieFile;
  final data = await readCookies();
  if (data != null) {
    data['lastPage'] = lastPage; // Update last page
    await file.writeAsString(jsonEncode(data));
  }
}

Future<Map<String, dynamic>?> readCookies() async {
  try {
    final file = await _cookieFile;
    final contents = await file.readAsString();
    final data = jsonDecode(contents);
    return data;
  } catch (e) {
    return null;
  }
}

// int _retryCount = 0;
// final int _maxRetries = 2;
//
// Future<void> _signInWithGoogle(BuildContext context) async {
//   final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['profile', 'email']);
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.android,
//   );
//
//   try {
//     final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
//     if (googleSignInAccount == null) {
//       return;
//     }
//
//     final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return const AlertDialog(
//           content: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: <Widget>[
//               CircularProgressIndicator(
//                 valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
//               ),
//               SizedBox(width: 20),
//               Text('...برجاء الانتظار'),
//             ],
//           ),
//         );
//       },
//     );
//
//     final AuthCredential credential = GoogleAuthProvider.credential(
//       idToken: googleSignInAuthentication.idToken,
//       accessToken: googleSignInAuthentication.accessToken,
//     );
//
//     final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
//     final User? user = userCredential.user;
//
//     if (googleSignInAuthentication.idToken != null) {
//       String idToken = googleSignInAuthentication.idToken!;
//       Map<String, dynamic> decodedToken = JwtDecoder.decode(idToken);
//
//       Map<String, String> cookieMap = await _sendEncodedTokenAndUrl(idToken);
//
//       if (cookieMap.isNotEmpty) {
//         String targetUrl = "https://lms.amirnagy.com/";
//
//         await writeCookies(cookieMap, targetUrl, targetUrl); // Save target URL as last page
//
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(
//             builder: (context) => WebViewExample(
//               targetUrl: targetUrl,
//               cookies: cookieMap,
//             ),
//           ),
//         );
//       } else {
//         _retrySignIn(context);
//       }
//     } else {
//       _retrySignIn(context);
//     }
//   } catch (error) {
//     if (error.toString().contains('404')) {
//       _retrySignIn(context);
//     } else {
//       Fluttertoast.showToast(msg: 'خطأ في التسجيل, حاول مجددا');
//     }
//   }
// }
//
// Future<void> _retrySignIn(BuildContext context) async {
//   if (_retryCount < _maxRetries) {
//     _retryCount++;
//     await _signInWithGoogle(context);
//   } else {
//     // Sign-in failed after multiple attempts
//   }
// }
//
// final GoogleSignIn _googleSignIn = GoogleSignIn();
//
// Future<Map<String, String>> _sendEncodedTokenAndUrl(String idToken) async {
//   final String apiUrl = "https://moodle-login.vercel.app/api/moodle-login-google";
//
//   try {
//     final response = await http.post(
//       Uri.parse(apiUrl),
//       headers: {
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({
//         'idToken': idToken,
//         'moodleUrl': "https://lms.amirnagy.com/",
//       }),
//     );
//
//     if (response.statusCode == 200) {
//       await _googleSignIn.signOut();
//
//       final responseBody = jsonDecode(response.body);
//       List<dynamic> cookiesList = responseBody['cookies'];
//
//       Map<String, String> cookiesMap = {};
//       for (var cookie in cookiesList) {
//         cookiesMap[cookie['key']] = cookie['value'];
//       }
//
//       return cookiesMap;
//     }
//   } catch (error) {
//     // Error handling
//   }
//
//   return {};
// }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amir nagy',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: FutureBuilder<Map<String, dynamic>?>(
        future: readCookies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (snapshot.hasData && snapshot.data!['cookies'].isNotEmpty) {
            return _validateCookiesAndNavigate(snapshot.data!, context);
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }

  Widget _validateCookiesAndNavigate(Map<String, dynamic> data, BuildContext context) {
    String lastPage = data['lastPage'] ?? 'https://lms.amirnagy.com/';
    Map<String, String> cookies = Map<String, String>.from(data['cookies']);

    return FutureBuilder<bool>(
      future: _checkCookieValidity(cookies),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData && snapshot.data == true) {
          return WebViewExample(
            targetUrl: lastPage,
            cookies: cookies,
          );
        } else {
          return LoginPage();
        }
      },
    );
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
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _checkNetwork() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  void _showNoNetworkDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('خطأ في الشبكة'),
          content: const Text('برجاء فحص شبكة الإنترنت'),
          actions: <Widget>[
            TextButton(
              child: const Text('فهمت'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  void _login() async {
    bool hasNetwork = await _checkNetwork();
    if (!hasNetwork) {
      _showNoNetworkDialog(context);
      return;
    }

    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;
      String password = _passwordController.text;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                ),
                SizedBox(width: 20),
                Text('...برجاء الانتظار'),
              ],
            ),
          );
        },
      );

      final loginUrl = Uri.parse('http://moodle-login.vercel.app/api/moodle-login');
      const targetUrl = 'https://lms.amirnagy.com/';

      try {
        final loginFormValues = <String, String>{
          'username': email,
          'password': password,
          'url': "https://lms.amirnagy.com/"
        };

        var response = await http.post(
          loginUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(loginFormValues),
        );

        // Handle redirects if necessary
        while (response.statusCode == 308 || response.statusCode == 302) {
          final redirectUrl = response.headers['location'];
          if (redirectUrl == null) break;

          response = await http.post(
            Uri.parse(redirectUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(loginFormValues),
          );
        }

        Navigator.of(context).pop();
        _handleResponse(response, targetUrl);
      } catch (e) {
        Navigator.of(context).pop();
        // Fluttertoast.showToast(msg: 'An error occurred: $e');
      }
    }
  }

  void _handleResponse(http.Response response, String targetUrl) async {
    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      if (responseJson['message'] == 'Login successful') {
        final cookies = responseJson['cookies'] as List<dynamic>;
        Map<String, String> cookieMap = {};
        for (var cookie in cookies) {
          cookieMap[cookie['key']] = cookie['value'];
        }

        if (cookieMap.isNotEmpty) {
          await writeCookies(cookieMap, targetUrl, targetUrl);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => WebViewExample(
                targetUrl: targetUrl,
                cookies: cookieMap,
              ),
            ),
          );
        } else {
          // Fluttertoast.showToast(msg: 'خطأ في التسجيل, حاول مجددا');
        }
      } else {
        // Fluttertoast.showToast(msg: 'Login failed: ${responseJson['message']}');
      }
    } else {
      Fluttertoast.showToast(msg: 'خطأ في التسجيل, حاول مجددا');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
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
                            hintText: "أدخل اسم المستخدم",
                            hintTextDirection: TextDirection.rtl, // This makes the input field RTL
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
                              color: Colors.yellow, // Change this to the desired color
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
                        SizedBox(height: 10),
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
                            hintText: "أدخل كلمة السر",
                            hintTextDirection: TextDirection.rtl,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            errorStyle: TextStyle(
                              color: Colors.yellow, // Change this to the desired color
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
                        SizedBox(height: 50),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _login,
                            label: Text(
                              'تسجيل الدخول',
                              style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              padding: EdgeInsets.symmetric(vertical: 10.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: TextStyle(
                                fontSize: 18.0,
                                color: Colors.yellow,
                              ),
                            ),
                          ),
                        ),
                        // SizedBox(height: 10),
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
                        // // SizedBox(
                        //   width: double.infinity,
                        //   child: ElevatedButton.icon(
                        //     onPressed: () {
                        //       _signInWithGoogle(context);
                        //     },
                        //     icon: SvgPicture.asset(
                        //       'assets/google_logo.svg',
                        //       height: 20,
                        //     ),
                        //     label: Text(
                        //       'تسجيل الدخول عن طريق',
                        //       style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        //     ),
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: Colors.white,
                        //       padding: EdgeInsets.symmetric(vertical: 10),
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(10),
                        //       ),
                        //       textStyle: TextStyle(
                        //         fontSize: 18.0,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  SizedBox(height: 200),
                  Text(
                    'Amir Nagy © 2024 Designed by Learnock',
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
    );
  }
}