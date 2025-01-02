import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore

class saloon extends StatelessWidget {
  const saloon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salons"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Saloons') // Fetch data from 'Salons' collection
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No salons found'));
          }

          // Fetch all documents and pass the document ID with data
          final salons = snapshot.data!.docs;

          return ListView.builder(
            itemCount: salons.length,
            itemBuilder: (context, index) {
              final doc = salons[index];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'Unnamed Salon'),
                subtitle: Text(data['location'] ?? 'Location not provided'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalonDetailsScreen(
                        salonId: doc.id,
                        salonData: data,
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

class SalonDetailsScreen extends StatelessWidget {
  final String salonId;
  final Map<String, dynamic> salonData;
  final String userId;

  const SalonDetailsScreen(
      {Key? key,
      required this.salonId,
      required this.salonData,
      required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> images = List<String>.from(salonData['images'] ?? []);
    final String name = salonData['name'] ?? 'N/A';
    final String location = salonData['location'] ?? 'N/A';
    final String serviceType = salonData['serviceType'] ?? 'N/A';
    final double price = (salonData['price'] ?? 0).toDouble();
    final String description =
        salonData['description'] ?? 'No description available';
    final List<String> selectedServices =
        List<String>.from(salonData['selectedServices'] ?? []);
    final String vendorId = salonData['vendorId'] ?? 'Unknown Vendor';

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
                  // Salon Name
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
