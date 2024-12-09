import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WarningPage extends StatefulWidget {
  const WarningPage({Key? key}) : super(key: key);

  @override
  _WarningPageState createState() => _WarningPageState();
}

class _WarningPageState extends State<WarningPage> {
  @override
  void initState() {
    super.initState();
  }

  void _closeApp() {
    SystemNavigator.pop(); // Close the app
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow.shade500, Colors.black],
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
                  'Error',
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
                  'This error may be caused by:\n'
                      '1. Using an emulator.\n'
                      '2. Using rooted devices.\n'
                      '3. Running an outdated app version.\n\n'
                      'Please check and resolve any of the above issues. For further assistance, contact us at:\n'
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
                  onPressed: _closeApp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Colors.yellow.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: Text(
                    'Close App',
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
    );
  }
}
