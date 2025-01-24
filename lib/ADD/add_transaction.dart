import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:new_ledger_1/transaction_search.dart';

import '../account_data.dart';
import '../Settings/settings.dart';
import '../SharedPref/sharedpreferences.dart'; // For date formatting





class AddTransaction extends StatefulWidget {

  String? name;
  int? id;
  bool? flag;
  // Settings? userId;

  AddTransaction({super.key, this.id, this.name, this.flag, });
  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {

  final TextEditingController accountNameController = TextEditingController();
  final TextEditingController transactionAmountController = TextEditingController();
  final TextEditingController transactionDateController = TextEditingController();

  final amtcon = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime _transactionDate = DateTime.now();
  DateTime? _reminderDate;
  bool _isReminderChecked = false;

  String? selectedAccountName;
  int? selectedAccountId;

  Future<int> tgetNextId() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection(textlink.tbltransaction)
          .orderBy(textlink.transactionId, descending: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty
          ? querySnapshot.docs.first[textlink.transactionId] + 1
          : 1;
    } catch (e) {
      return -1;
    }
  }

  Future<void> _addTransaction(bool status) async {
    try {
      int tnextId = await tgetNextId();
      if (tnextId == -1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to generate transaction ID")));
        }
        return;
      }

      // Get the current user
      final currentUser = FirebaseAuth.instance.currentUser;

      // Check if the user is logged in
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No user is logged in")));
        }
        return;
      }

      final transactionData = {
        textlink.transactionId: tnextId,
        textlink.transactionAmount: double.parse(amtcon.text),
        textlink.transactionDate: _formatDate(_transactionDate),
        textlink.transactionReminderDate: _reminderDate != null ? _formatDate(_reminderDate!) : null,
        textlink.transactionNote: 'Debit Note',
        textlink.transactionIsCredited: status,
        textlink.transactionAccountId: selectedAccountId, // Assuming selectedAccountId is the ID of the user's account
        'user_id': currentUser.uid, // Correct the key here to 'user_id'
        textlink.transactionIsDelete: false,
      };

      await FirebaseFirestore.instance.collection(textlink.tbltransaction).doc(tnextId.toString()).set(transactionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Transaction added successfully")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error adding transaction")));
      }
    }
  }

  String? userId, userEmail;
  SharedPreferenceHelper spHelper = SharedPreferenceHelper();

  getDataFromSPHelper() async {
    userId = await spHelper.getUserId();
    userEmail = await spHelper.getUserEmail();
    setState(() {
    });
  }




  @override
  void initState() {
    getDataFromSPHelper();
    // TODO: implement initState
    super.initState();
    if(widget.name!=null && widget.id!=null && widget.flag!=null){
      selectedAccountName = widget.name;
      selectedAccountId = widget.id;
    }
  }
  Future<void> _selectDate(BuildContext context, DateTime initialDate,
      Function(DateTime) onDateSelected) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        title: const Text(
          "Transaction",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Account Name", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              InkWell(
                onTap: () {
                  if(widget.flag != true){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage(userId: userId.toString(),)))
                        .then((result) {
                      if (result != null) {
                        // Extract and store the result in variables
                        selectedAccountName = result['name'];
                        selectedAccountId = result['id'];
                        setState(() {

                        });
                      }
                    });
                  }


                },


                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:  EdgeInsets.symmetric(horizontal: 16),
                  child:  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        selectedAccountName!=null ? selectedAccountName.toString() : "Select Account",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Transaction", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: amtcon,
                      decoration: const InputDecoration(
                        hintText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _selectDate(context, _transactionDate, (pickedDate) {
                          setState(() {
                            _transactionDate = pickedDate;
                          });
                        });
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_formatDate(_transactionDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Reminder Transaction", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _isReminderChecked,
                    onChanged: (value) {
                      setState(() {
                        _isReminderChecked = value ?? false;
                      });
                    },
                  ),
                  const Text("Due Reminder"),
                  const Spacer(),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isReminderChecked
                          ? () {
                        _selectDate(
                          context,
                          _reminderDate ?? DateTime.now(),
                              (pickedDate) {
                            setState(() {
                              _reminderDate = pickedDate;
                            });
                          },
                        );
                      }
                          : null,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _reminderDate != null
                              ? _formatDate(_reminderDate!)
                              : "Select Date",
                          style: TextStyle(
                            color: _isReminderChecked ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Transaction Note", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Note',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final transactionData = {
                            textlink.transactionAmount: double.parse(amtcon.text),
                            textlink.transactionDate: _formatDate(_transactionDate),
                            textlink.transactionReminderDate: _reminderDate != null ? _formatDate(_reminderDate!) : null,
                            textlink.transactionNote: 'Debit Note',
                            textlink.transactionIsCredited: false,
                            textlink.transactionAccountId: textlink.accountId,
                          };

                          _addTransaction(false);
                          Navigator.pop(context, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("DEBIT"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final transactionData = {
                            textlink.transactionAmount: double.parse(amtcon.text),
                            textlink.transactionDate: _formatDate(_transactionDate),
                            textlink.transactionReminderDate: _reminderDate != null ? _formatDate(_reminderDate!) : null,
                            textlink.transactionNote: 'Credit Note',
                            textlink.transactionIsCredited: true,
                            textlink.transactionAccountId: textlink.accountId,
                          };

                          _addTransaction(true);
                          Navigator.pop(context, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("CREDIT"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
