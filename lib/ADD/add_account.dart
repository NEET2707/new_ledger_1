import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../account_data.dart';
import '../colors.dart';
import '../Settings/settings.dart';



class AddAccount extends StatefulWidget {
  final String name;
  final String contact;
  final String id;
  final String? email;
  final String? description;

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
  final _formKey = GlobalKey<FormState>();
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
      return -1;
    }
  }

  addData(String PaccountName, String PaccountContact, String PaccountEmail, String PaccountDescription) async {
    if (PaccountName.isEmpty || PaccountContact.isEmpty) {
      return;
    }

    int nextId = widget.id == '0' ? await getNextId() : int.parse(widget.id);
    User? user = FirebaseAuth.instance.currentUser;  // Get the current user

    if (user != null) {
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
          widget.id == '0' ? 'Create Account' : 'Edit Account',
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
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the account name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: accountContactController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the account contact number';
                  }  else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'Mobile number must contain only digits';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),
              TextField(
                controller: accountEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: accountDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
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
                    backgroundColor: themecolor,
                  ),
                  child: Text(
                    widget.id == '0' ? 'Add' : 'Update',
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

