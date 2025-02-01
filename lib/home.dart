import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:new_ledger_1/reminder.dart';
import 'package:new_ledger_1/tab/all.dart';
import 'package:new_ledger_1/tab/credit.dart';
import 'package:new_ledger_1/tab/debit.dart';
import 'ADD/add_account.dart';
import 'ADD/add_transaction.dart';
import 'Settings/change_currency_page.dart';
import 'Settings/settings.dart';
import 'account_data.dart';
import 'colors.dart';

class Home extends StatefulWidget {
  Home({super.key});

  @override
  State<Home> createState() => _HomePageState();
}

class _HomePageState extends State<Home> {
  double totalCredit = 0.0;
  double totalDebit = 0.0;
  double totalAccountBalance = 0.0;
  bool hasDueTransactions = false; // State to track due transactions
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData;
  late String user_id;
  String a = "";
  String b = "";

  void _onDueTransactionsChanged(bool hasDue) {
    setState(() {
      hasDueTransactions = hasDue; // Update the state when due transactions change
    });
  }

  // Create a GlobalKey for each tab to access their state
  final GlobalKey<AllState> _allKey = GlobalKey<AllState>();
  final GlobalKey<CreditState> _creditKey = GlobalKey<CreditState>();
  final GlobalKey<DebitState> _debitKey = GlobalKey<DebitState>();

  Future<void> _refreshAllTabs() async {
    await calculateTotals();
    await fetchUserData();

    // Trigger refresh in each tab
    _allKey.currentState?.refresh();
    _creditKey.currentState?.refresh();
    _debitKey.currentState?.refresh();

    setState(() {});
  }
  @override
  void initState() {
    super.initState();
    calculateTotals();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userData = userDoc.data();
      });
    }
  }

  Future<void> calculateTotals() async {
    try {
      final transactionSnapshot = await FirebaseFirestore.instance
          .collection(textlink.tbltransaction)
          .where("user_id", isEqualTo: _auth.currentUser?.uid)
          .get();

      double creditSum = 0.0;
      double debitSum = 0.0;

      for (var transaction in transactionSnapshot.docs) {
        double amount = double.parse(transaction[textlink.transactionAmount].toString());
        bool isCredit = transaction[textlink.transactionIsCredited] ?? false;

        if (isCredit) {
          creditSum += amount;
        } else {
          debitSum += amount;
        }
      }

      setState(() {
        totalCredit = creditSum;
        totalDebit = debitSum;
        totalAccountBalance = creditSum - debitSum;
      });

      print("Total Credit: $totalCredit");
      print("Total Debit: $totalDebit");
      print("Total Account Balance: $totalAccountBalance");

    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _showContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final contact = await FlutterContacts.openExternalPick(); // Opens the native contacts app
      if (contact != null && contact.phones.isNotEmpty) {
        // Extract the contact's display name and first phone number
        a = contact.displayName;
        b = contact.phones.first.number;

        // Call your addData function with the contact's details
        addData(a, b, "", "");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected: ${a}, ${b}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No phone number found for the selected contact.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permission to access contacts was denied.")),
      );
    }
  }

  addData(String PaccountName, String PaccountContact, String PaccountEmail, String PaccountDescription) async {
    if (PaccountName.isEmpty || PaccountContact.isEmpty) {
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
      return -1; // Return a safe fallback value in case of error
    }
  }

  void _navigateToSecondPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AppSettings()),
    );

    if (result == true) {
      _reloadPage();
    }
  }

  void _reloadPage() {
    setState(() {
      // Add your reload logic here
    });
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: themecolor,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/image/logo.png',
                    width: 50,
                    height: 80,
                    color: Colors.white,
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ledger Book",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (userData != null)
                          Text(
                            "${userData!['email']}",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) =>
                        ReminderPage(onDueTransactionsChanged: _onDueTransactionsChanged, // Pass the callback
                    )));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Stack(
                      children: [
                        Icon(Icons.notification_add, color: Colors.white),
                        if (hasDueTransactions) // Show a badge if there are due transactions
                          Positioned(
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                '!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showContacts,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Icon(Icons.contact_page, color: Colors.white),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _navigateToSecondPage();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Icon(Icons.settings, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await calculateTotals();
            await fetchUserData();
            await _refreshAllTabs;// Fetch user data again
            setState(() {
              // Any other UI updates needed after refreshing
            });
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Container(
                  color: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Current A/C:",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${CurrencyManager.cr}${totalAccountBalance.abs().toStringAsFixed(2)} ${totalAccountBalance >= 0 ? 'CR' : 'DR'}",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem(Icons.arrow_upward_rounded, "${CurrencyManager.cr}${totalCredit.toStringAsFixed(2)} Credit", Colors.green),
                          _buildSummaryItem(Icons.arrow_downward_rounded, "${CurrencyManager.cr}${totalDebit.toStringAsFixed(2)} Debit", Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.blueAccent,
                  child: TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    tabs: [
                      Tab(text: "ALL"),
                      Tab(text: "CREDIT"),
                      Tab(text: "DEBIT"),
                    ],
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: TabBarView(
                    children: [
                      All(key: _allKey),
                      Credit(key: _creditKey),
                      Debit(key: _debitKey),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: SpeedDial(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          icon: Icons.add,
          children: [
            SpeedDialChild(
              child: Icon(Icons.account_balance_wallet, color: Colors.black),
              backgroundColor: Colors.white,
              label: 'Add Transaction',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddTransaction()),
                );

                if (result == true) {
                  calculateTotals(); // Refresh total amounts
                  setState(() {}); // Rebuild Home Page
                }
              },
            ),
            SpeedDialChild(
              child: Icon(Icons.person_add, color: Colors.black),
              backgroundColor: Colors.white,
              label: 'Add Account',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddAccount(name: 'none', contact: 'none', id: '0')),
                );
                if (result == true) calculateTotals();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, Color iconColor) {
    return Row(
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.white)),
      ],
    );
  }
}

