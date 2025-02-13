import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:occasioneaseuser/Screens/CateringDetailsScreen.dart';
import 'package:occasioneaseuser/Screens/FarmhouseDetailsScreen.dart';
import 'package:occasioneaseuser/Screens/MarriageHallDetailingScreen.dart';
import 'package:occasioneaseuser/Screens/ParlorDetailsScreen.dart';
import 'package:occasioneaseuser/Screens/PhotographerDetailsScreen.dart';
import 'package:occasioneaseuser/Screens/SalonDetailsScreen.dart';

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
              nameField = data['cateringCompanyName']?.toLowerCase() ?? '';
              break;
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
            double? rating =
                (data.containsKey('rating') && data['rating'] != null)
                    ? data['rating'].toDouble()
                    : null; // Null if rating does not exist

            setState(() {
              searchResults.add({
                'id': doc.id,
                'category': category,
                'data': data,
                'rating': rating,
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
        backgroundColor: Colors.blue,
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
                filled: true,
                fillColor: Colors.white,
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
                        ? const Center(child: Text('No vendors found'))
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final result = searchResults[index];
                              final category = result['category'];
                              final data = result['data'];
                              final rating = result['rating']; // Get rating

                              String displayName;
                              switch (category) {
                                case 'Beauty Parlors':
                                case 'Saloons':
                                  displayName = data['parlorName'];
                                  break;
                                case 'Catering':
                                  displayName = data['cateringCompanyName'];
                                  break;
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
                                elevation: 4,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: ListTile(
                                  title: Text(displayName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Category: $category'),
                                      Row(
                                        children: List.generate(5, (index) {
                                          return Icon(
                                            Icons.star,
                                            color: rating != null &&
                                                    index < rating.round()
                                                ? Colors.yellow
                                                : Colors.grey,
                                            size: 18,
                                          );
                                        }),
                                      ),
                                      const SizedBox(width: 5),
                                    ],
                                  ),
                                  onTap: () => _navigateToDetailsScreen(result),
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

  Future<void> _navigateToDetailsScreen(Map<String, dynamic> vendor) async {
    String category = vendor['category'];
    String vendorId = vendor['id'];
    Map<String, dynamic> vendorData = vendor['data'];
    List<String> timeslots = List<String>.from(vendorData['timeslots'] ?? []);
    final List<Map<String, dynamic>> timeSlots =
        List<Map<String, dynamic>>.from(vendorData['timeSlots'] ?? []);

    switch (category) {
      case 'Beauty Parlors':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParlorDetailsScreen(
              parlorId: vendorId,
              parlorData: vendorData,
              timeSlots: timeSlots,
            ),
          ),
        );
        break;
      case 'Saloons':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SalonDetailsScreen(
              salonId: vendorId,
              salonData: vendorData,
              timeSlots: vendorData['timeSlots'],
            ),
          ),
        );
        break;
      case 'Catering':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CateringDetailsScreen(
              cateringId: vendorId,
              cateringData: vendorData,
              timeSlots: vendorData['timeSlots'],
            ),
          ),
        );
        break;
      case 'Photographer':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotographerDetailsScreen(
              photographerId: vendorId,
              photographerData: vendorData,
              timeSlots: vendorData['timeSlots'],
            ),
          ),
        );
        break;
      case 'Farm Houses':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FarmhouseDetailingScreen(
              farmhouseId: vendorId,
              farmhouseData: vendorData,
              timeSlots: vendorData['timeSlots'],
            ),
          ),
        );
        break;
      case 'Marriage Halls':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarriageHallDetailingScreen(
              hallId: vendorId,
              hallData: vendorData,
              timeSlots: vendorData['timeSlots'],
            ),
          ),
        );
        break;
    }
  }
}
