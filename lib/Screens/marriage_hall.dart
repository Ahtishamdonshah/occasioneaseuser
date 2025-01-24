import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:occasioneaseuser/Screens/quantitymarriagehall.dart';

class MarriageHall extends StatelessWidget {
  const MarriageHall({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marriage Halls"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('Marriage Halls').snapshots(),
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

          final halls = snapshot.data!.docs;

          return ListView.builder(
            itemCount: halls.length,
            itemBuilder: (context, index) {
              final doc = halls[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    data['name'] ?? 'Unnamed Hall',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Location: ${data['location'] ?? 'Not provided'}",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    List<String> timeSlots = [];
                    try {
                      final hallDoc = await FirebaseFirestore.instance
                          .collection('Marriage Halls')
                          .doc(doc.id)
                          .get();

                      final slots = hallDoc.data()?['timeSlots'] ?? [];
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

                    // Navigating to the MarriageHallDetailingScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarriageHallDetailingScreen(
                          hallId: doc.id,
                          hallData: data,
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

class MarriageHallDetailingScreen extends StatefulWidget {
  final String hallId;
  final Map<String, dynamic> hallData;
  final List<String> timeSlots;

  const MarriageHallDetailingScreen({
    Key? key,
    required this.hallId,
    required this.hallData,
    required this.timeSlots,
  }) : super(key: key);

  @override
  _MarriageHallDetailingScreenState createState() =>
      _MarriageHallDetailingScreenState();
}

class _MarriageHallDetailingScreenState
    extends State<MarriageHallDetailingScreen> {
  final Map<String, List<Map<String, dynamic>>> _servicesByCategory = {};
  final Map<String, List<bool>> _selectedSubServices = {};

  @override
  void initState() {
    super.initState();
    final List<dynamic> services = widget.hallData['additionalServices'] ?? [];
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
        List<String>.from(widget.hallData['imageUrls'] ?? []);
    final String name = widget.hallData['name'] ?? 'N/A';
    final String location = widget.hallData['location'] ?? 'N/A';

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
                  const Text('Additional Services:',
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
                            builder: (context) =>
                                QuantityAndDateMarriageHallScreen(
                              hallId: widget.hallId,
                              hallData: widget.hallData,
                              selectedServices: selectedServices,
                              timeSlots: widget.timeSlots,
                              selectedDate:
                                  DateTime.now(), // Add appropriate date
                              selectedTimeSlot: widget.timeSlots.isNotEmpty
                                  ? widget.timeSlots[0]
                                  : '', // Add appropriate time slot
                              marriageHallId: widget.hallId, // Add this line
                              pricePerSeat: widget.hallData['pricePerSeat'] ??
                                  0.0, // Add this line
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
