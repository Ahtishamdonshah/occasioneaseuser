import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore

class beauty_porlor extends StatelessWidget {
  const beauty_porlor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beauty Parlors"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('Beauty Parlors').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No parlors found'));
          }

          // Fetch all documents and pass the document ID with data
          final parlors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: parlors.length,
            itemBuilder: (context, index) {
              final doc = parlors[index];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'Unnamed Parlor'),
                subtitle: Text(data['location'] ?? 'Location not provided'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParlorDetailsScreen(
                        parlorId: doc.id,
                        parlorData: data,
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

class ParlorDetailsScreen extends StatelessWidget {
  final String parlorId;
  final Map<String, dynamic> parlorData;

  const ParlorDetailsScreen(
      {Key? key, required this.parlorId, required this.parlorData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> images = List<String>.from(parlorData['images'] ?? []);
    final String name = parlorData['name'] ?? 'N/A';
    final String location = parlorData['location'] ?? 'N/A';
    final String serviceType = parlorData['serviceType'] ?? 'N/A';
    final double price = (parlorData['price'] ?? 0).toDouble();
    final String description =
        parlorData['description'] ?? 'No description available';
    final List<String> selectedServices =
        List<String>.from(parlorData['selectedServices'] ?? []);

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
                  // Parlor Name
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
                  ...selectedServices.map((service) =>
                      Text('• $service', style: const TextStyle(fontSize: 16))),
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
