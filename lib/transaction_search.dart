import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:new_ledger_1/Settings/settings.dart';
import 'package:new_ledger_1/colors.dart';

class SearchPage extends StatefulWidget {
  final String userId;

  SearchPage({Key? key, required this.userId}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Accounts"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search by Account Name",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                    });
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _searchQuery.isEmpty
                  ? FirebaseFirestore.instance
                  .collection(textlink.tblAccount)
                  .where('userId', isEqualTo: widget.userId)
                  .snapshots()
                  : FirebaseFirestore.instance
                  .collection(textlink.tblAccount)
                  .where('userId', isEqualTo: widget.userId)
                  .where(textlink.accountName, isGreaterThanOrEqualTo: _searchQuery)
                  .where(textlink.accountName, isLessThanOrEqualTo: _searchQuery + '\uf8ff')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No results found"));
                }

                // Map and display the results
                final accounts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: themecolor,
                        child: Text(
                          account[textlink.accountName][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(account[textlink.accountName]),
                      subtitle: Text(account[textlink.accountContact]),
                      onTap: () {
                        Navigator.pop(context, {
                          "name": account[textlink.accountName],
                          "id": account[textlink.accountId],
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
