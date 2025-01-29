import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:occasioneaseuser/Screens/CateringDetailsScreen.dart';

class catering extends StatefulWidget {
  const catering({Key? key}) : super(key: key);

  @override
  _cateringState createState() => _cateringState();
}

class _cateringState extends State<catering> {
  Future<void> _toggleFavorite(String vendorId, bool isFavorite) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final vendorFavoritesRef = FirebaseFirestore.instance
          .collection('userFavorites')
          .doc(user.uid)
          .collection('vendors');
      final userFavoritesRef = FirebaseFirestore.instance
          .collection('userFavorites')
          .doc(user.uid)
          .collection('vendors');

      if (isFavorite) {
        //   await vendorFavoritesRef.doc(user.uid).delete();
        await userFavoritesRef.doc(vendorId).delete();
      } else {
        //  await vendorFavoritesRef.doc(user.uid).set({'userId': user.uid});
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
      appBar: AppBar(
        title: const Text("Catering Services"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Catering').snapshots(),
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
              final vendorName = data['cateringCompanyName'] ?? 'Unknown';

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
                            builder: (context) => CateringDetailsScreen(
                              cateringId: vendorId,
                              cateringData: data,
                              timeSlots:
                                  List<String>.from(data['timeslots'] ?? []),
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
