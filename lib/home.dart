import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:new_ledger_1/Settings/settings.dart';
import 'package:new_ledger_1/colors.dart';
import 'Settings/change_currency_page.dart';
import 'reminder.dart';
import 'account_data.dart';
import 'ADD/add_transaction.dart';
import 'ADD/add_account.dart';

// Account table field names

class Home extends StatefulWidget {
  Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String selectedTab = "ALL"; // Default tab
  double totalCredit = 0.0;
  double totalDebit = 0.0;
  double totalAccountBalance = 0.0;
  bool isLoading = true;
  Map<String, dynamic>? userData;
  late String user_id;
  // Contact? _contact;

  String a = "";
  String b = "";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Contact>? contacts;
  get nextId => null;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data
    calculateTotals();
    _checkAndFetchContacts();
  }

  Future<void> _checkAndFetchContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final fetchedContacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        contacts = fetchedContacts as List<Contact>?;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permission to access contacts was denied")),
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
      return -1; // Return a safe fallback value in case of error
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




  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(user.uid).get();

      setState(() {
        userData = userDoc.data() as Map<String, dynamic>?;
        user_id = userData!["uid"];
      });
    }
  }

// Function to recalculate the totals
  void calculateTotals() async {
    setState(() {
      isLoading = true; // Start loading
    });

    double creditSum = 0.0;
    double debitSum = 0.0;

    try {
      final accountSnapshot = await FirebaseFirestore.instance
          .collection(textlink.tblAccount)
          .get();

      for (var account in accountSnapshot.docs) {

        if (account.data().containsKey('account_id')) {
          final accountId = account['account_id'];

          final transactionSnapshot = await FirebaseFirestore.instance
              .collection(textlink.tbltransaction)
              .where(textlink.transactionAccountId, isEqualTo: accountId)
              .where("user_id", isEqualTo: user_id)
              .get();

          for (var transaction in transactionSnapshot.docs) {
            double amount = double.parse(transaction[textlink.transactionAmount].toString());
            bool isCredit = transaction[textlink.transactionIsCredited] ?? false;

            if (isCredit) {
              creditSum += amount;
            } else {
              debitSum += amount;
            }
          }
        } else {
        }
      }

      setState(() {
        totalCredit = creditSum;
        totalDebit = debitSum;
        totalAccountBalance = creditSum - debitSum;
        isLoading = false; // Stop loading
      });
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading in case of error
      });
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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: themecolor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/image/logo.png', // Path to your logo image
                  width: 50, // Adjust the size if needed
                  height: 80,
                  color: Colors.white,
                ),
                SizedBox(width: 10), // Space between the logo and text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                  children: [
                    Text(
                      "Ledger Book",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16, // Adjust font size for the title
                      ),
                    ),
                    if (userData != null) // Check if userData is not null
                      Text(
                        "${userData!['email']}", // Display email as subtitle
                        style: TextStyle(
                          color: Colors.white70, // Slightly dimmer color for subtitle
                          fontSize: 12, // Smaller font size for subtitle
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),

        actions: [
          Row(
            mainAxisSize: MainAxisSize.min, // Ensures the row is only as wide as needed
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>ReminderPage()));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Icon(Icons.notification_add, color: Colors.white),
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
                  _navigateToSecondPage();                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Icon(Icons.settings, color: Colors.white),
                ),
              ),
            ],
          ),
        ],


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
              if (result != null && result == true) {
                calculateTotals(); // Recalculate totals after adding a transaction
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
                MaterialPageRoute(
                  builder: (context) => AddAccount(name: 'none', contact: 'none', id: '0'),
                ),
              );
              if (result != null && result == true) {
                calculateTotals(); // Recalculate totals after adding an account
              }
            }
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async{
          _fetchUserData();
          calculateTotals();
          _checkAndFetchContacts();
        },
        child: Column(
          children: [
        // child: Text(
        // _contact != null
        // ? 'Selected Contact: ${_contact!.fullName} (${_contact!.phoneNumber?.number})'
        //     : 'No contact selected',
          // Display total credit, debit, and balance under "Current A/C"
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
                  "${CurrencyManager.cr}${totalAccountBalance.toStringAsFixed(2)}",
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
          // Tabs for ALL, CREDIT, and DEBIT
          Container(
            color: Colors.blueAccent,
            child: Row(
              children: [
                _buildTabButton("ALL", selectedTab == "ALL"),
                _buildTabButton("CREDIT", selectedTab == "CREDIT"),
                _buildTabButton("DEBIT", selectedTab == "DEBIT"),
              ],
            ),
          ),
          Expanded(
            child: isLoading // Show loading indicator while data is being fetched
                ? Center(child: CircularProgressIndicator())
                : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection(textlink.tblAccount)
                  .where("userId", isEqualTo: _auth.currentUser?.uid) // Filter by uid
                  .snapshots(),
              builder: (context, accountSnapshot) {
                if (accountSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!accountSnapshot.hasData || accountSnapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No accounts available."));
                }

                final accounts = accountSnapshot.data!.docs;
                if(accountSnapshot.hasData){
                  return ListView.separated(
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {

                      final account = accounts[index];

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

                            if (selectedTab == "ALL" ||
                                (selectedTab == "CREDIT" && isCredit) ||
                                (selectedTab == "DEBIT" && !isCredit)) {
                              if (isCredit) {
                                creditSum += amount;
                              } else {
                                debitSum += amount;
                              }
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
                                Flexible(
                                  child: Text(
                                    accountName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    overflow: TextOverflow.ellipsis,  // Ensures text is truncated if it overflows
                                  ),
                                ),
                                Text(
                                  "${CurrencyManager.cr}${accountBalance.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: accountBalance >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(accountContact),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final shouldRefresh = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddAccount(
                                        name: accountName,
                                        contact: accountContact,
                                        id: accountId.toString(),
                                        email: account[textlink.accountEmail],
                                        description: account[textlink.accountDescription],
                                      ),
                                    ),
                                  );

                                  if (shouldRefresh == true) {
                                    setState(() {}); // Refresh account list after editing
                                    calculateTotals(); // Recalculate totals after editing
                                  }
                                } else if (value == 'delete') {
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Confirm Delete'),
                                        content: const Text('Are you sure you want to delete this account?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (shouldDelete == true) {
                                    await FirebaseFirestore.instance
                                        .collection(textlink.tblAccount)
                                        .doc(accountId.toString())
                                        .delete();

                                    setState(() {}); // Refresh account list after deletion
                                    calculateTotals(); // Recalculate totals after deletion
                                  }
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Edit', style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AccountData(
                                    name: accountName,
                                    id: accountId,
                                    num: accountContact,
                                  ),
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
                }else {
                  return Container(child: Text("No data"),);
                }
              },
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = title;
          });
        },
        child: Container(
          height: 50,
          color: isSelected ? Colors.white : Colors.blueAccent,
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, Color iconColor) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 32,
            width: 32,
            color: Colors.white,
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}


