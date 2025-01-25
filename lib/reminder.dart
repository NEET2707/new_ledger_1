import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:new_ledger_1/colors.dart';

import 'Settings/change_currency_page.dart';
import 'Settings/settings.dart';

class ReminderPage extends StatefulWidget {
  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  List<Map<String, dynamic>> reminderTransactions = [];
  bool isLoading = true; // Flag to track loading state

  @override
  void initState() {
    super.initState();
    _loadReminderTransactions();
  }

  Future<void> _loadReminderTransactions() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          isLoading = false; // Stop loading if user is not logged in
        });
        return;
      }

      // Query to fetch transactions that have a reminder date (non-null)
      final querySnapshot = await FirebaseFirestore.instance
          .collection(textlink.tbltransaction)
          .where('user_id', isEqualTo: currentUser.uid)
          .where(textlink.transactionReminderDate, isNotEqualTo: null) // Only transactions with reminder dates
          .get();

      final transactions = querySnapshot.docs
          .map((doc) => doc.data())
          .where((transaction) => transaction[textlink.transactionReminderDate] != null) // Filter out those without reminder dates
          .toList();

      // Fetch account names for each transaction
      for (int i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final accountId = transaction[textlink.transactionAccountId];

        // Fetch the account name using accountId
        if (accountId != null) {
          final accountDoc = await FirebaseFirestore.instance
              .collection(textlink.tblAccount)
              .doc(accountId.toString()) // Assuming accountId is an int, convert to string if necessary
              .get();

          if (accountDoc.exists) {
            setState(() {
              transactions[i][textlink.accountName] =
                  accountDoc.data()?[textlink.accountName] ?? "Unknown Account";
            });
          }
        }
      }

      setState(() {
        reminderTransactions = transactions;
        isLoading = false; // Stop loading after data is fetched
      });
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading in case of an error
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading reminder transactions")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Due Reminders"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator while data is being fetched
          : reminderTransactions.isEmpty
          ? Center(child: Text("No transactions with due reminders"))
          : ListView.separated(
        itemCount: reminderTransactions.length,
        itemBuilder: (context, index) {
          final transaction = reminderTransactions[index];
          final accountName = transaction[textlink.accountName] ?? "Unknown Account";
          final firstCharacter = accountName.isNotEmpty ? accountName[0].toUpperCase() : ""; // Get the first character

          // Get the amount
          final amount = transaction[textlink.transactionAmount];
          final isCredited = transaction[textlink.transactionIsCredited] ?? false;

          // Define the background color for the avatar and text color based on credit status
          final backgroundColor = isCredited ? Colors.green : Colors.red;
          final amountColor = isCredited ? Colors.green : Colors.red;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: backgroundColor,
              child: Text(
                firstCharacter,
                style: TextStyle(color: Colors.white), // Use the first character as the avatar's content
              ),
            ),
            title: Text("$accountName"),
            subtitle: Text(
              "${CurrencyManager.cr}$amount",
              style: TextStyle(color: amountColor), // Change the amount text color
            ),
            trailing: Text("Due Date: ${transaction[textlink.transactionReminderDate]}"),
          );
        },
        separatorBuilder: (context, index) {
          return Container(
            width: double.infinity, // Make the separator cover the full width
            padding: EdgeInsets.symmetric(horizontal: 20.0), // Adjust the horizontal padding
            child: Divider(
              color: Colors.grey, // You can adjust the color of the separator
              thickness: 1.0, // Thickness of the divider
            ),
          );
        },
      ),
    );
  }
}
