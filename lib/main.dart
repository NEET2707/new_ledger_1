import 'package:flutter/material.dart';
import 'package:new_ledger_1/SharedPref/sharedpreferences.dart';
import 'package:new_ledger_1/password/splashscreen.dart';
import 'package:provider/provider.dart'; // Import the provider package
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_ledger_1/authentication/loginpage.dart';
import 'package:new_ledger_1/home.dart';
import 'Settings/change_currency_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferenceHelper.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await CurrencyManager().loadCurrency();

  runApp(ChangeNotifierProvider(
    create: (context) => CurrencyManager(), // Provide the CurrencyManager globally
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: SplashScreen(),

      // AuthHandler(),
    );
  }
}

class AuthHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return snapshot.hasData ? Home() : LoginPage();
      },
    );
  }
}
