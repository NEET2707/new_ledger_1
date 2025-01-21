import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:new_ledger_1/authentication/loginpage.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          userData = doc.data() as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile',style: TextStyle(color: Colors.white),),
        foregroundColor: Colors.white,
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue,
              child: Text(
                user?.email != null ? user!.email![0].toUpperCase() : '?',
                style: TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),


            // Email
            ListTile(
              leading: Icon(Icons.email, color: Colors.blue),
              title: Text('Email'),
              subtitle: Text(user?.email ?? 'N/A'),
            ),

            // User ID
            ListTile(
              leading: Icon(Icons.perm_identity, color: Colors.blue),
              title: Text('User ID'),
              subtitle: Text(userData?['uid'] ?? 'N/A'),
            ),

            SizedBox(height: 40),

            // Logout Button
            ElevatedButton(
              onPressed: logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Logout', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
