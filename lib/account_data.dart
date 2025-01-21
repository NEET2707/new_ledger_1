import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:new_ledger_1/settings.dart';
import 'package:new_ledger_1/transaction_search.dart';
import 'ADD/add_transaction.dart';
import 'colors.dart';



class AccountData extends StatefulWidget {
  final String name;
  final String num;
  final int id;

  AccountData({super.key, required this.name, required this.num, required this.id});

  @override
  State<AccountData> createState() => _AccountDataState();
}


class _AccountDataState extends State<AccountData> with TickerProviderStateMixin {
  double accountBalance = 0.0;
  double totalCredit = 0.0;
  double totalDebit = 0.0;
  bool isLoading = true; // Show loading initially
  bool showContent = false; // Flag to control content display
  // late AnimationController _rotationController; // Rotation animation controller

  @override
  void initState() {

    print("----> ${widget.id}");
    super.initState();
    fetchTransactionData(); // Fetch transaction data

    // Show content after a delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showContent = true; // Display content after 5 seconds
        isLoading = false; // Hide loading spinner
      });
    });
  }

  void fetchTransactionData() {
    FirebaseFirestore.instance
        .collection(textlink.tbltransaction)
        .where(textlink.transactionAccountId, isEqualTo: widget.id)
        .snapshots()
        .listen((querySnapshot) {
      double creditSum = 0.0;
      double debitSum = 0.0;

      // Process the transaction data
      for (var doc in querySnapshot.docs) {
        double amount = double.parse(doc[textlink.transactionAmount].toString());
        bool isCredit = doc[textlink.transactionIsCredited] ?? false;

        if (isCredit) {
          creditSum += amount;
        } else {
          debitSum += amount;
        }
      }

      setState(() {
        totalCredit = creditSum;
        totalDebit = debitSum;
        accountBalance = creditSum - debitSum;
      });
    }, onError: (e) {
      print("Error fetching transactions: $e");
      setState(() {
        isLoading = false; // Hide loading if error occurs
      });
    });
  }

  // Function to get the color based on balance
  Color getBalanceColor() {
    if (accountBalance == 0) {
      return themecolor; // Default theme color for zero balance
    } else if (accountBalance > 0) {
      return Colors.green; // Green for positive balance
    } else {
      return Colors.red; // Red for negative balance
    }
  }

  // Function to set the app bar color based on balance
  Color getAppBarColor() {
    if (accountBalance == 0) {
      return themecolor;
    } else if (accountBalance > 0) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  @override
  void dispose() {
    // _rotationController.dispose(); // Dispose the controller when no longer needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showContent
          ? AppBar(
        foregroundColor: Colors.white,
        backgroundColor: getAppBarColor(), // Set app bar color dynamically
        title: Text(
          widget.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      )
          : PreferredSize(
        preferredSize: const Size.fromHeight(0), // AppBar hidden until content shows
        child: Container(),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator while data is being fetched
          : showContent
          ? SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account balance section
            Container(
              color: getBalanceColor(), // Set balance section color dynamically
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.call, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        widget.num,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Current A/C:",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₹ ${accountBalance.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 32,
                              width: 32,
                              color: Colors.white,
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "₹ ${totalCredit.toStringAsFixed(2)} Credit",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 32,
                              width: 32,
                              color: Colors.white,
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                color: Colors.red,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "₹ ${totalDebit.toStringAsFixed(2)} Debit",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: const Text(
                "Transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection(textlink.tbltransaction)
                  .where(textlink.transactionAccountId, isEqualTo: widget.id)
                  .snapshots(),
              builder: (context, snapshots) {
                if (snapshots.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshots.hasError) {
                  return Center(child: Text("Error: ${snapshots.error.toString()}"));
                }

                if (!snapshots.hasData || snapshots.data!.docs.isEmpty) {
                  return const Center(child: Text("No transactions available."));
                }

                final transactions = snapshots.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final isCredit = transaction[textlink.transactionIsCredited] ?? false;
                    final transactionId = transaction.id;
                    final amount = transaction[textlink.transactionAmount];
                    final date = transaction[textlink.transactionDate];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCredit ? Colors.green : Colors.red,
                        child: Icon(
                          isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        "₹ $amount",
                        style: TextStyle(
                          color: isCredit ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        date,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddTransaction(
                                  id: widget.id,
                                  name: widget.name,
                                  flag: true,
                                ),
                              ),
                            );
                          } else if (value == 'delete') {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: const Text(
                                      'Are you sure you want to delete this transaction?'),
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
                                  .collection(textlink.tbltransaction)
                                  .doc(transactionId)
                                  .delete();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Transaction deleted successfully'),
                                ),
                              );
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
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(
                    color: Colors.grey,
                    height: 1,
                  ),
                );
              },
            ),
          ],
        ),
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themecolor,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransaction(
                flag: true,
                id: widget.id,
                name: widget.name,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}





