import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore

class farmhouse extends StatelessWidget {
  const farmhouse({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmhouses"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(
                'Farm Houses') // Fetch data from 'Farmhouses' collection
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No farmhouses found'));
          }

          // Fetch all documents and pass the document ID with data
          final farmhouses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: farmhouses.length,
            itemBuilder: (context, index) {
              final doc = farmhouses[index];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'Unnamed Farmhouse'),
                subtitle: Text(data['location'] ?? 'Location not provided'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FarmhouseDetailsScreen(
                        farmhouseId: doc.id,
                        farmhouseData: data,
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

class FarmhouseDetailsScreen extends StatelessWidget {
  final String farmhouseId;
  final Map<String, dynamic> farmhouseData;
  final String userId;

  const FarmhouseDetailsScreen(
      {Key? key,
      required this.farmhouseId,
      required this.farmhouseData,
      required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        List<String>.from(farmhouseData['images'] ?? []);
    final String name = farmhouseData['name'] ?? 'N/A';
    final String location = farmhouseData['location'] ?? 'N/A';
    final String serviceType = farmhouseData['serviceType'] ?? 'N/A';
    final double price = (farmhouseData['price'] ?? 0).toDouble();
    final String description =
        farmhouseData['description'] ?? 'No description available';
    final List<String> selectedServices =
        List<String>.from(farmhouseData['selectedServices'] ?? []);

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
                  // Farmhouse Name
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
