// Future<bool> _checkContactPermission() async {
//   try {
//     final status = await Permission.contacts.status;
//     if (status.isGranted) {
//       return true;
//     } else if (status.isDenied || status.isPermanentlyDenied) {
//       final result = await Permission.contacts.request();
//       return result.isGranted;
//     }
//   } catch (e) {
//     print("Error checking contact permission: $e");
//   }
//   return false;
// }
//
//
// Future<void> _pickContact() async {
//   String a="";
//   String b="";
//   try {
//     if (await _checkContactPermission()) {
//       print("Attempting to pick a contact...");
//       final contact = await _contactPicker.selectContact();
//
//       if (contact != null) {
//         a = contact.fullName ?? "No Name Available";
//         b = (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty)
//             ? contact.phoneNumbers![0]
//             : "No Phone Number Available";
//
//         if (!mounted) return;
//
//         await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => AddAccount(
//               name: a,
//               contact: b,
//               id: '0',
//             ),
//           ),
//         );
//       } else {
//         print("No contact selected.");
//       }
//     } else {
//       print("Permission denied.");
//     }
//   } catch (e, stackTrace) {
//     print("Error picking contact: $e\n$stackTrace");
//   }
//
//   print("---------------------> $a");
//   print("---------------------> $b");
//   // try {
//   //   await FirebaseFirestore.instance.collection(textlink.tblAccount).doc(nextId.toString()).set({
//   //     'na': a.toString(),
//   //   });
//   //   print("Account added successfully.");
//   // } catch (e) {
//   //   print("Error adding account: $e");
//   // }
//
// }