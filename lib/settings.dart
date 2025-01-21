import 'package:flutter/material.dart';

// Rename the Settings class to AppSettings to avoid conflicts
import '../colors.dart'; // Import your custom colors file.


// Account table field names
class textlink {
  static const String tblAccount = "Account";
  static String accountId = "account_id";
  static String accountName = "account_name";
  static String accountContact = "account_contact";
  static String accountEmail = "account_email";
  static String accountDescription = "account_description";
  static String accountImage = "image";
  static String accountTotal = "account_total";
  static String accountDateAdded = "date_added";
  static String accountDateModified = "date_modified";
  static String accountIsDelete = "is_delete";

// Transaction table field names
  static String tbltransaction = "Transaction";
  static String transactionAccountId = "account_id";
  static String transactionId = "transaction_id";
  static String transactionAmount = "transaction_amount";
  static String transactionDate = "transaction_date";
  static String transactionIsDueReminder = "is_due_reminder";
  static String transactionReminderDate = "reminder_date";
  static String transactionIsCredited = "is_credited";
  static String transactionNote = "transaction_note";
  static String transactionDateAdded = "date_added";
  static String transactionDateModified = "date_modified";
  static String transactionIsDelete = "is_delete";

}

class AppSettings extends StatefulWidget {
  const AppSettings({super.key});

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themecolor,
        title: Text("Settings", style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          _buildSettingsCard(
            icon: Icons.account_circle,
            title: "All Account",
            subtitle: "Manage All Account - Edit/Delete",
          ),
          _buildSettingsCard(
            icon: Icons.payment,
            title: "All Payment",
            subtitle: "Manage All Payment - Filter/Edit/Delete",
          ),
          _buildSettingsCard(
            icon: Icons.lock,
            title: "Password Setting",
            subtitle: "Set/Reset Password",
          ),
          _buildSettingsCard(
            icon: Icons.cloud_upload,
            title: "Ledger Book Backup",
            subtitle: "Backup/Restore Your Ledger Book Entries",
          ),
          _buildSettingsCard(
            icon: Icons.currency_exchange,
            title: "Change Currency",
            subtitle: "Select Currency",
          ),
          _buildSettingsCard(
            icon: Icons.phone,
            title: "Contact Us",
            subtitle: "Communication Details",
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.grey),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: () {
          // Add navigation or functionality here
        },
      ),
    );
  }
}
