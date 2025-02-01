import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:occasioneaseuser/Screens/SalonDetailsScreen.dart';

import 'package:occasioneaseuser/Screens/heart.dart';
import 'package:occasioneaseuser/Screens/home_screem.dart';
import 'package:occasioneaseuser/Screens/viewbooking.dart'; // Import BookingsScreen

class Salon extends StatefulWidget {
  const Salon({Key? key}) : super(key: key);

  @override
  _SalonState createState() => _SalonState();
}

class _SalonState extends State<Salon> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0; // To track selected bottom navigation tab

  // Function to fetch salon rating from the 'rating' collection
  Future<double> _getSalonRating(String vendorId) async {
    final ratingSnapshot =
        await _firestore.collection('rating').doc(vendorId).get();
    if (ratingSnapshot.exists) {
      final ratingData = ratingSnapshot.data() as Map<String, dynamic>;
      return ratingData['rating']?.toDouble() ??
          0.0; // Return rating or 0 if not found
    }
    return 0.0;
  }

  Future<void> _toggleFavorite(String vendorId, bool isFavorite) async {
    final user = _auth.currentUser;
    if (user != null) {
      final userFavoritesRef = _firestore
          .collection('userFavorites')
          .doc(user.uid)
          .collection('vendors');
      if (isFavorite) {
        await userFavoritesRef.doc(vendorId).delete();
      } else {
        await userFavoritesRef.doc(vendorId).set({'vendorId': vendorId});
      }
    }
  }

  Stream<bool> _isFavoriteStream(String vendorId) {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('userFavorites')
          .doc(user.uid)
          .collection('vendors')
          .doc(vendorId)
          .snapshots()
          .map((snapshot) => snapshot.exists);
    }
    return Stream.value(false);
  }

  // Function to build the rating stars UI
  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      stars.add(Icon(
        i < rating ? Icons.star : Icons.star_border,
        color: i < rating ? Colors.yellow : Colors.grey,
      ));
    }
    return Row(children: stars);
  }

  // Bottom Navigation Bar items
  final List<Widget> _pages = [
    HomeScreen(), // Home Screen widget
    HeartScreen(), // Heart Screen widget
    BookingsScreen(), // Bookings Screen widget
  ];

  // Navigation to the corresponding screen
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Use the Navigator to navigate to the selected page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => _pages[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saloons"),
        backgroundColor: Colors.blue, // Blue color for the AppBar
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Saloons').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No saloons found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final vendorId = doc.id;
              final vendorName = data['parlorName'] ?? 'Unknown';

              return FutureBuilder<double>(
                future: _getSalonRating(vendorId),
                builder: (context, ratingSnapshot) {
                  if (ratingSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      title: Text(vendorName),
                      trailing: const CircularProgressIndicator(),
                    );
                  }
                  if (ratingSnapshot.hasError) {
                    return ListTile(
                      title: Text(vendorName),
                      subtitle: const Text('Error fetching rating'),
                    );
                  }

                  final vendorRating = ratingSnapshot.data ?? 0.0;

                  return StreamBuilder<bool>(
                    stream: _isFavoriteStream(vendorId),
                    builder: (context, favoriteSnapshot) {
                      if (favoriteSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return ListTile(
                          title: Text(vendorName),
                          trailing: const CircularProgressIndicator(),
                        );
                      }

                      bool isFavorite = favoriteSnapshot.data ?? false;

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        child: ListTile(
                          title: Text(vendorName,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRatingStars(
                                  vendorRating), // Display rating stars
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : null,
                            ),
                            onPressed: () async {
                              await _toggleFavorite(vendorId, isFavorite);
                            },
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SalonDetailsScreen(
                                salonId: vendorId,
                                salonData: data,
                                timeSlots: List<Map<String, dynamic>>.from(
                                    data['timeSlots'] ?? []),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor:
            Colors.blue[700], // Blue color for the bottom navigation bar
        selectedItemColor: Colors.white, // White color for selected icon
        unselectedItemColor: Colors.white60, // Light color for unselected icons
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Heart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Bookings',
          ),
        ],
      ),
    );
  }
}
