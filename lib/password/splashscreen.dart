import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_ledger_1/password/pin_verify.dart';
import '../SharedPref/sharedpreferences.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _showSplashScreen();
  }

  Future<void> _showSplashScreen() async {
    await Future.delayed(Duration(seconds: 5));

    String? savedPin = await SharedPreferenceHelper.get(prefKey: PrefKey.pin);

    if (savedPin != null && savedPin.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VerifyPinScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthHandler()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/image/logo.png', // Path to your logo image
              width: 150, // Adjust the size if needed
              height: 150, // Adjust the size if needed
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
