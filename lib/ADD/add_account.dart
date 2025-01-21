import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuth
import 'package:new_ledger_1/sharedpreferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../account_data.dart';
import '../colors.dart';
import '../settings.dart';



class AddAccount extends StatefulWidget {
  final String name;
  final String contact;
  final String id;
  final String? email; // Make email optional
  final String? description; // Make description optional

  const AddAccount({
    super.key,
    required this.name,
    required this.contact,
    required this.id,
    this.email,
    this.description,
  });

  @override
  State<AddAccount> createState() => _AddAccountState();
}

class _AddAccountState extends State<AddAccount> {
  final _formKey = GlobalKey<FormState>(); // Key to validate the form
  final TextEditingController accountNameController = TextEditingController();
  final TextEditingController accountContactController = TextEditingController();
  final TextEditingController accountEmailController = TextEditingController();
  final TextEditingController accountDescriptionController = TextEditingController();

  Future<int> getNextId() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection(textlink.tblAccount)
          .orderBy(textlink.accountId, descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first[textlink.accountId] + 1;
      } else {
        return 1;
      }
    } catch (e) {
      print('Error fetching data: $e');
      return -1; // Return a safe fallback value in case of error
    }
  }

  addData(String PaccountName, String PaccountContact, String PaccountEmail, String PaccountDescription) async {
    if (PaccountName.isEmpty || PaccountContact.isEmpty) {
      print("Enter required fields");
      return;
    }

    int nextId = await getNextId();
    User? user = FirebaseAuth.instance.currentUser;  // Get the current user

    if (user != null) {
      await FirebaseFirestore.instance.collection(textlink.tblAccount).doc(nextId.toString()).set({
        textlink.accountName: PaccountName,
        textlink.accountContact: PaccountContact,
        textlink.accountId: nextId,
        textlink.accountEmail: PaccountEmail ?? "",
        textlink.accountDescription: PaccountDescription ?? "",
        'userId': user.uid,
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AccountData(name: PaccountName, id: nextId, num: PaccountContact),
        ),
      );
    } else {
      print("User not logged in");
    }
  }


  String? userId, userEmail;
  SharedPreferenceHelper spHelper = SharedPreferenceHelper();

  getDataFromSPHelper() async {
    userId = await spHelper.getUserId();
    userEmail = await spHelper.getUserEmail();
    setState(() {
      print("USER iiiiiiiiiiiiiiiiiiiiiiddddddddddddd : $userId");
      print("USER iiiiiiiiiiiiiiiiiiiiiiddddddddddddd : $userEmail");
    });
  }


  @override
  void initState() {
    super.initState();
    getDataFromSPHelper();

    if (widget.name == "none" && widget.contact == "none" && widget.id == '0') {
      accountContactController.text = "";
      accountNameController.text = "";
    } else {
      accountNameController.text = widget.name;
      accountContactController.text = widget.contact;
    }
    if (widget.email != null) accountEmailController.text = widget.email!;
    if (widget.description != null) accountDescriptionController.text = widget.description!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themecolor,
        foregroundColor: Colors.white,
        title: const Text(
          "Create Account",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Name *', // Add asterisk to indicate required field
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the account name'; // Validation message for empty Name field
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: accountContactController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *', // Add asterisk to indicate required field
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the account contact number'; // Validation message for empty Mobile field
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: accountEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email', // No asterisk as it is optional
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: accountDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description', // No asterisk as it is optional
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 400,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      addData(accountNameController.text, accountContactController.text, accountEmailController.text, accountDescriptionController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account form validated!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themecolor, // Set the background color to the theme color
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
