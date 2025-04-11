import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:new_ledger_1/account_data.dart';
import 'package:new_ledger_1/Settings/settings.dart';
import '../ADD/add_account.dart';
import 'change_currency_page.dart';

class AllAccountsPage extends StatefulWidget {
  bool isyes;
  bool boom;

  AllAccountsPage({super.key, this.isyes = false, required this.boom});

  @override
  _AllAccountsPageState createState() => _AllAccountsPageState();
}

class _AllAccountsPageState extends State<AllAccountsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  String a = "";
  String b = "";

  Future<void> _showContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null && contact.phones.isNotEmpty) {
        a = contact.displayName;
        b = contact.phones.first.number;

        addData(a, b, "", "");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected: ${a}, ${b}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("No phone number found for the selected contact.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permission to access contacts was denied.")),
      );
    }
  }

  addData(String PaccountName, String PaccountContact, String PaccountEmail,
      String PaccountDescription) async {
    if (PaccountName.isEmpty || PaccountContact.isEmpty) {
      return;
    }

    int nextId = await getNextId();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection(textlink.tblAccount)
          .doc(nextId.toString())
          .set({
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
          builder: (context) =>
              AccountData(name: PaccountName, id: nextId, num: PaccountContact),
        ),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey.shade50,
        foregroundColor: Colors.white,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Search accounts...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.black),
          ),
          style: TextStyle(color: Colors.black),
          onChanged: (query) {
            setState(() {
              _searchQuery = query.toLowerCase();
            });
          },
        )
            : Text("All Accounts", style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                _searchController.clear();
                if (!_isSearching) {
                  _searchQuery = '';
                }
              });
            },
          ),

          /// 👥 Group icon => open AddAccount
          IconButton(
            icon: Icon(Icons.group, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddAccount(
                    name: 'none',
                    contact: 'none',
                    id: '0',
                  ),
                ),
              );
              if (result == true) {
                // await calculateTotals();
              }
            },
          ),

          /// ➕ Contact icon => pick contact and add
          IconButton(
            icon: Icon(Icons.person_add_alt_1, color: Colors.black),
            onPressed: () async {
              await _showContacts();
            },
          ),
        ],
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Account")
            .where("userId", isEqualTo: _auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No accounts found"));
          }

          var accounts = snapshot.data!.docs;
          var filteredAccounts = accounts.where((account) {
            final accountName = account[textlink.accountName].toString().toLowerCase();
            return accountName.contains(_searchQuery);
          }).toList();

          return ListView.separated(
            itemCount: filteredAccounts.length,
            itemBuilder: (context, index) {
              final account = filteredAccounts[index];

              final accountId = account[textlink.accountId];
              final accountName = account[textlink.accountName];
              final accountContact = account[textlink.accountContact];

              return StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection(textlink.tbltransaction)
                    .where("user_id", isEqualTo: _auth.currentUser?.uid)
                    .where(textlink.accountId, isEqualTo: accountId) // Filter by uid
                    .snapshots(),
                builder: (context, transactionSnapshot) {
                  // if (transactionSnapshot.connectionState == ConnectionState.waiting) {
                  //   return ListTile(title: Text("Loading..."));
                  // }
                  final transactions = transactionSnapshot.data?.docs ?? [];
                  double creditSum = 0.0;
                  double debitSum = 0.0;

                  for (var transaction in transactions) {
                    double amount = double.parse(transaction[textlink.transactionAmount].toString());

                    bool isCredit = transaction[textlink.transactionIsCredited] ?? false;

                    if (isCredit) {
                      creditSum += amount;  // Add to credit sum
                    } else {
                      debitSum += amount;  // Add to debit sum
                    }
                  }

                  double accountBalance = creditSum - debitSum;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    leading: CircleAvatar(
                      backgroundColor: accountBalance >= 0 ? Colors.green : Colors.red,
                      child: Text(
                        accountName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          accountName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          "${CurrencyManager.cr}${accountBalance >= 0 ? accountBalance.toStringAsFixed(2) : accountBalance.abs().toStringAsFixed(2)} ${accountBalance >= 0 ? 'CR' : 'DR'}",
                          style: TextStyle(
                            color: accountBalance >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(accountContact),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountData(num: accountContact, name: accountName, id: accountId),
                        ),
                      );
                    },
                  );
                },
              );
            },
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Divider(
                color: Colors.grey,
                height: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}
