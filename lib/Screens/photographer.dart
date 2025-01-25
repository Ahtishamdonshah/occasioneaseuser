import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:occasioneaseuser/Screens/PhotographerDetailsScreen.dart';

class photographer extends StatelessWidget {
  const photographer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Photographers"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('Photographer').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No photographers found'));
          }

          final photographers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: photographers.length,
            itemBuilder: (context, index) {
              final doc = photographers[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    data['photographerName'] ?? 'Unnamed Photographer',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(data['location'] ?? 'Location not provided'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    // Fetching the time slots before navigation
                    List<String> timeSlots = [];
                    try {
                      final photographerDoc = await FirebaseFirestore.instance
                          .collection('Photographer')
                          .doc(doc.id)
                          .get();

                      // Extracting time slots in the format: "startTime - endTime"
                      final slots = photographerDoc.data()?['timeSlots'] ?? [];
                      for (var slot in slots) {
                        String startTime = slot['startTime'] ?? '';
                        String endTime = slot['endTime'] ?? '';
                        timeSlots.add('$startTime - $endTime');
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Error fetching time slots')),
                      );
                    }

                    // Navigating to the PhotographerDetailsScreen with all necessary data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotographerDetailsScreen(
                          photographerId: doc.id,
                          photographerData: data,
                          timeSlots:
                              timeSlots, // Passing the formatted timeSlots here
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
