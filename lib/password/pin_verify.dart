import 'package:flutter/material.dart';
import 'package:new_ledger_1/home.dart';
import 'dart:io';

import '../colors.dart';
import '../SharedPref/sharedpreferences.dart';

class VerifyPinScreen extends StatefulWidget {
  const VerifyPinScreen({super.key});

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen>
    with TickerProviderStateMixin {
  late AnimationController animationController;
  String enteredPin = '';
  bool showErrorMessage = false;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin(BuildContext context, String pin) async {
    String? savedPin = await SharedPreferenceHelper.get(prefKey: PrefKey.pin);
    if (savedPin == enteredPin) {
      setState(() {
        showErrorMessage = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    } else {
      setState(() {
        showErrorMessage = true;
        enteredPin = '';
      });
    }
  }

  Future<bool> showExitPopup(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Exit App',
          style: TextStyle(color: themecolor),
        ),
        content: Text(
          'Do you want to exit the app?',
          style: TextStyle(color: themecolor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No', style: TextStyle(color: themecolor)),
          ),
          TextButton(
            onPressed: () => exit(0),
            child: Text('Yes', style: TextStyle(color: themecolor)),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => showExitPopup(context),
      child: Scaffold(
        backgroundColor:Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0), // Add padding here
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 130,
                width: 125,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage('assets/image/logo.png'),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Ledger",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: themecolor,
                ),
              ),
              SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 100.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                        (index) => AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: enteredPin.length > index
                            ? themecolor
                            : Colors.white,
                        border: Border.all(color: themecolor, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
              if (showErrorMessage)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    "Incorrect PIN. Try again.",
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              Spacer(),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 35),
                child: GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    if (index == 9) return SizedBox.shrink();
                    if (index == 11) {
                      return InkWell(
                        onTap: () {
                          if (enteredPin.isNotEmpty) {
                            setState(() {
                              enteredPin = enteredPin.substring(
                                  0, enteredPin.length - 1);
                            });
                          }
                        },
                        child: Icon(Icons.backspace_outlined, size: 28),
                      );
                    }
                    final digit = index == 10 ? '0' : (index + 1).toString();
                    return InkWell(
                      onTap: () {
                        if (enteredPin.length < 4) {
                          setState(() {
                            enteredPin += digit;
                            if (enteredPin.length == 4) {
                              _verifyPin(context, enteredPin);
                            }
                          });
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: themecolor,
                        child: Text(
                          digit,
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
