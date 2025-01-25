import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for FirebaseAuth
import 'package:new_ledger_1/SharedPref/sharedpreferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../account_data.dart';
import '../colors.dart';
import '../Settings/settings.dart';



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
      return -1; // Return a safe fallback value in case of error
    }
  }

  addData(String PaccountName, String PaccountContact, String PaccountEmail, String PaccountDescription) async {
    if (PaccountName.isEmpty || PaccountContact.isEmpty) {
      return;
    }

    // Check if it's a new account or editing an existing one
    int nextId = widget.id == '0' ? await getNextId() : int.parse(widget.id);
    User? user = FirebaseAuth.instance.currentUser;  // Get the current user

    if (user != null) {
      // If it's a new account, add new document, else update the existing account document
      if (widget.id == '0') {
        await FirebaseFirestore.instance.collection(textlink.tblAccount).doc(nextId.toString()).set({
          textlink.accountName: PaccountName,
          textlink.accountContact: PaccountContact,
          textlink.accountId: nextId,
          textlink.accountEmail: PaccountEmail ?? "",
          textlink.accountDescription: PaccountDescription ?? "",
          'userId': user.uid,
        });
      } else {
        await FirebaseFirestore.instance.collection(textlink.tblAccount).doc(widget.id).update({
          textlink.accountName: PaccountName,
          textlink.accountContact: PaccountContact,
          textlink.accountEmail: PaccountEmail ?? "",
          textlink.accountDescription: PaccountDescription ?? "",
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AccountData(name: PaccountName, id: nextId, num: PaccountContact),
        ),
      );
    } else {
      // Handle user not logged in case
    }
  }

  @override
  void initState() {
    super.initState();
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
        title: Text(
          widget.id == '0' ? 'Create Account' : 'Edit Account', // Change title based on edit or create
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                  } else if (value.length != 10) {
                    return 'Mobile number must be exactly 10 digits';
                  } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Mobile number must contain only digits'; // Validation for non-numeric characters
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
                  child: Text(
                    widget.id == '0' ? 'Add' : 'Update', // Change button label based on action
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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

