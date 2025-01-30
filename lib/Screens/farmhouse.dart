import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:occasioneaseuser/Screens/FarmhouseDetailsScreen.dart';

class Farmhouse extends StatefulWidget {
  const Farmhouse({Key? key}) : super(key: key);

  @override
  _FarmhouseState createState() => _FarmhouseState();
}

class _FarmhouseState extends State<Farmhouse> {
  Future<void> _toggleFavorite(String vendorId, bool isFavorite) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userFavoritesRef = FirebaseFirestore.instance
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('userFavorites')
          .doc(user.uid)
          .collection('vendors')
          .doc(vendorId)
          .snapshots()
          .map((doc) => doc.exists);
    }
    return Stream.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Farmhouses")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('Farm Houses').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError)
            return const Center(child: Text('Error fetching data'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No farmhouses found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final vendorId = doc.id;
              final images = List<String>.from(data['imageUrls'] ?? []);

              return StreamBuilder<bool>(
                stream: _isFavoriteStream(vendorId),
                builder: (context, favoriteSnapshot) {
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            itemCount: images.length,
                            itemBuilder: (context, imgIndex) => Image.network(
                              images[imgIndex],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text(data['name'] ?? 'Unknown'),
                          subtitle: Text(data['location'] ?? ''),
                          trailing: IconButton(
                            icon: Icon(
                              favoriteSnapshot.data ?? false
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: favoriteSnapshot.data ?? false
                                  ? Colors.red
                                  : null,
                            ),
                            onPressed: () => _toggleFavorite(
                                vendorId, favoriteSnapshot.data ?? false),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FarmhouseDetailingScreen(
                                  farmhouseId: vendorId,
                                  farmhouseData: data,
                                  timeSlots: List<Map<String, dynamic>>.from(
                                      data['timeSlots'] ?? []),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 0),
    );
  }

  BottomNavigationBar _buildBottomNavBar(BuildContext context, int index) {
    return BottomNavigationBar(
      currentIndex: index,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (idx) {
        if (idx == 1) Navigator.pushNamed(context, '/favorites');
        if (idx == 2) Navigator.pushNamed(context, '/profile');
      },
    );
  }
}
