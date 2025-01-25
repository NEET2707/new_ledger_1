import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:new_ledger_1/transaction_search.dart';

import '../account_data.dart';
import '../Settings/settings.dart';
import '../SharedPref/sharedpreferences.dart'; // For date formatting





class AddTransaction extends StatefulWidget {
  final String? name;
  final int? id;
  final bool? flag;
  final String? amount;
  final String? date;
  final String? note;
  final String? transactionId;  // Add transaction ID

  AddTransaction({
    super.key,
    this.id,
    this.name,
    this.flag,
    this.amount,
    this.date,
    this.note,
    this.transactionId,  // Receive transaction ID
  });

  @override
  State<AddTransaction> createState() => _AddTransactionState();
}


class _AddTransactionState extends State<AddTransaction> {

  final TextEditingController transactionNoteController = TextEditingController();
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

      final currentUser = FirebaseAuth.instance.currentUser;

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
        textlink.transactionNote: transactionNoteController.text,
        textlink.transactionIsCredited: status,
        textlink.transactionAccountId: selectedAccountId,
        'user_id': currentUser.uid,
        textlink.transactionIsDelete: false,
        textlink.transactionReminderDate: _reminderDate != null ? _formatDate(_reminderDate!) : null,  // Save reminder date
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
    super.initState();
    getDataFromSPHelper();

    if (widget.flag == true && widget.transactionId != null) {  // Editing mode
      amtcon.text = widget.amount ?? '';
      transactionDateController.text = widget.date ?? '';
      transactionNoteController.text = widget.note ?? '';
    }

    if (widget.name != null && widget.id != null) {
      selectedAccountName = widget.name;
      selectedAccountId = widget.id;
    }
  }

  @override
  void dispose() {
    transactionNoteController.dispose();
    transactionDateController.dispose();
    amtcon.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction(bool status) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No user is logged in")));
        }
        return;
      }

      final transactionData = {
        textlink.transactionAmount: double.parse(amtcon.text),
        textlink.transactionDate: _formatDate(_transactionDate),
        textlink.transactionNote: transactionNoteController.text,
        textlink.transactionIsCredited: status,
        textlink.transactionAccountId: selectedAccountId,
        'user_id': currentUser.uid,
        textlink.transactionIsDelete: false,
        textlink.transactionReminderDate: _reminderDate != null ? _formatDate(_reminderDate!) : null,  // Save reminder date
      };

      if (widget.transactionId != null) {
        await FirebaseFirestore.instance
            .collection(textlink.tbltransaction)
            .doc(widget.transactionId)
            .update(transactionData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Transaction updated successfully")));
        }
      } else {
        int tnextId = await tgetNextId();
        transactionData[textlink.transactionId] = tnextId;
        await FirebaseFirestore.instance
            .collection(textlink.tbltransaction)
            .doc(tnextId.toString())
            .set(transactionData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Transaction added successfully")));
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving transaction")));
      }
    }
  }



  Future<void> _selectDate(BuildContext context, DateTime initialDate,
      Function(DateTime) onDateSelected) async {
    final DateTime now = DateTime.now(); // Current date and time
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now, // Set the first date to today
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
    if (pickedDate != null && !pickedDate.isBefore(now)) { // Ensure the date is not in the past
      onDateSelected(pickedDate);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select a date not earlier than today.")),
        );
      }
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isReminderChecked = !_isReminderChecked;
                      });
                    },
                    child: const Text("Due Reminder"),
                  ),
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
              TextFormField(
                controller: transactionNoteController,
                decoration: const InputDecoration(
                  hintText: 'Enter Note',
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
                          if (widget.flag == true) {  // Use widget.flag to access the flag property
                            _saveTransaction(false);
                          } else {
                            _addTransaction(false);
                          }
                          Navigator.pop(context, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("DEBIT",style: TextStyle(color: Colors.white),),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          if (widget.flag == true) {  // Use widget.flag to access the flag property
                            _saveTransaction(true);
                          } else {
                            _addTransaction(true);
                          }
                          Navigator.pop(context, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("CREDIT",style: TextStyle(color: Colors.white),),
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