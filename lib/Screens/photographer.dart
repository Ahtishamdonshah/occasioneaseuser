import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:occasioneaseuser/Screens/quantityphotographer.dart';

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

class PhotographerDetailsScreen extends StatefulWidget {
  final String photographerId;
  final Map<String, dynamic> photographerData;
  final List<String> timeSlots;

  const PhotographerDetailsScreen({
    Key? key,
    required this.photographerId,
    required this.photographerData,
    required this.timeSlots, // Receiving timeSlots here
  }) : super(key: key);

  @override
  _PhotographerDetailsScreenState createState() =>
      _PhotographerDetailsScreenState();
}

class _PhotographerDetailsScreenState extends State<PhotographerDetailsScreen> {
  final Map<String, List<Map<String, dynamic>>> _servicesByCategory = {};
  final Map<String, List<bool>> _selectedSubServices = {};

  @override
  void initState() {
    super.initState();
    final List<dynamic> services = widget.photographerData['services'] ?? [];
    for (var service in services) {
      final category = service['category'] ?? 'Other';
      if (!_servicesByCategory.containsKey(category)) {
        _servicesByCategory[category] = [];
        _selectedSubServices[category] = [];
      }
      _servicesByCategory[category]!.add(service);
      _selectedSubServices[category]!.add(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        List<String>.from(widget.photographerData['imageUrls'] ?? []);
    final String name = widget.photographerData['photographerName'] ?? 'N/A';
    final String location = widget.photographerData['location'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              Container(
                height: 200,
                margin: const EdgeInsets.only(bottom: 16),
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
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No images available'),
              )),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Location: $location',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text('Services:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._servicesByCategory.entries.map((entry) {
                    final category = entry.key;
                    final services = entry.value;
                    return ExpansionTile(
                      title: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: List.generate(services.length, (index) {
                        final service = services[index];
                        final String serviceName = service['name'] ?? 'N/A';
                        final double price = (service['price'] ?? 0).toDouble();
                        return CheckboxListTile(
                          title: Text(serviceName),
                          subtitle:
                              Text('Price: \$${price.toStringAsFixed(2)}'),
                          value: _selectedSubServices[category]![index],
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedSubServices[category]![index] =
                                  value ?? false;
                            });
                          },
                        );
                      }),
                    );
                  }),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedServices = <Map<String, dynamic>>[];

                        _servicesByCategory.forEach((category, services) {
                          for (int i = 0; i < services.length; i++) {
                            if (_selectedSubServices[category]![i]) {
                              selectedServices.add(services[i]);
                            }
                          }
                        });

                        if (selectedServices.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please select at least one service'),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuantityPhotographer(
                              selectedServices: selectedServices,
                              photographerId: widget.photographerId,
                              timeSlots: widget.timeSlots, // Passing timeSlots
                            ),
                          ),
                        );
                      },
                      child: const Text('Add Service'),
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
