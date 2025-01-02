import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore

class marriage_hall extends StatelessWidget {
  const marriage_hall({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marriage Halls"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(
                'Marriage Halls') // Fetch data from 'Marriage Halls' collection
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No marriage halls found'));
          }

          // Fetch all documents and pass the document ID with data
          final marriageHalls = snapshot.data!.docs;

          return ListView.builder(
            itemCount: marriageHalls.length,
            itemBuilder: (context, index) {
              final doc = marriageHalls[index];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'Unnamed Marriage Hall'),
                subtitle: Text(data['location'] ?? 'Location not provided'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarriageHallDetailsScreen(
                        marriageHallId: doc.id,
                        marriageHallData: data,
                        userId: data['userId'] ?? 'Unknown User', // Pass userId
                      ),
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

class MarriageHallDetailsScreen extends StatelessWidget {
  final String marriageHallId;
  final Map<String, dynamic> marriageHallData;
  final String userId;

  const MarriageHallDetailsScreen(
      {Key? key,
      required this.marriageHallId,
      required this.marriageHallData,
      required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        List<String>.from(marriageHallData['images'] ?? []);
    final String name = marriageHallData['name'] ?? 'N/A';
    final String location = marriageHallData['location'] ?? 'N/A';
    final String serviceType = marriageHallData['serviceType'] ?? 'N/A';
    final double price = (marriageHallData['price'] ?? 0).toDouble();
    final String description =
        marriageHallData['description'] ?? 'No description available';
    final List<String> selectedServices =
        List<String>.from(marriageHallData['selectedServices'] ?? []);
    final String vendorId = marriageHallData['vendorId'] ?? 'Unknown Vendor';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images Carousel
            if (images.isNotEmpty)
              Container(
                height: 200,
                child: PageView(
                  children: images
                      .map(
                        (url) => Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Text('Image not available')),
                        ),
                      )
                      .toList(),
                ),
              )
            else
              const Center(child: Text('No images available')),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Marriage Hall Name
                  Text(name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Location
                  Text('Location: $location',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),

                  // Service Type
                  Text('Service Type: $serviceType',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),

                  // Price
                  Text('Price: \$${price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),

                  // Description
                  const Text('Description:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),

                  // Services
                  const Text('Services:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (selectedServices.isNotEmpty)
                    ...selectedServices.map((service) => Text('• $service',
                        style: const TextStyle(fontSize: 16)))
                  else
                    const Text('No specific services listed.',
                        style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),

                  // Vendor ID
                  const Text('Vendor ID:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(vendorId, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),

                  // User ID
                  const Text('User ID:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(userId, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),

                  // Book Now Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement booking functionality
                      },
                      child: const Text('Book Now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
