// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// import '../ADD/add_account.dart';
// import '../Settings/change_currency_page.dart';
// import '../Settings/settings.dart';
// import '../account_data.dart';
//
// class All extends StatefulWidget {
//   const All({Key? key}) : super(key: key);
//
//   @override
//   AllState createState() => AllState(); // Renamed to AllState
// }
//
// class AllState extends State<All> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   bool isLoading = true;
//   double totalCredit = 0.0;
//   double totalDebit = 0.0;
//   double totalAccountBalance = 0.0;
//
//   void refresh() {
//     setState(() {
//       // This will force the StreamBuilder to rebuild and fetch fresh data
//     });
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     setState(() {
//       isLoading = false;
//     });
//
//   }
//
//   Future<void> calculateTotals() async {
//     try {
//       final transactionSnapshot = await FirebaseFirestore.instance
//           .collection(textlink.tbltransaction)
//           .where("user_id", isEqualTo: _auth.currentUser?.uid)
//           .get();
//
//       double creditSum = 0.0;
//       double debitSum = 0.0;
//
//       for (var transaction in transactionSnapshot.docs) {
//         double amount = double.parse(transaction[textlink.transactionAmount].toString());
//         bool isCredit = transaction[textlink.transactionIsCredited] ?? false;
//
//         if (isCredit) {
//           creditSum += amount;
//         } else {
//           debitSum += amount;
//         }
//       }
//
//       setState(() {
//         totalCredit = creditSum;
//         totalDebit = debitSum;
//         totalAccountBalance = creditSum - debitSum;
//       });
//
//       print("Total Credit: $totalCredit");
//       print("Total Debit: $totalDebit");
//       print("Total Account Balance: $totalAccountBalance");
//
//     } catch (e) {
//       print("Error: $e");
//     }
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return isLoading
//         ? Center(child: CircularProgressIndicator())
//         : StreamBuilder(
//       stream: FirebaseFirestore.instance
//           .collection(textlink.tblAccount) // Collection name for accounts
//           .where("userId", isEqualTo: _auth.currentUser?.uid) // Filter by user
//           .snapshots(),
//         builder: (context, accountSnapshot) {
//           if (accountSnapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//
//           if (!accountSnapshot.hasData || accountSnapshot.data!.docs.isEmpty) {
//             return Center(child: Text("No accounts available."));
//           }
//
//           print("Fetched Accounts: ${accountSnapshot.data!.docs.length}"); // Log the data count
//           print("Account Data: ${accountSnapshot.data!.docs.map((doc) => doc.data())}"); // Log actual data
//
//           final accounts = accountSnapshot.data!.docs;
//
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 10),
//             child: ListView.separated(
//               itemCount: accounts.length,
//               separatorBuilder: (context, index) => Divider(),
//               itemBuilder: (context, index) {
//                 final account = accounts[index];
//
//                 final accountId = account[textlink.accountId];
//                 final accountName = account[textlink.accountName];
//                 final accountContact = account[textlink.accountContact];
//
//                 return StreamBuilder(
//                   stream: FirebaseFirestore.instance
//                       .collection(textlink.tbltransaction)
//                       .where("user_id", isEqualTo: _auth.currentUser?.uid)
//                       .where(textlink.accountId, isEqualTo: accountId) // Filter by uid
//                       .snapshots(),
//                   builder: (context, transactionSnapshot) {
//                     if (transactionSnapshot.connectionState == ConnectionState.waiting) {
//                       return ListTile(title: Text("Loading..."));
//                     }
//                     final transactions = transactionSnapshot.data?.docs ?? [];
//
//                     double creditSum = 0.0;
//                     double debitSum = 0.0;
//
//                     for (var transaction in transactions) {
//                       double amount = double.parse(transaction[textlink.transactionAmount].toString());
//                       bool isCredit = transaction[textlink.transactionIsCredited] ?? false;
//                       if (isCredit) {
//                         creditSum += amount;
//                       } else {
//                         debitSum += amount;
//                       }
//                     }
//                     double accountBalance = creditSum - debitSum;
//                     print(creditSum);
//                     print(debitSum);
//
//                     return ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: accountBalance >= 0 ? Colors.green : Colors.red,
//                         child: Text(
//                           accountName[0].toUpperCase(),
//                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       title: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Flexible(
//                             child: Text(
//                               accountName,
//                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                           Text(
//                             "${CurrencyManager.cr}${accountBalance.abs().toStringAsFixed(2)} ${accountBalance >= 0 ? 'CR' : 'DR'}",
//                             style: TextStyle(
//                               color: accountBalance >= 0 ? Colors.green : Colors.red,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 15,
//                             ),
//                           )
//                         ],
//                       ),
//                       subtitle: Text(accountContact),
//                       trailing: PopupMenuButton<String>(
//                         icon: const Icon(Icons.more_vert),
//                         onSelected: (value) async {
//                           if (value == 'edit') {
//                             final shouldRefresh = await Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => AddAccount(
//                                   name: accountName,
//                                   contact: accountContact,
//                                   id: accountId.toString(),
//                                   email: account[textlink.accountEmail],
//                                   description: account[textlink.accountDescription],
//                                 ),
//                               ),
//                             );
//
//                             if (shouldRefresh == true) {
//                               setState(() {});
//                               calculateTotals();
//                             }
//                           } else if (value == 'delete') {
//                             final shouldDelete = await showDialog<bool>(
//                               context: context,
//                               builder: (BuildContext context) {
//                                 return AlertDialog(
//                                   title: const Text('Confirm Delete'),
//                                   content: const Text('Are you sure you want to delete this account?'),
//                                   actions: [
//                                     TextButton(
//                                       onPressed: () => Navigator.of(context).pop(false),
//                                       child: const Text('Cancel'),
//                                     ),
//                                     TextButton(
//                                       onPressed: () => Navigator.of(context).pop(true),
//                                       child: const Text('Delete'),
//                                     ),
//                                   ],
//                                 );
//                               },
//                             );
//
//                             if (shouldDelete == true) {
//
//                               print("------------------------${accountId.toString()}");
//
//                               QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//                                   .collection(textlink.tbltransaction)
//                                   .where(textlink.transactionAccountId, isEqualTo: accountId)
//                                   .get();
//
//                               if (querySnapshot.docs.isEmpty) {
//                                 print("⚠️ No matching documents found for accountId: $accountId");
//                               } else {
//                                 for (var doc in querySnapshot.docs) {
//                                   print("📄 Found document: ${doc.id} - Reference: ${doc.reference}");
//                                   await doc.reference.delete();
//                                   print("✅ Deleted document: ${doc.id}");
//                                 }
//                               }
//
//                               await FirebaseFirestore.instance
//                                   .collection(textlink.tblAccount)
//                                   .doc(accountId.toString())
//                                   .delete();
//
//                               setState(() {});
//                               calculateTotals();
//                             }
//                           }
//                         },
//                         itemBuilder: (BuildContext context) => [
//                           PopupMenuItem(
//                             value: 'edit',
//                             child: Row(
//                               children: const [
//                                 Icon(Icons.edit, color: Colors.blue),
//                                 SizedBox(width: 8),
//                                 Text('Edit', style: TextStyle(fontSize: 16)),
//                               ],
//                             ),
//                           ),
//                           PopupMenuItem(
//                             value: 'delete',
//                             child: Row(
//                               children: const [
//                                 Icon(Icons.delete, color: Colors.red),
//                                 SizedBox(width: 8),
//                                 Text('Delete', style: TextStyle(fontSize: 16)),
//                               ],
//                             ),
//                           ),
//                         ],
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 4,
//                       ),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => AccountData(
//                               name: accountName,
//                               id: accountId,
//                               num: accountContact,
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             ),
//           );
//         }
//     );
//   }
// }
