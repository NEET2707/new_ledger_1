import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'Settings/change_currency_page.dart';
import 'Settings/settings.dart';

class ReminderPage extends StatefulWidget {
  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> allTransactions = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReminderTransactions();
  }

  Future<void> _loadReminderTransactions() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection(textlink.tbltransaction)
          .where('user_id', isEqualTo: currentUser.uid)
          .where(textlink.transactionReminderDate, isNotEqualTo: null)
          .get();

      final transactions = querySnapshot.docs
          .map((doc) => doc.data())
          .where((transaction) => transaction[textlink.transactionReminderDate] != null)
          .toList();

      for (int i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final accountId = transaction[textlink.transactionAccountId];

        if (accountId != null) {
          final accountDoc = await FirebaseFirestore.instance
              .collection(textlink.tblAccount)
              .doc(accountId.toString())
              .get();

          if (accountDoc.exists) {
            transactions[i][textlink.accountName] =
                accountDoc.data()?[textlink.accountName] ?? "Unknown Account";
          }
        }
      }

      setState(() {
        allTransactions = transactions;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading reminder transactions")));
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String todayDate = DateFormat('yyyy-MM-dd').format(now);


    DateTime? parseReminderDate(String dateStr) {
      try {
        return DateFormat("dd MMM yyyy").parse(dateStr);
      } catch (e) {
        return null; // Return null if parsing fails
      }
    }

    List<Map<String, dynamic>> todayTransactions = allTransactions
        .where((transaction) {
      String reminderDateStr = transaction[textlink.transactionReminderDate];
      DateTime? reminderDate = parseReminderDate(reminderDateStr);
      return reminderDate != null && DateFormat('yyyy-MM-dd').format(reminderDate) == todayDate;
    })
        .toList();

    List<Map<String, dynamic>> upcomingTransactions = allTransactions
        .where((transaction) {
      String reminderDateStr = transaction[textlink.transactionReminderDate];
      DateTime? reminderDate = parseReminderDate(reminderDateStr);
      return reminderDate != null && reminderDate.isAfter(now);
    })
        .toList();

    upcomingTransactions.sort((a, b) {
      DateTime dateA = parseReminderDate(a[textlink.transactionReminderDate]) ?? DateTime(9999);
      DateTime dateB = parseReminderDate(b[textlink.transactionReminderDate]) ?? DateTime(9999);
      return dateA.compareTo(dateB); // Sort in ascending order
    });


    return Scaffold(
      appBar: AppBar(
        title: Text("Due Reminders"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "TODAY"),
            Tab(text: "UPCOMING"),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionList(todayTransactions, "No due reminders for today"),
          _buildTransactionList(upcomingTransactions, "No upcoming reminders"),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions, String emptyMessage) {
    return transactions.isEmpty
        ? Center(child: Text(emptyMessage))
        : ListView.separated(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final accountName = transaction[textlink.accountName] ?? "Unknown Account";
        final firstCharacter = accountName.isNotEmpty ? accountName[0].toUpperCase() : "";
        final amount = transaction[textlink.transactionAmount];
        final isCredited = transaction[textlink.transactionIsCredited] ?? false;
        final backgroundColor = isCredited ? Colors.green : Colors.red;
        final amountColor = isCredited ? Colors.green : Colors.red;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: backgroundColor,
            child: Text(firstCharacter, style: TextStyle(color: Colors.white)),
          ),
          title: Text(accountName),
          subtitle: Text(
            "${CurrencyManager.cr}$amount",
            style: TextStyle(color: amountColor),
          ),
          trailing: Text("Due Date: ${transaction[textlink.transactionReminderDate]}"),
        );
      },
      separatorBuilder: (context, index) => Divider(),
    );
  }
}
