import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:occasioneaseuser/Screens/CateringDetailsScreen.dart';

class catering extends StatelessWidget {
  const catering({Key? key}) : super(key: key);

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
            return const Center(child: Text('No catering services found'));
          }

          final cateringServices = snapshot.data!.docs;

          return ListView.builder(
            itemCount: cateringServices.length,
            itemBuilder: (context, index) {
              final doc = cateringServices[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    data['cateringCompanyName'] ?? 'Unnamed Catering Service',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(data['location'] ?? 'Location not provided'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    // Fetching the time slots before navigation
                    List<String> timeSlots = [];
                    try {
                      final cateringDoc = await FirebaseFirestore.instance
                          .collection('Catering')
                          .doc(doc.id)
                          .get();

                      final slots = cateringDoc.data()?['timeSlots'] ?? [];
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

                    // Navigating to the CateringDetailsScreen with all necessary data
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CateringDetailsScreen(
                          cateringId: doc.id,
                          cateringData: data,
                          timeSlots: timeSlots,
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
