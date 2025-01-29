import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:occasioneaseuser/Screens/ParlorDetailsScreen.dart';

class HeartScreen extends StatefulWidget {
  const HeartScreen({Key? key}) : super(key: key);

  @override
  _HeartScreenState createState() => _HeartScreenState();
}

class _HeartScreenState extends State<HeartScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot>? _userFavoritesStream;

  @override
  void initState() {
    super.initState();
    _initUserFavoritesStream();
  }

  void _initUserFavoritesStream() {
    final user = _auth.currentUser;
    if (user != null) {
      _userFavoritesStream = _firestore
          .collection('userFavorites')
          .doc(user.uid)
          .collection('vendors')
          .snapshots();
    }
  }

  Future<void> _toggleFavorite(String vendorId) async {
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

      await favoritesRef.doc(user.uid).delete();
      await userFavoritesRef.doc(vendorId).delete();
    }
  }

  Future<Map<String, dynamic>?> _getVendorData(String vendorId) async {
    const List<Map<String, String>> collections = [
      {'collection': 'Beauty Parlors', 'nameField': 'parlorName'},
      {'collection': 'Saloons', 'nameField': 'parlorName'},
      {'collection': 'Farm Houses', 'nameField': 'name'},
      {'collection': 'Catering', 'nameField': 'cateringCompanyName'},
      {'collection': 'Marriage Halls', 'nameField': 'name'},
      {'collection': 'Photographer', 'nameField': 'photographerName'},
    ];

    for (var coll in collections) {
      final doc =
          await _firestore.collection(coll['collection']!).doc(vendorId).get();
      if (doc.exists) {
        return {
          'data': doc.data(),
          'nameField': coll['nameField'],
          'collection': coll['collection'],
        };
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorite Vendors"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _userFavoritesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No favorite vendors found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final vendorId = doc.id;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getVendorData(vendorId),
                builder: (context, vendorSnapshot) {
                  if (vendorSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const ListTile(title: Text('Loading...'));
                  }
                  if (vendorSnapshot.hasError || !vendorSnapshot.hasData) {
                    return ListTile(
                      title: Text('Error loading vendor'),
                    );
                  }

                  final vendorData = vendorSnapshot.data!;
                  final data = vendorData['data'] as Map<String, dynamic>;
                  final nameField = vendorData['nameField'] as String;
                  final vendorName = data[nameField] ?? 'Unknown';

                  return Card(
                    elevation: 4,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(vendorName,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: Icon(Icons.favorite, color: Colors.red),
                        onPressed: () async {
                          await _toggleFavorite(vendorId);
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
