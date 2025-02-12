import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ADD/add_transaction.dart';
import 'Settings/change_currency_page.dart';
import 'Settings/settings.dart';
import 'account_data.dart';

class ReminderPage extends StatefulWidget {
  final Function(bool) onDueTransactionsChanged; // Add this callback

  ReminderPage({required this.onDueTransactionsChanged}); // Constructor

  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> allTransactions = [];
  bool isLoading = true;
  bool hasDueTransactions = false; // Add this flag
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

      DateTime now = DateTime.now();
      String todayDate = DateFormat('yyyy-MM-dd').format(now);

      bool dueTransactionsFound = false; // Local variable to track due transactions

      for (int i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final accountId = transaction[textlink.transactionAccountId];

        if (accountId != null) {
          final accountDoc = await FirebaseFirestore.instance
              .collection(textlink.tblAccount)
              .doc(accountId.toString())
              .get();

          if (accountDoc.exists) {
            print("my contact----------------------------${accountDoc.data()}"); // Add this line to debug
            transactions[i][textlink.accountName] = accountDoc.data()?[textlink.accountName] ?? "Unknown Account";
            transactions[i]['accountContact'] = accountDoc.data()?[textlink.accountContact] ?? "No contact available";
          }

        }

        // Check if the transaction is due today
        String reminderDateStr = transaction[textlink.transactionReminderDate];
        DateTime? reminderDate = parseReminderDate(reminderDateStr);
        if (reminderDate != null && DateFormat('yyyy-MM-dd').format(reminderDate) == todayDate) {
          dueTransactionsFound = true; // Set the local flag to true
        }
      }

      setState(() {
        allTransactions = transactions;
        isLoading = false;
        hasDueTransactions = dueTransactionsFound; // Update the state variable
      });

      widget.onDueTransactionsChanged(hasDueTransactions);

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading reminder transactions")));
    }
  }

  DateTime? parseReminderDate(String dateStr) {
    try {
      return DateFormat("dd MMM yyyy").parse(dateStr);
    } catch (e) {
      return null; // Return null if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String todayDate = DateFormat('yyyy-MM-dd').format(now);

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
        print(transaction);

        final accountName = transaction[textlink.accountName] ?? "Unknown Account";
        final accountId =transaction[textlink.accountId];
        final firstCharacter = accountName.isNotEmpty ? accountName[0].toUpperCase() : "";
        final amount = transaction[textlink.transactionAmount];
        final isCredited = transaction[textlink.transactionIsCredited] ?? false;
        final backgroundColor = isCredited ? Colors.green : Colors.red;
        final amountColor = isCredited ? Colors.green : Colors.red;
        final accountContact = transaction["accountContact"] ?? "No contact available";
        print(accountContact);

        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: backgroundColor.withOpacity(0.8),
                      radius: 24,
                      child: Text(
                        firstCharacter,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            accountName,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Row(
                            children: [
                              Icon(Icons.date_range, size: 14, color: Colors.black54),
                              SizedBox(width: 4),
                              Text(
                                transaction[textlink.transactionReminderDate] != null
                                    ? transaction[textlink.transactionReminderDate].toString()
                                    : "No date",
                                style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 14, color: Colors.black54),
                              SizedBox(width: 4),
                              Text(
                                accountContact.toString(), // Replace with actual phone number
                                style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Amount : ",
                                  style: TextStyle(color: Colors.black, fontSize: 14),
                                ),
                                TextSpan(
                                  text: "${CurrencyManager.cr}$amount",
                                  style: TextStyle(color: amountColor, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.grey.shade300),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTransaction(
                              flag: false,
                              id: transaction[textlink.transactionId],
                              name: transaction[textlink.accountName],
                            ),
                          ),
                        );
                      },

                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12))),
                      ),
                      child: Text("Receive", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  Container(height: 40, width: 1, color: Colors.grey.shade300), // Vertical divider
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AccountData(
                              name: accountName,
                              id: accountId, // Pass correctly
                              num: accountContact,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomRight: Radius.circular(12))),
                      ),
                      child: Text("View", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );


      },
      separatorBuilder: (context, index) => Divider(),
    );
  }
}