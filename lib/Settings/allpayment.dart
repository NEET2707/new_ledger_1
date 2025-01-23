import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  // Controllers for date fields
  TextEditingController _startDateController = TextEditingController();
  TextEditingController _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _startDateController.text = _startDate.toLocal().toString().split(' ')[0];
    _endDateController.text = _endDate.toLocal().toString().split(' ')[0];
  }

  Future<void> _fetchTransactions() async {
    try {
      QuerySnapshot transactionSnapshot = await _firestore.collection('Transaction').get();
      List<Map<String, dynamic>> tempTransactions = [];

      for (var doc in transactionSnapshot.docs) {
        String accountId = doc['account_id'].toString();
        String accountName = 'Unknown Account';

        // Fetch account_name using account_id
        DocumentSnapshot accountDoc = await _firestore.collection('Account').doc(accountId).get();
        if (accountDoc.exists) {
          accountName = accountDoc['account_name'];
        }

        tempTransactions.add({
          'account': accountName,
          'date': doc[textlink.transactionDate] is Timestamp
              ? doc[textlink.transactionDate].toDate().toString()
              : doc[textlink.transactionDate].toString(),
          'amount': doc[textlink.transactionAmount].toString(),
          'isCredit': doc[textlink.transactionIsCredited] ?? false,
        });
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
    // Declare variables to hold selected filters
    DateTime? startDate = _startDate;
    DateTime? endDate = _endDate;
    String? selectedType = _transactionTypeFilter;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Filter Transactions'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction Type Selector using RadioButtons
                Text('Transaction Type'),
                ListTile(
                  title: Text('All'),
                  leading: Radio<String>(
                    value: 'All',
                    groupValue: selectedType,
                    onChanged: (String? value) {
                      setState(() {
                        selectedType = value;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: Text('Credit'),
                  leading: Radio<String>(
                    value: 'Credit',
                    groupValue: selectedType,
                    onChanged: (String? value) {
                      setState(() {
                        selectedType = value;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: Text('Debit'),
                  leading: Radio<String>(
                    value: 'Debit',
                    groupValue: selectedType,
                    onChanged: (String? value) {
                      setState(() {
                        selectedType = value;
                      });
                    },
                  ),
                ),
                SizedBox(height: 20),

                // Start Date Picker with TextField
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
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedStartDate != null && pickedStartDate != startDate) {
                                setState(() {
                                  startDate = pickedStartDate;
                                  _startDateController.text = startDate!.toLocal().toString().split(' ')[0];
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

                // End Date Picker with TextField
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
                                initialDate: endDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedEndDate != null && pickedEndDate != endDate) {
                                setState(() {
                                  endDate = pickedEndDate;
                                  _endDateController.text = endDate!.toLocal().toString().split(' ')[0];
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
                Navigator.pop(context);

                // Apply the selected filters
                setState(() {
                  _transactionTypeFilter = selectedType ?? 'All';
                  _startDate = startDate!;
                  _endDate = endDate!;
                });

                // Call your fetch transactions method
                _fetchTransactions();
              },
              child: Text('Apply Filters'),
            ),
          ],
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
