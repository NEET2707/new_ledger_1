// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:new_ledger_1/Settings/settings.dart';
//
// import '../Settings/change_currency_page.dart';
// import '../account_data.dart';
//
// class Debit extends StatefulWidget {
//   const Debit({Key? key}) : super(key: key);
//
//   @override
//   DebitState createState() => DebitState(); // Renamed to DebitState
// }
//
// class DebitState extends State<Debit> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   void refresh() {
//     setState(() {
//       // This will force the StreamBuilder to rebuild and fetch fresh data
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder(
//       stream: FirebaseFirestore.instance
//           .collection(textlink.tblAccount)
//           .where("userId", isEqualTo: _auth.currentUser?.uid)
//           .snapshots(),
//       builder: (context, accountSnapshot) {
//         if (accountSnapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         }
//         if (!accountSnapshot.hasData || accountSnapshot.data!.docs.isEmpty) {
//           return Center(child: Text("No debited accounts available."));
//         }
//
//         final accounts = accountSnapshot.data!.docs;
//
//         return FutureBuilder<List<Map<String, dynamic>>>(
//           future: _getFilteredAccounts(accounts),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return Center(child: CircularProgressIndicator());
//             }
//
//             final filteredAccounts = snapshot.data ?? [];
//
//             if (filteredAccounts.isEmpty) {
//               return Center(child: Text("No debited accounts available."));
//             }
//
//             return ListView.separated(
//               itemCount: filteredAccounts.length,
//               separatorBuilder: (context, index) => Divider(height: 1),
//               itemBuilder: (context, index) {
//                 final account = filteredAccounts[index];
//                 final accountId = account[textlink.accountId];
//                 final accountName = account[textlink.accountName];
//                 final accountContact = account[textlink.accountContact];
//                 final accountBalance = account['balance'];
//
//                 return ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.red,
//                     child: Text(accountName[0].toUpperCase(), style: TextStyle(color: Colors.white)),
//                   ),
//                   title: Text(accountName, style: TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: Text(accountContact),
//                   trailing: Text(
//                     "${CurrencyManager.cr}${(accountBalance ?? 0.0).abs().toStringAsFixed(2)} ${accountBalance != null && accountBalance < 0 ? 'CR' : 'DR'}",
//                     style: TextStyle(
//                       color: Colors.red,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                     ),
//                   ),
//
//
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => AccountData(
//                           name: accountName,
//                           id: accountId,
//                           num: accountContact,
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Future<List<Map<String, dynamic>>> _getFilteredAccounts(List<QueryDocumentSnapshot> accounts) async {
//     List<Map<String, dynamic>> filteredAccounts = [];
//
//     for (var account in accounts) {
//       final accountId = account[textlink.accountId];
//       final accountName = account[textlink.accountName];
//       final accountContact = account[textlink.accountContact];
//
//       final transactionSnapshot = await FirebaseFirestore.instance
//           .collection(textlink.tbltransaction)
//           .where("user_id", isEqualTo: _auth.currentUser?.uid)
//           .where("account_id", isEqualTo: accountId)
//           .get();
//
//       double creditSum = 0.0;
//       double debitSum = 0.0;
//
//       for (var transaction in transactionSnapshot.docs) {
//         double amount = double.parse(transaction[textlink.transactionAmount].toString());
//         bool isCredit = transaction[textlink.transactionIsCredited] ?? false;
//         if (isCredit) {
//           creditSum += amount;
//         } else {
//           debitSum += amount;
//         }
//       }
//
//       double accountBalance = creditSum - debitSum;
//       print("Account Balance for $accountName: $accountBalance");
//
//       if (accountBalance < 0) {
//         filteredAccounts.add({
//           textlink.accountId: accountId,  // Use the correct variable here
//           textlink.accountName: accountName,
//           textlink.accountContact: accountContact,
//           'balance': accountBalance,
//         });
//       }
//     }
//
//     return filteredAccounts;
//   }
// }