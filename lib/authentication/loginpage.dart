import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:new_ledger_1/authentication/signuppage.dart';
import 'package:new_ledger_1/colors.dart';
import 'package:new_ledger_1/home.dart';
import 'package:new_ledger_1/SharedPref/sharedpreferences.dart';

import 'forgot_password.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SharedPreferenceHelper spHelper = SharedPreferenceHelper();
  bool _passwordVisible = false;

  // Move the GoogleSignIn instance here
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  void _login() async {
    try {
      // Authenticate the user with Firebase
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save the user email in SharedPreferences
      await SharedPreferenceHelper.save(
        value: _emailController.text.trim(),
        prefKey: PrefKey.userEmail,
      );

      // Query Firestore for user data
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("users")
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;
        String uid = userDoc["uid"];

        // Save the user ID in SharedPreferences
        await SharedPreferenceHelper.save(
          value: uid,
          prefKey: PrefKey.userId,
        );

        // Navigate to the Home screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found in Firestore')),
        );
      }
    } catch (e) {
      // Display an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In');

      // Sign out first to ensure the account picker appears
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In canceled');
        return null;
      }
      print('Google user signed in: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Save user data to SharedPreferences
        await SharedPreferenceHelper.save(
          value: user.email ?? '',
          prefKey: PrefKey.userEmail,
        );
        await SharedPreferenceHelper.save(
          value: user.uid,
          prefKey: PrefKey.userId,
        );

        // Check if user exists in Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // Create a new user in Firestore
          await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
          });
        }

        // Navigate to the Home screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      }
      return user;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();

      await _googleSignIn.signOut();
      await _googleSignIn.disconnect(); // Ensures account picker on next login

      await SharedPreferenceHelper.deleteAll();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login', style: TextStyle(color: Colors.white)),
        backgroundColor: themecolor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: themecolor,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email, color: themecolor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock, color: themecolor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: themecolor,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: themecolor,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            SizedBox(height: 10),
            IconButton(
              icon: Icon(Icons.login),  // Replace with Google icon if you prefer
              onPressed: () async {
                User? user = await signInWithGoogle();
                if (user != null) {
                  print('Signed in as: ${user.displayName}');
                  // Handle user info here (navigate, display user data, etc.)
                } else {
                  print('Sign-in failed or was canceled');
                }
              },
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(color: themecolor, fontSize: 16),
              ),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignupPage()),
                );
              },
              child: Text(
                'Create an Account',
                style: TextStyle(color: themecolor, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
