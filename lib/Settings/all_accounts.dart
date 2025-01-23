import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:new_ledger_1/account_data.dart';
import 'package:new_ledger_1/Settings/settings.dart';
import 'package:new_ledger_1/colors.dart';

import 'change_currency_page.dart';

class AllAccountsPage extends StatefulWidget {
  @override
  _AllAccountsPageState createState() => _AllAccountsPageState();
}

class _AllAccountsPageState extends State<AllAccountsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: Text("All Accounts", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search accounts...',
                  prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query.toLowerCase();
                  });
                },
              ),
            ),
          ),
        ),
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
          // Filter the accounts based on the search query
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
                  if (transactionSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(title: Text("Loading..."));
                  }
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
                          "${CurrencyManager.cr} ${accountBalance.toStringAsFixed(2)}",
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
