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
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    String? savedPin = await SharedPreferenceHelper.get(prefKey: PrefKey.pin);

    if (savedPin != null && savedPin.isNotEmpty) {
      // If PIN is set, navigate to VerifyPinScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VerifyPinScreen()),
      );
    } else {
      // If PIN is not set, navigate to AuthHandler page
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
        child: CircularProgressIndicator(), // Show a loading indicator while checking
      ),
    );
  }
}
