import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:new_ledger_1/Settings/settings.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AllPaymentPage extends StatefulWidget {
  @override
  _AllPaymentPageState createState() => _AllPaymentPageState();
}

class _AllPaymentPageState extends State<AllPaymentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Data for the table
  List<Map<String, dynamic>> transactions = [];
  String _transactionTypeFilter = 'All';
  DateTime _sDate = DateTime.now();
  DateTime _eDate = DateTime.now();
  late DateTime _startDate;
  late DateTime _endDate;


  // Controllers for date fields
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ensure that _startDate and _endDate are initialized to valid DateTime values
    _startDate = DateTime.now().subtract(Duration(days: 30)); // Default to 30 days ago
    _endDate = DateTime.now(); // Default to current date
    _startDateController.text = DateFormat('yyyy-MM-dd').format(_startDate); // Format start date
    _endDateController.text = DateFormat('yyyy-MM-dd').format(_endDate); // Format end date
    _fetchTransactions(); // Fetch transactions on page load
  }



  Future<void> _fetchTransactions() async {
    try {
      QuerySnapshot transactionSnapshot = await _firestore.collection('Transaction').get();
      List<Map<String, dynamic>> tempTransactions = [];

      // Log the fetched documents for debugging
      print('Fetched Documents: ${transactionSnapshot.docs.length}');

      DateTime currentDate = DateTime.now();

      for (var doc in transactionSnapshot.docs) {
        String accountId = doc['account_id'].toString();
        String accountName = 'Unknown Account';

        // Fetch account_name using account_id
        DocumentSnapshot accountDoc = await _firestore.collection('Account').doc(accountId).get();
        if (accountDoc.exists) {
          accountName = accountDoc['account_name'];
        }

        // Get transaction date directly from Firebase (it's already formatted as string)
        String transactionDateString = doc['transaction_date']; // Get the string date from the doc

        // Parse the string date into a DateTime object using DateFormat
        DateTime transactionDate = DateFormat('d MMM yyyy').parse(transactionDateString);

        // Filter transactions based on selected date range and transaction type
        bool isWithinDateRange = transactionDate.isAfter(_startDate) && transactionDate.isBefore(_endDate);

        // Apply filters based on transaction type
        bool isTransactionTypeMatch = false;

        // If 'All' is selected, include all transactions within the date range
        if (_transactionTypeFilter == 'All') {
          isTransactionTypeMatch = true;
        }
        // If 'Credit' is selected, include only credit transactions
        else if (_transactionTypeFilter == 'Credit' && doc['is_credited'] == true) {
          isTransactionTypeMatch = true;
        }
        // If 'Debit' is selected, include only debit transactions
        else if (_transactionTypeFilter == 'Debit' && doc['is_credited'] == false) {
          isTransactionTypeMatch = true;
        }

        // Add the transaction to the list if it matches both the date range and transaction type
        if (isWithinDateRange && isTransactionTypeMatch) {
          tempTransactions.add({
            'account': accountName,
            'date': DateFormat('yyyy-MM-dd').format(transactionDate), // Format the date for display
            'amount': doc['transaction_amount'].toString(),
            'isCredit': doc['is_credited'] ?? false,
          });
        }
      }

      setState(() {
        transactions = tempTransactions;
      });

      print('Fetched Transactions: $transactions');
    } catch (e) {
      print("Error fetching transactions: $e");
    }
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
                    pw.Text('Amount (Dr/Cr)'),
                  ],
                ),
                ...transactions.map(
                      (txn) => pw.TableRow(
                    children: [
                      pw.Text(txn['account']),
                      pw.Text(txn['date']),
                      pw.Text(
                        '${txn['amount']} ${txn['isCredit'] ? "Cr" : "Dr"}',
                      ),
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

  Future<void> _showFilterDialog() async {
    // Start with the correct types for date variables
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
                                  final DateTime? pickedStartDate = await showDatePicker(
                                    context: context,
                                    initialDate: tempStartDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (pickedStartDate != null) {
                                    setDialogState(() {
                                      tempStartDate = pickedStartDate;
                                      _startDateController.text = DateFormat('yyyy-MM-dd').format(tempStartDate);
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
                                  final DateTime? pickedEndDate = await showDatePicker(
                                    context: context,
                                    initialDate: tempEndDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (pickedEndDate != null) {
                                    setDialogState(() {
                                      tempEndDate = pickedEndDate;
                                      _endDateController.text = DateFormat('yyyy-MM-dd').format(tempEndDate);
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
                      // Save dates as DateTime objects (not strings)
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
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: const [
                Expanded(
                    child: Text('Account',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Date',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text('Amount (Dr/Cr)',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                return Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(txn['account'])),
                      Expanded(child: Text(txn['date'])),
                      Expanded(
                        child: Text(
                          '${txn['amount']} ${txn['isCredit'] ? "Cr" : "Dr"}',
                          style: TextStyle(
                            color: txn['isCredit'] ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
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
