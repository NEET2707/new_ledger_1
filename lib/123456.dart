// @override
// void initState() {
//   super.initState();
//   calculateTotals();
//
// }
//
// // Function to recalculate the totals
// void calculateTotals() async {
//   setState(() {
//     isLoading = true; // Start loading
//   });
//
//   double creditSum = 0.0;
//   double debitSum = 0.0;
//
//   final accountSnapshot = await FirebaseFirestore.instance.collection(tblAccount).get();
//
//   for (var account in accountSnapshot.docs) {
//     final accountId = account["account_id"];
//     final transactionSnapshot = await FirebaseFirestore.instance
//         .collection(tbltransaction)
//         .where(transactionAccountId, isEqualTo: accountId)
//         .get();
//
//     for (var transaction in transactionSnapshot.docs) {
//       double amount = double.parse(transaction[transactionAmount].toString());
//       bool isCredit = transaction[transactionIsCredited] ?? false;
//
//       if (isCredit) {
//         creditSum += amount;
//       } else {
//         debitSum += amount;
//       }
//     }
//   }
//
//   setState(() {
//     totalCredit = creditSum;
//     totalDebit = debitSum;
//     totalAccountBalance = creditSum - debitSum;
//     isLoading = false; // Stop loading
//   });
// }
//
//
// Container(
// color: Colors.blueAccent,
// padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
// child: Column(
// crossAxisAlignment: CrossAxisAlignment.center,
// children: [
// Text(
// "Current A/C:",
// style: TextStyle(fontSize: 16, color: Colors.white),
// ),
// SizedBox(height: 4),
// Text(
// "₹ ${totalAccountBalance.toStringAsFixed(2)}",
// style: TextStyle(
// fontSize: 20,
// fontWeight: FontWeight.bold,
// color: Colors.white,
// ),
// ),
// SizedBox(height: 8),
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// _buildSummaryItem(Icons.arrow_upward_rounded, "₹ ${totalCredit.toStringAsFixed(2)} Credit", Colors.green),
// _buildSummaryItem(Icons.arrow_downward_rounded, "₹ ${totalDebit.toStringAsFixed(2)} Debit", Colors.red),
// ],
// ),
// ],
// ),
// ),



// Account table field names
const String tblAccount = "Account";
const String accountId = "account_id";
const String accountName = "account_name";
const String accountContact = "account_contact";
const String accountEmail = "account_email";
const String accountDescription = "account_description";
const String accountImage = "image";
const String accountTotal = "account_total";
const String accountDateAdded = "date_added";
const String accountDateModified = "date_modified";
const String accountIsDelete = "is_delete";

// Transaction table field names
const String tbltransaction = "Transaction";
const String transactionAccountId = "account_id";
const String transactionId = "transaction_id";
const String transactionAmount = "transaction_amount";
const String transactionDate = "transaction_date";
const String transactionIsDueReminder = "is_due_reminder";
const String transactionReminderDate = "reminder_date";
const String transactionIsCredited = "is_credited";
const String transactionNote = "transaction_note";
const String transactionDateAdded = "date_added";
const String transactionDateModified = "date_modified";
const String transactionIsDelete = "is_delete";