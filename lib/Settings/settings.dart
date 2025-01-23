import 'package:currency_picker/currency_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Rename the Settings class to AppSettings to avoid conflicts
import '../../colors.dart';
import '../password/set_pin.dart';
import '../SharedPref/sharedpreferences.dart';
import 'all_accounts.dart';
import 'allpayment.dart';
import 'change_currency_page.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String selectedCurrency = 'USD'; // Default currency
  User? user;
  bool isToggled = false;


  void onToggleSwitch(bool value) {
    if (value) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SetPinScreen()),
      );
    }
    if (value == false) {
      SharedPreferenceHelper.deleteSpecific(prefKey: PrefKey.pin);
      setState(() {
        isToggled = value;
      });
    }
  }

  Future<void> ispinsave() async {
    String? savedPin = SharedPreferenceHelper.get(prefKey: PrefKey.pin);
    isToggled = savedPin != null ? true : false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
  }
  //
  // void onToggleSwitch(bool value) {
  //   setState(() {
  //     isToggled = value;
  //   });
  // }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // Redirect to Login Page after logout
      Navigator.of(context)
          .pushReplacementNamed('/login'); // Update route accordingly
    } catch (e) {
      print('Error logging out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to log out. Please try again.")),
      );
    }
  }


  // Function to launch the URL
  Future<void> _launchUrl(String links) async {
    final Uri _url =
    Uri.parse(links);
    if (!await launchUrl(_url)) {
      throw 'Could not launch $_url';
    }
  }

  void _showCompensationDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ledger Book'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('We are thanking you for using this app.'),
              SizedBox(height: 8),
              Text('Write us on'),
              GestureDetector(
                onTap: () {
                  _launchUrl("mailto:ledgerbook@gnhub.com");
                },
                child: Text(
                  'ledgerbook@gnhub.com',
                  style: TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
              SizedBox(height: 8),
              Text('Generation Next'),
              GestureDetector(
                onTap: () {
                  _launchUrl("http://www.gnhub.com/");
                },
                child: Text(
                  'http://www.gnhub.com/',
                  style: TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  _launchUrl('tel:+912612665403');
                },
                child: Text(
                  '+91 261 2665403',
                  style: TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
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
        automaticallyImplyLeading: false,
        leading: GestureDetector(
            onTap: (){
              Navigator.pop(context, true);
            },
            child: Icon(Icons.arrow_back)),
        foregroundColor: Colors.white,
        backgroundColor: themecolor,
        title: Text("Settings", style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          // Display user profile details
          _buildProfileDetails(),

          // Add all other settings cards
          _buildSettingsCard(
            icon: Icons.account_circle,
            title: "All Account",
            subtitle: "Manage All Account - Edit/Delete",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AllAccountsPage()),
              );
            },
          ),

          _buildSettingsCard(
            icon: Icons.payment,
            title: "All Payment",
            subtitle: "Manage All Payment - Filter/Edit/Delete",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AllPaymentPage()),
              );
            },
          ),
          _buildSettingsCard(
            icon: Icons.lock,
            title: "Enter PIN",
            subtitle: "Secure your app with a PIN.",
            leadingIcon: Icons.lock,  // Set leadingIcon to use the lock icon
            trailingWidget: Switch(
              value: isToggled,  // Current state of the switch
              onChanged: onToggleSwitch,  // Callback to toggle the switch
            ),
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
            onTap: () {
              showCurrencyPicker(
                context: context,
                showFlag: true,
                showCurrencyName: true,
                showCurrencyCode: true,
                onSelect: (Currency currency) {
                  print('Selected currency: ${currency.name}');
                  // Update the global currency symbol and the CurrencyManager
                  Provider.of<CurrencyManager>(context, listen: false).updateCurrency(currency.symbol);
                },
              );
            },
          ),
          _buildSettingsCard(
            icon: Icons.phone,
            title: "Contact Us",
            subtitle: "Communication Details",
            onTap: () {
              _showCompensationDetailsDialog(context);
            },
          ),

          // Add the Log Out option
          _buildSettingsCard(
            icon: Icons.logout,
            title: "Log Out",
            subtitle: "Sign out of your account",
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Display user avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: themecolor,
              child: Text(
                user?.email != null ? user!.email![0].toUpperCase() : '?',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            SizedBox(height: 12),

            // Display user email
            Text(
              user?.email ?? "Email not available",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),

            // Display user ID
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    void Function()? onTap,
    Widget? trailingWidget, // Add this parameter for trailing widget like Switch
    IconData? leadingIcon,  // Add this parameter to accept leadingIcon
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: leadingIcon != null
            ? Icon(leadingIcon, size: 40, color: Colors.black54) // Use leadingIcon if available
            : Icon(icon, size: 40, color: Colors.black54), // Default icon
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: trailingWidget, // Display the trailing widget here
      ),
    );
  }




// void _launchURL(String url) async {
  //   final Uri uri = Uri.parse(url); // Convert string URL to Uri
  //
  //   if (await canLaunchUrl(uri)) {
  //     // Check if the URL can be launched
  //     await launchUrl(uri); // Launch the URL
  //   } else {
  //     throw 'Could not launch $url'; // Throw an error if the URL cannot be launched
  //   }
  // }
}
