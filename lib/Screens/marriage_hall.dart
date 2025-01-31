import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:occasioneaseuser/Screens/MarriageHallDetailingScreen.dart';

class MarriageHall extends StatefulWidget {
  const MarriageHall({Key? key}) : super(key: key);

  @override
  _MarriageHallState createState() => _MarriageHallState();
}

class _MarriageHallState extends State<MarriageHall> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
          .map((doc) => doc.exists);
    }
    return Stream.value(false);
  }

  // Fetch marriage hall's rating from the 'rating' collection
  Future<double> _getHallRating(String vendorId) async {
    final ratingSnapshot =
        await _firestore.collection('rating').doc(vendorId).get();

    if (ratingSnapshot.exists) {
      final ratingData = ratingSnapshot.data() as Map<String, dynamic>;
      return ratingData['rating']?.toDouble() ??
          0.0; // Return rating or 0 if not found
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marriage Halls"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Marriage Halls').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No vendors found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final vendorId = doc.id;
              final vendorName = data['name'] ?? 'Unknown';

              return FutureBuilder<double>(
                future: _getHallRating(vendorId),
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MarriageHallDetailingScreen(
                                  hallId: vendorId,
                                  hallData: data,
                                  timeSlots: List<Map<String, dynamic>>.from(
                                      data['timeSlots'] ?? []),
                                ),
                              ),
                            );
                          },
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
    );
  }
}
