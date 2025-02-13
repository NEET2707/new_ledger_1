import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:new_ledger_1/Settings/settings.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'ADD/add_account.dart';
import 'ADD/add_transaction.dart';
import 'Settings/change_currency_page.dart';
import 'colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AccountData extends StatefulWidget {
  final String name;
  final String num;
  final int id;

  AccountData(
      {super.key, required this.name, required this.num, required this.id});

  @override
  State<AccountData> createState() => _AccountDataState();
}

class _AccountDataState extends State<AccountData>
    with TickerProviderStateMixin {
  double accountBalance = 0.0;
  double totalCredit = 0.0;
  double totalDebit = 0.0;
  bool isLoading = true;
  bool showContent = false;

  @override
  void initState() {
    super.initState();
    fetchTransactionData(); // Fetch transaction data

    // Show content after a delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showContent = true;
        isLoading = false;
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

      for (var doc in querySnapshot.docs) {
        double amount =
            double.parse(doc[textlink.transactionAmount].toString());
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
      setState(() {
        isLoading = false;
      });
    });
  }

  Color getBalanceColor() {
    if (accountBalance == 0) {
      return themecolor;
    } else if (accountBalance > 0) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

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
    super.dispose();
  }

  Future<void> _launchUrl(String links) async {
    final Uri _url = Uri.parse(links);
    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showContent
          ? AppBar(
              foregroundColor: Colors.white,
              backgroundColor:
                  getAppBarColor(),
              title: Text(
                widget.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (BuildContext context) {
                        return Wrap(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Ledger Book",
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.share),
                              title: const Text("Share Transaction"),
                              onTap: () {
                                Navigator.pop(context); // Close the bottom sheet

                                String message =
                                    "Account Name: ${widget.name}\n"
                                    "Account Balance: ${accountBalance.toStringAsFixed(2)}\n"
                                    "Total Credit: ${totalCredit.toStringAsFixed(2)}\n"
                                    "Total Debit: ${totalDebit.toStringAsFixed(2)}\n";

                                Share.share(message);
                              },
                            ),

                            ListTile(
                              leading: const Icon(Icons.download),
                              title: const Text("Download Transaction Pdf"),
                              onTap: () async {
                                final pdf = pw.Document();

                                QuerySnapshot transactionSnapshot =
                                    await FirebaseFirestore.instance
                                        .collection(textlink.tbltransaction)
                                        .where(textlink.transactionAccountId,
                                            isEqualTo: widget.id)
                                        .get();

                                List<pw.Widget> transactionWidgets = [];

                                for (var doc in transactionSnapshot.docs) {
                                  String date = doc[textlink.transactionDate] ??
                                      "Unknown Date";
                                  double amount = double.parse(
                                      doc[textlink.transactionAmount]
                                          .toString());
                                  bool isCredit =
                                      doc[textlink.transactionIsCredited] ??
                                          false;
                                  String transactionType =
                                      isCredit ? "Credit" : "Debit";

                                  transactionWidgets.add(
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: pw.Row(
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text(date,
                                              style:
                                                  pw.TextStyle(fontSize: 12)),
                                          pw.Text("$amount",
                                              style:
                                                  pw.TextStyle(fontSize: 12)),
                                          pw.Text(transactionType,
                                              style:
                                                  pw.TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                pdf.addPage(
                                  pw.Page(
                                    pageFormat: PdfPageFormat.a4,
                                    build: (pw.Context context) {
                                      return pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.start,
                                        children: [
                                          pw.Text(
                                              "Account Name: ${widget.name}",
                                              style: pw.TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      pw.FontWeight.bold)),
                                          pw.Text(
                                              "Account Balance: ${accountBalance.toStringAsFixed(2)}",
                                              style:
                                                  pw.TextStyle(fontSize: 14)),
                                          pw.SizedBox(height: 10),
                                          pw.Divider(),
                                          pw.Text("Transactions:",
                                              style: pw.TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      pw.FontWeight.bold)),
                                          pw.SizedBox(height: 10),
                                          ...transactionWidgets, // Display transactions
                                        ],
                                      );
                                    },
                                  ),
                                );

                                // Display PDF preview
                                await Printing.layoutPdf(
                                  onLayout: (PdfPageFormat format) async =>
                                      pdf.save(),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.clear_outlined),
                              title: const Text("Clear Account"),
                              onTap: () {
                                Navigator.pop(
                                    context); // Close the bottom sheet
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text("Confirm Delete"),
                                      content: const Text(
                                          "Are you sure you want to delete all account data? This action cannot be undone."),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.pop(context); // Close the dialog

                                            try {
                                              FirebaseFirestore firestore = FirebaseFirestore.instance;

                                              await firestore
                                                  .collection("Transaction")
                                                  .where(textlink.accountId, isEqualTo: widget.id) // Filter by account_id
                                                  .get()
                                                  .then((snapshot) {
                                                for (var doc in snapshot.docs) {
                                                  doc.reference.delete(); // Delete each transaction
                                                }
                                              });

                                              print("All transactions for account ${widget.id} deleted");

                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("All transactions deleted")),
                                                );
                                              }
                                            } catch (e) {
                                              print("Error deleting transactions: $e");

                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Error deleting transactions")),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text("Edit Account Detail"),
                              onTap: () {

                                Navigator.pop(context);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddAccount(
                                      name: widget.name,
                                      contact: widget.num,
                                      id: widget.id.toString(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete),
                              title: const Text("Delete Account"),
                              onTap: () async{
                                QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                                    .collection(textlink.tbltransaction)
                                    .where(textlink.transactionAccountId, isEqualTo: widget.id)
                                    .get();

                                if (querySnapshot.docs.isEmpty) {
                                } else {
                                  for (var doc in querySnapshot.docs) {
                                    print("Found document: ${doc.id} - Reference: ${doc.reference}");
                                    await doc.reference.delete();
                                    print("Deleted document: ${doc.id}");
                                  }
                                }

                                await FirebaseFirestore.instance
                                    .collection(textlink.tblAccount)
                                    .doc(widget.id.toString())
                                    .delete();

                                  setState(() {});
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            )
          : PreferredSize(
              preferredSize:
                  const Size.fromHeight(0),
              child: Container(),
            ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : showContent
              ? SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: getBalanceColor(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    _launchUrl('tel:${widget.num}');
                                  },
                                  child: Icon(Icons.call,
                                      color: Colors.white, size: 18),
                                ),
                                SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    _launchUrl('tel:${widget.num}');
                                  },
                                  child: Text(
                                    widget.num,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
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
                              "${CurrencyManager.cr}${accountBalance >= 0 ? accountBalance.toStringAsFixed(2) : accountBalance.abs().toStringAsFixed(2)} ${accountBalance >= 0 ? 'CR' : 'DR'}",
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
                                      "${CurrencyManager.cr}${totalCredit.toStringAsFixed(2)} Credit",
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
                                      "${CurrencyManager.cr}${totalDebit.toStringAsFixed(2)} Debit",
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
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection(textlink.tbltransaction)
                            .where(textlink.transactionAccountId,
                                isEqualTo: widget.id)
                            .snapshots(),
                        builder: (context, snapshots) {
                          if (snapshots.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (snapshots.hasError) {
                            return Center(
                                child: Text(
                                    "Error: ${snapshots.error.toString()}"));
                          }

                          if (!snapshots.hasData ||
                              snapshots.data!.docs.isEmpty) {
                            return const Center(
                                child: Text("No transactions available."));
                          }

                          final transactions = snapshots.data!.docs;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 50),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = transactions[index];
                                final isCredit = transaction[
                                        textlink.transactionIsCredited] ??
                                    false;
                                final transactionId = transaction.id;
                                final amount =
                                    transaction[textlink.transactionAmount];
                                final date =
                                    transaction[textlink.transactionDate];
                                final note =
                                    transaction[textlink.transactionNote];
                                final reminder = transaction[
                                    textlink.transactionReminderDate];

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        isCredit ? Colors.green : Colors.red,
                                    child: Icon(
                                      isCredit
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    "${CurrencyManager.cr}${amount.abs().toStringAsFixed(2)} ${isCredit ? 'CR' : 'DR'}",
                                    style: TextStyle(
                                      color:
                                          isCredit ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        date ?? 'No date available',
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(height: 4),
                                      if (note != null && note.isNotEmpty) ...[
                                        Text(
                                          note ?? '',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      if (reminder != null &&
                                          reminder.isNotEmpty) ...[
                                        if (reminder != null &&
                                            reminder.isNotEmpty) ...[
                                          Text(
                                            "due on: $reminder",
                                            style: const TextStyle(
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        print(transaction[
                                            textlink.transactionIsCredited]);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AddTransaction(
                                              id: widget.id,
                                              name: widget.name,
                                              flag:
                                                  true, // Indicates editing mode
                                              transactionId:
                                                  transactionId, // Pass transaction ID
                                              amount: transaction[textlink
                                                      .transactionAmount]
                                                  .toString(),
                                              date: transaction[
                                                  textlink.transactionDate],
                                              note: transaction[textlink
                                                      .transactionNote] ??
                                                  '',
                                              reminderDate: transaction[textlink
                                                  .transactionReminderDate],
                                              check: transaction[textlink
                                                      .transactionIsCredited] ??
                                                  false,
                                            ),
                                          ),
                                        );
                                      } else if (value == 'delete') {
                                        final shouldDelete =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title:
                                                  const Text('Confirm Delete'),
                                              content: const Text(
                                                  'Are you sure you want to delete this transaction?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (shouldDelete == true) {
                                          await FirebaseFirestore.instance
                                              .collection(
                                                  textlink.tbltransaction)
                                              .doc(transactionId)
                                              .delete();

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Transaction deleted successfully'),
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
                                            Icon(Icons.edit,
                                                color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Edit',
                                                style: TextStyle(fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: const [
                                            Icon(Icons.delete,
                                                color: Colors.red),
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
                                );
                              },
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                color: Colors.grey,
                                height: 1,
                              ),
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
                flag: false,
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
