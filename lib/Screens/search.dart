import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;

  Future<void> _searchVendor() async {
    String vendorName = _searchController.text.toLowerCase();

    setState(() {
      searchResults = [];
      isSearching = true;
    });

    try {
      List<String> categories = [
        'Beauty Parlors',
        'Catering',
        'Farm Houses',
        'Marriage Halls',
        'Photographer',
        'Saloons'
      ];

      for (var category in categories) {
        QuerySnapshot snapshot = await _firestore.collection(category).get();

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String nameField;

          switch (category) {
            case 'Beauty Parlors':
            case 'Saloons':
              nameField = data['parlorName']?.toLowerCase() ?? '';
              break;
            case 'Catering':
            case 'Farm Houses':
            case 'Marriage Halls':
              nameField = data['name']?.toLowerCase() ?? '';
              break;
            case 'Photographer':
              nameField = data['photographerName']?.toLowerCase() ?? '';
              break;
            default:
              nameField = '';
          }

          if (nameField.contains(vendorName)) {
            setState(() {
              searchResults.add({
                'category': category,
                'data': data,
              });
            });
          }
        }
      }
    } catch (e) {
      _showErrorSnackbar(
          "Failed to search for vendor. Please try again later.");
    } finally {
      setState(() {
        isSearching = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Vendors'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter vendor name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onSubmitted: (value) {
                _searchVendor();
              },
            ),
            const SizedBox(height: 20),
            isSearching
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: searchResults.isEmpty
                        ? const Center(child: Text('Not found your vendor'))
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final result = searchResults[index];
                              final category = result['category'];
                              final data = result['data'];

                              String displayName;
                              switch (category) {
                                case 'Beauty Parlors':
                                case 'Saloons':
                                  displayName = data['parlorName'];
                                  break;
                                case 'Catering':
                                case 'Farm Houses':
                                case 'Marriage Halls':
                                  displayName = data['name'];
                                  break;
                                case 'Photographer':
                                  displayName = data['photographerName'];
                                  break;
                                default:
                                  displayName = 'Unknown';
                              }

                              return Card(
                                child: ListTile(
                                  title: Text(displayName),
                                  subtitle: Text('Category: $category'),
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
