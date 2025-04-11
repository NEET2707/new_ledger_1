import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:new_ledger_1/reminder.dart';
import 'ADD/add_account.dart';
import 'ADD/add_transaction.dart';
import 'Settings/all_accounts.dart';
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
  bool hasDueTransactions = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? userData;
  late String user_id;
  String a = "";
  String b = "";
  int _selectedIndex = 0;
  int _selectedIndexbotam = 0;
  bool _hasActiveAccounts = true;

  void _onDueTransactionsChanged(bool hasDue) {
    setState(() {
      hasDueTransactions = hasDue;
    });

    if (!hasDue) {
      checkDueReminders();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      calculateTotals(); // Ensures it runs only once after UI is built
    });
    fetchUserData();
    checkDueReminders();
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          height: 40,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> checkDueReminders() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection(textlink.tbltransaction)
        .where('user_id', isEqualTo: currentUser.uid)
        .where(textlink.transactionReminderDate,
            isNotEqualTo: null) // Ensure only non-null values
        .get();

    DateTime now = DateTime.now();
    String todayDate = DateFormat('yyyy-MM-dd').format(now);

    bool dueFound = querySnapshot.docs.any((transaction) {
      final reminderDateStr = transaction[textlink.transactionReminderDate];

      if (reminderDateStr == null ||
          reminderDateStr.toString().trim().isEmpty) {
        return false;
      }

      DateTime? reminderDate = parseReminderDate(reminderDateStr.toString());
      return reminderDate != null &&
          DateFormat('yyyy-MM-dd').format(reminderDate) == todayDate;
    });

    if (mounted) {
      setState(() {
        hasDueTransactions = dueFound;
      });
    }
  }

  DateTime? parseReminderDate(String dateStr) {
    try {
      return DateFormat("dd MMM yyyy").parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  DateTime? parseReminderDateInHome(String dateStr) {
    try {
      return DateFormat("dd MMM yyyy").parse(dateStr);
    } catch (e) {
      return null;
    }
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
        double amount =
        double.parse(transaction[textlink.transactionAmount].toString());
        bool isCredit = transaction[textlink.transactionIsCredited] ?? false;

        if (isCredit) {
          creditSum += amount;
        } else {
          debitSum += amount;
        }
      }

      double newTotalCredit = creditSum;
      double newTotalDebit = debitSum;
      double newTotalAccountBalance = creditSum - debitSum;

      if (mounted &&
          (newTotalCredit != totalCredit ||
              newTotalDebit != totalDebit ||
              newTotalAccountBalance != totalAccountBalance)) {
        setState(() {
          totalCredit = newTotalCredit;
          totalDebit = newTotalDebit;
          totalAccountBalance = newTotalAccountBalance;
        });
      }

    } catch (e) {
      print("Error: $e");
    }
  }

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

  addData(String PaccountName, String PaccountContact, String PaccountEmail, String PaccountDescription) async {
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
    setState(() {});
  }

  Widget buildRefreshIndicator({required Widget child}) {
    return RefreshIndicator(
      onRefresh: () async {
        await calculateTotals();
        await fetchUserData();
      },
      child: child,
    );
  }

  final List<Widget> _pages = [
    Container(),
    Builder(
      builder: (context) => AllAccountsPage(isyes: true, boom: false),
    ),
    AppSettings(),
  ];

  Future<List<Widget>> _getNonZeroBalanceTiles(List<QueryDocumentSnapshot> accounts) async {
    List<Widget> result = [];

    for (var account in accounts) {
      final accountId = account[textlink.accountId];
      final accountName = account[textlink.accountName];
      final accountContact = account[textlink.accountContact];

      final transactionSnapshot = await FirebaseFirestore.instance
          .collection(textlink.tbltransaction)
          .where("user_id", isEqualTo: _auth.currentUser?.uid)
          .where(textlink.accountId, isEqualTo: accountId)
          .get();

      double creditSum = 0.0;
      double debitSum = 0.0;

      for (var transaction in transactionSnapshot.docs) {
        double amount = double.tryParse(
            transaction[textlink.transactionAmount].toString()) ??
            0.0;
        bool isCredit = transaction[textlink.transactionIsCredited] ?? false;
        if (isCredit) {
          creditSum += amount;
        } else {
          debitSum += amount;
        }
      }

      double accountBalance = creditSum - debitSum;

      if (accountBalance == 0) continue; // skip this account

      result.add(ListTile(
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
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              "${CurrencyManager.cr}${accountBalance.abs().toStringAsFixed(2)} ${accountBalance >= 0 ? 'CR' : 'DR'}",
              style: TextStyle(
                color: accountBalance >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            )
          ],
        ),
        subtitle: Text(accountContact),
        trailing: PopupMenuButton<String>(icon: const Icon(Icons.more_vert),
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
                    description:
                    account[textlink.accountDescription],
                  ),
                ),
              );

              if (shouldRefresh == true) {
                setState(() {});
                calculateTotals();
              }
            } else if (value == 'delete') {
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text(
                        'Are you sure you want to delete this account?'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );

              if (shouldDelete == true) {
                QuerySnapshot querySnapshot =
                await FirebaseFirestore.instance
                    .collection(textlink.tbltransaction)
                    .where(textlink.transactionAccountId,
                    isEqualTo: accountId)
                    .get();

                for (var doc in querySnapshot.docs) {
                  await doc.reference.delete();
                }

                await FirebaseFirestore.instance
                    .collection(textlink.tblAccount)
                    .doc(accountId.toString())
                    .delete();

                setState(() {});
                calculateTotals();
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
                  Text('Delete',
                      style: TextStyle(fontSize: 16)),
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
      ));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: (_selectedIndexbotam == 1 || _selectedIndexbotam == 2)
            ? null
            : AppBar(
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
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ReminderPage(
                                onDueTransactionsChanged:
                                    _onDueTransactionsChanged)));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Stack(
                      children: [
                        Icon(Icons.notification_add, color: Colors.white),
                        if (hasDueTransactions)
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
                  onTap: _navigateToSecondPage,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Icon(Icons.settings, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _selectedIndexbotam == 0
            ? SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                color: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Current A/C:", style: TextStyle(fontSize: 16, color: Colors.white)),
                    SizedBox(height: 4),
                    Text(
                      "${CurrencyManager.cr}${totalAccountBalance.abs().toStringAsFixed(2)} ${totalAccountBalance >= 0 ? 'CR' : 'DR'}",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    _buildTabButton("ALL", 0),
                    _buildTabButton("CREDIT", 1),
                    _buildTabButton("DEBIT", 2),
                  ],
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    kBottomNavigationBarHeight -
                    150,
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildAllTab(),
                    _buildCreditTab(),
                    _buildDebitTab(),
                  ],
                ),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: () async {},
          child: _pages[_selectedIndexbotam],
        ),

        /// ✅ Here is the proper floatingActionButton
          floatingActionButton: _selectedIndexbotam == 0 && _hasActiveAccounts
              ? SpeedDial(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.add,
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            children: [
              SpeedDialChild(
                child: Icon(Icons.account_balance_wallet, color: Colors.black),
                backgroundColor: Colors.white,
                label: 'Add Transaction',
                labelStyle: TextStyle(fontSize: 16),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddTransaction()),
                  );
                  if (result == true) await calculateTotals();
                },
              ),
              SpeedDialChild(
                child: Icon(Icons.person_add, color: Colors.black),
                backgroundColor: Colors.white,
                label: 'Add Account',
                labelStyle: TextStyle(fontSize: 16),
                onTap: () async {
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
                  if (result == true) await calculateTotals();
                },
              ),
            ],
          )
              : null,

          bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          height: 65,
          notchMargin: 8.0,
          color: themecolor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, "Home", 0),
              _buildNavItem(Icons.account_circle, "All Account", 1),
              _buildNavItem(Icons.settings, "settings", 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndexbotam = index;
            if (_selectedIndexbotam == 0) {
              // Call these functions when switching back to home
              WidgetsBinding.instance.addPostFrameCallback((_) {
                calculateTotals(); // Ensures it runs only once after UI is built
              });
              fetchUserData();
              checkDueReminders();
            }
          });
        },
        child: SizedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: _selectedIndexbotam == index ? Colors.white : Colors.white,
              ),
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: _selectedIndexbotam == index ? Colors.white : Colors.white,
                ),
              ),
            ],
          ),
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
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.white)),
      ],
    );
  }

  Widget _buildAllTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await calculateTotals(); // Only updates totals
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 30.0),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection(textlink.tblAccount)
              .where("userId", isEqualTo: _auth.currentUser?.uid)
              .snapshots(),
          builder: (context, accountSnapshot) {
            if (accountSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!accountSnapshot.hasData ||
                accountSnapshot.data!.docs.isEmpty) {
              _hasActiveAccounts = false;
              return _buildEmptyAccountsUI();
            }

            final accounts = accountSnapshot.data!.docs;
            List<Widget> accountTiles = [];

            return FutureBuilder(
              future: _getNonZeroBalanceTiles(accounts),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final tiles = snapshot.data ?? [];

                // Set the state here to control FAB visibility
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_hasActiveAccounts != tiles.isNotEmpty) {
                    setState(() {
                      _hasActiveAccounts = tiles.isNotEmpty;
                    });
                  }
                });

                return tiles.isNotEmpty
                    ? ListView.separated(
                  itemCount: tiles.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) => tiles[index],
                )
                    : _buildEmptyAccountsUI();
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyAccountsUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("No active accounts.", style: TextStyle(fontSize: 18)),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.person_add),
            label: Text("Add Account"),
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
              if (result == true) await calculateTotals();
            },
          ),
          SizedBox(height: 12),
          ElevatedButton.icon(
            icon: Icon(Icons.account_balance_wallet),
            label: Text("Add Transaction"),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddTransaction()),
              );
              if (result == true) await calculateTotals();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreditTab() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(textlink.tblAccount)
          .where("userId", isEqualTo: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, accountSnapshot) {
        if (accountSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!accountSnapshot.hasData || accountSnapshot.data!.docs.isEmpty) {
          return Center(child: Text("No credited accounts available."));
        }

        final accounts = accountSnapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: () async {
            await calculateTotals();
          },
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getFilteredAccounts(accounts, true),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Text("No accounts with a positive balance."));
              }

              final filteredAccounts = snapshot.data!;

              return ListView.separated(
                itemCount: filteredAccounts.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final account = filteredAccounts[index];
                  final accountId = account[textlink.accountId];
                  final accountName = account[textlink.accountName];
                  final accountContact = account[textlink.accountContact];
                  final accountBalance = account['balance'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(
                        accountName[0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(accountName,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(accountContact),
                    trailing: Text(
                      "${CurrencyManager.cr}${accountBalance.toStringAsFixed(2)} CR",
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
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
          ),
        );
      },
    );
  }

  Widget _buildDebitTab() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(textlink.tblAccount)
          .where("userId", isEqualTo: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, accountSnapshot) {
        if (accountSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!accountSnapshot.hasData || accountSnapshot.data!.docs.isEmpty) {
          return Center(child: Text("No debited accounts available."));
        }

        final accounts = accountSnapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: () async {
            await calculateTotals();
          },
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getFilteredAccounts(accounts, false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final filteredAccounts = snapshot.data ?? [];

              if (filteredAccounts.isEmpty) {
                return Center(child: Text("No debited accounts available."));
              }

              return ListView.separated(
                itemCount: filteredAccounts.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final account = filteredAccounts[index];
                  final accountId = account[textlink.accountId];
                  final accountName = account[textlink.accountName];
                  final accountContact = account[textlink.accountContact];
                  final accountBalance = account['balance'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Text(accountName[0].toUpperCase(),
                          style: TextStyle(color: Colors.white)),
                    ),
                    title: Text(accountName,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(accountContact),
                    trailing: Text(
                      "${CurrencyManager.cr}${(accountBalance ?? 0.0).abs().toStringAsFixed(2)} ${accountBalance != null && accountBalance < 0 ? 'CR' : 'DR'}",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getFilteredAccounts(
      List<QueryDocumentSnapshot> accounts, bool isCredit) async {
    if (accounts.isEmpty) return [];

    // Extract account IDs with original type (don't convert to String)
    final accountIds = accounts.map((a) => a[textlink.accountId]).toList();

    // Chunk the account IDs for Firestore 'whereIn' (max 10 items)
    List<List<dynamic>> chunks = [];
    for (int i = 0; i < accountIds.length; i += 10) {
      chunks.add(accountIds.sublist(
          i, i + 10 > accountIds.length ? accountIds.length : i + 10));
    }

    final accountBalances = <dynamic, double>{};

    // For each chunk, fetch transactions and calculate balances
    for (var chunk in chunks) {
      print("Querying chunk: $chunk");
      final snapshot = await FirebaseFirestore.instance
          .collection(textlink.tbltransaction)
          .where("user_id", isEqualTo: _auth.currentUser?.uid)
          .where(textlink.accountId, whereIn: chunk)
          .get();

      print("Transactions found: ${snapshot.docs.length}");

      for (var transaction in snapshot.docs) {
        var accountId = transaction[textlink.accountId]; // keep as dynamic
        double amount = double.tryParse(
            transaction[textlink.transactionAmount].toString()) ??
            0.0;
        bool isCreditTransaction =
            transaction[textlink.transactionIsCredited] ?? false;

        print(
            "Transaction -> accountId: $accountId, amount: $amount, isCredit: $isCreditTransaction");

        accountBalances[accountId] = (accountBalances[accountId] ?? 0.0) +
            (isCreditTransaction ? amount : -amount);
      }
    }

    // Debug print all balances
    print("Account balances:");
    accountBalances.forEach((id, balance) {
      print("Account ID: $id => Balance: $balance");
    });

    // Filter based on positive or negative balance
    final filteredAccounts = accounts.where((account) {
      final id = account[textlink.accountId];
      final balance = accountBalances[id] ?? 0.0;
      return isCredit ? balance > 0.001 : balance < -0.001; // with tolerance
    }).map((account) {
      final id = account[textlink.accountId];
      return {
        textlink.accountId: account[textlink.accountId],
        textlink.accountName: account[textlink.accountName],
        textlink.accountContact: account[textlink.accountContact],
        'balance': accountBalances[id] ?? 0.0,
      };
    }).toList();

    print(
        "Filtered ${isCredit ? "credit" : "debit"} accounts: ${filteredAccounts.length}");

    return filteredAccounts;
  }

}
