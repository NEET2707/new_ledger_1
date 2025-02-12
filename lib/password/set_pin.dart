import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:new_ledger_1/password/pin_verify.dart';

import '../colors.dart';
import '../SharedPref/sharedpreferences.dart';

class SetPinScreen extends StatefulWidget {
  @override
  _SetPinScreenState createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String pin = '';
  String confirmPin = '';

  Future<void> _savePin(String pin) async {
    await SharedPreferenceHelper.save(prefKey: PrefKey.pin, value: pin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Set PIN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: themecolor,
        elevation: 5,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title Text
              Text(
                "Create your 4-digit PIN",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: themecolor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // PIN Input
              TextFormField(
                controller: pinController,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Allow only digits
                decoration: InputDecoration(
                  labelText: "Enter PIN",
                  labelStyle: TextStyle(color: themecolor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color:themecolor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themecolor),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty || value.length < 4) {
                    return "PIN must be at least 4 digits";
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    pin = value;
                  });
                },
              ),
              SizedBox(height: 20),

              TextFormField(
                controller: confirmPinController,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Allow only digits
                decoration: InputDecoration(
                  labelText: "Confirm PIN",
                  labelStyle: TextStyle(color: themecolor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themecolor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: themecolor),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                validator: (value) {
                  if (value != pin) {
                    return "PINs do not match";
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    confirmPin = value;
                  });
                },
              ),
              SizedBox(height: 40),

              // Save PIN Button
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    await _savePin(pin); // Save the PIN securely
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => VerifyPinScreen()), // Go to PIN Verification Screen
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themecolor,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  "Set PIN",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
