import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:occasioneaseuser/Screens/ParlorDetailsScreen.dart';

class beauty_porlor extends StatefulWidget {
  const beauty_porlor({Key? key}) : super(key: key);

  @override
  _beauty_porlorState createState() => _beauty_porlorState();
}

class _beauty_porlorState extends State<beauty_porlor> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _toggleFavorite(String vendorId, bool isFavorite) async {
    final user = _auth.currentUser;
    if (user != null) {
      final favoritesRef = _firestore
          .collection('userFavorites')
          .doc(user.uid)
          .collection('vendors');

      final userFavoritesRef = _firestore
          .collection('userFavorites')
          .doc(user.uid)
          .collection('vendors');

      if (isFavorite) {
        // Remove from vendor's favorites
        // await favoritesRef.doc(user.uid).delete();
        // Remove from user's favorites
        await userFavoritesRef.doc(vendorId).delete();
      } else {
        // Add to vendor's favorites
        //   await favoritesRef.doc(user.uid).set({'userId': user.uid});
        // Add to user's favorites
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beauty Parlors"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('Beauty Parlors').snapshots(),
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
              final vendorName = data['parlorName'] ?? 'Unknown';

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
                      trailing: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
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
                            builder: (context) => ParlorDetailsScreen(
                              parlorId: vendorId,
                              parlorData: data,
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
      ),
    );
  }
}
