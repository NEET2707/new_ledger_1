import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:new_ledger_1/Settings/settings.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllPaymentPage extends StatefulWidget {
  @override
  _AllPaymentPageState createState() => _AllPaymentPageState();
}

class _AllPaymentPageState extends State<AllPaymentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _cachedTransactions = [];
  bool _dataLoaded = false;
  bool load = false;

  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> creditTransactions = [];
  List<Map<String, dynamic>> debitTransactions = [];

  String _transactionTypeFilter = 'All';

  late DateTime _startDate;
  late DateTime _endDate;

  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();

  User? user;
  late String userId;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    userId = user?.uid ?? '';

    _resetFilters();

    if (!_dataLoaded) {
      _loadTransactionsFromCache();
    } else {
      setState(() {
        transactions = _cachedTransactions;
        _separateTransactions();
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _transactionTypeFilter = 'All';
      _startDate = DateTime.now().subtract(Duration(days: 30));
      _endDate = DateTime.now();

      _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate);
      _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate);
    });
  }

  Future<void> _loadTransactionsFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cachedTransactions');

    if (cachedData != null) {
      List<dynamic> cachedList = jsonDecode(cachedData);
      print('Loaded transactions from cache: $cachedList');
      setState(() {
        _cachedTransactions = List<Map<String, dynamic>>.from(cachedList);
        transactions = _cachedTransactions;
        _dataLoaded = true;
        _separateTransactions();
      });
    } else {
      print('No cached data found.');
      _fetchTransactions();
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      load = true;
    });
    try {
      QuerySnapshot transactionSnapshot = await _firestore
          .collection('Transaction')
          .where('user_id', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> tempTransactions = [];

      for (var doc in transactionSnapshot.docs) {
        String accountId = doc[textlink.accountId].toString();
        String accountName = 'Unknown Account';

        DocumentSnapshot accountDoc =
        await _firestore.collection('Account').doc(accountId).get();
        if (accountDoc.exists) {
          accountName = accountDoc['account_name'];
        }

        String transactionDateString = doc[textlink.transactionDate];
        DateTime transactionDate =
        DateFormat('d MMM yyyy').parse(transactionDateString);

        bool isWithinDateRange = transactionDate.isAfter(_startDate) &&
            transactionDate.isBefore(_endDate);

        // Apply filters based on transaction type
        bool isTransactionTypeMatch = false;

        if (_transactionTypeFilter == 'All') {
          isTransactionTypeMatch = true;
        } else if (_transactionTypeFilter == 'Credit' &&
            doc[textlink.transactionIsCredited] == true) {
          isTransactionTypeMatch = true;
        } else if (_transactionTypeFilter == 'Debit' &&
            doc[textlink.transactionIsCredited] == false) {
          isTransactionTypeMatch = true;
        }

        if (isWithinDateRange && isTransactionTypeMatch) {
          tempTransactions.add({
            'account': accountName,
            'date': DateFormat('yyyy-MM-dd').format(transactionDate),
            'amount': doc[textlink.transactionAmount].toString(),
            'isCredit': doc[textlink.transactionIsCredited] ?? false,
          });
        }
      }

      setState(() {
        load = false;
        transactions = tempTransactions;
        _cachedTransactions = tempTransactions; // Cache the transactions
        _dataLoaded = true;
        _separateTransactions();
        _saveTransactionsToCache(tempTransactions); // Save to cache
      });
    } catch (e) {
      setState(() {
        load = false;
      });
    }
  }

  void _separateTransactions() {
    creditTransactions = transactions.where((txn) => txn['isCredit'] == true).toList();
    debitTransactions = transactions.where((txn) => txn['isCredit'] == false).toList();
  }

  Future<void> _saveTransactionsToCache(List<Map<String, dynamic>> transactions) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(transactions);
    bool success = await prefs.setString('cachedTransactions', jsonString); // Save data to cache

    if (success) {
      print('Data successfully saved to cache.');
    } else {
      print('Failed to save data to cache.');
    }
  }

  Future<void> _showFilterDialog() async {
    DateTime tempStartDate = _startDate ?? DateTime.now();
    DateTime tempEndDate = _endDate ?? DateTime.now();
    String tempTransactionType = _transactionTypeFilter;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Filter Transactions'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transaction Type'),
                    ListTile(
                      title: Text('All'),
                      leading: Radio<String>(
                        value: 'All',
                        groupValue: tempTransactionType,
                        onChanged: (String? value) {
                          setDialogState(() {
                            tempTransactionType = value!;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Credit'),
                      leading: Radio<String>(
                        value: 'Credit',
                        groupValue: tempTransactionType,
                        onChanged: (String? value) {
                          setDialogState(() {
                            tempTransactionType = value!;
                          });
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('Debit'),
                      leading: Radio<String>(
                        value: 'Debit',
                        groupValue: tempTransactionType,
                        onChanged: (String? value) {
                          setDialogState(() {
                            tempTransactionType = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Start Date:'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'Select Start Date',
                              suffixIcon: IconButton(
                                icon: Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final DateTime? pickedStartDate =
                                  await showDatePicker(
                                    context: context,
                                    initialDate: tempStartDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (pickedStartDate != null) {
                                    setDialogState(() {
                                      tempStartDate = pickedStartDate;
                                      _startDateController.text =
                                          DateFormat('yyyy-MM-dd')
                                              .format(tempStartDate);
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text('End Date:'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _endDateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'Select End Date',
                              suffixIcon: IconButton(
                                icon: Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final DateTime? pickedEndDate =
                                  await showDatePicker(
                                    context: context,
                                    initialDate: tempEndDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (pickedEndDate != null) {
                                    setDialogState(() {
                                      tempEndDate = pickedEndDate;
                                      _endDateController.text =
                                          DateFormat('yyyy-MM-dd')
                                              .format(tempEndDate);
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _transactionTypeFilter = tempTransactionType;
                      _startDate = tempStartDate; // Store DateTime
                      _endDate = tempEndDate; // Store DateTime
                    });

                    _fetchTransactions(); // Fetch filtered transactions
                    Navigator.pop(context);
                  },
                  child: Text('Apply Filters'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'All Transactions',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Text('Account'),
                    pw.Text('Date'),
                    pw.Text('Credit'),
                    pw.Text('Debit'),
                  ],
                ),
                ...transactions.map(
                      (txn) => pw.TableRow(
                    children: [
                      pw.Text(txn['account']),
                      pw.Text(txn['date']),
                      pw.Text(txn['isCredit'] ? txn['amount'] : ''),
                      pw.Text(!txn['isCredit'] ? txn['amount'] : ''),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          'All Payment',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: _showFilterDialog, // Trigger filter dialog
          ),
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
              color: Colors.white,
            ),
            onPressed: _generatePDF,
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () async {
              setState(() {
                transactions = [];
              });
              await _fetchTransactions();
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Container(
            color: Colors.blueAccent,
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: const [
                Expanded(
                    flex: 2,
                    child: Text('Date',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 3,
                    child: Text('Account',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('Credit',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 1,
                    child: Text('Debit',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          load ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height / 2.5,),
              Center(child: CircularProgressIndicator()),
            ],
          ):
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                return Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          txn['date'],
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          txn['account'],
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          txn['isCredit'] ? txn['amount'] : '',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          !txn['isCredit'] ? txn['amount'] : '',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}