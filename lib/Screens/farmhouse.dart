import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:occasioneaseuser/Screens/quantityanddatefarmhouse.dart';

class farmhouse extends StatelessWidget {
  const farmhouse({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmhouses"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('Farm Houses').snapshots(),
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

          final farmhouses = snapshot.data!.docs;

          return ListView.builder(
            itemCount: farmhouses.length,
            itemBuilder: (context, index) {
              final doc = farmhouses[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    data['name'] ?? 'Unnamed Farmhouse',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Location: ${data['location'] ?? 'Not provided'}",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    List<String> timeSlots = [];
                    try {
                      final farmhouseDoc = await FirebaseFirestore.instance
                          .collection('Farm Houses')
                          .doc(doc.id)
                          .get();

                      final slots = farmhouseDoc.data()?['timeSlots'] ?? [];
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

                    // Navigating to the FarmhouseDetailsScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FarmhouseDetailsScreen(
                          farmhouseId: doc.id,
                          farmhouseData: data,
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

class FarmhouseDetailsScreen extends StatefulWidget {
  final String farmhouseId;
  final Map<String, dynamic> farmhouseData;
  final List<String> timeSlots;

  const FarmhouseDetailsScreen({
    Key? key,
    required this.farmhouseId,
    required this.farmhouseData,
    required this.timeSlots,
  }) : super(key: key);

  @override
  _FarmhouseDetailsScreenState createState() => _FarmhouseDetailsScreenState();
}

class _FarmhouseDetailsScreenState extends State<FarmhouseDetailsScreen> {
  late List<bool> _selectedServices;

  @override
  void initState() {
    super.initState();
    _selectedServices = List.filled(
        widget.farmhouseData['additionalServices']?.length ?? 0, false);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        List<String>.from(widget.farmhouseData['imageUrls'] ?? []);
    final String name = widget.farmhouseData['name'] ?? 'N/A';
    final String location = widget.farmhouseData['location'] ?? 'N/A';
    final double farmhousePrice = widget.farmhouseData['price'] ?? 0;
    final double pricePerSeat =
        widget.farmhouseData['pricePerSeat'] ?? 0; // Get pricePerSeat
    final List<dynamic> additionalServices =
        widget.farmhouseData['additionalServices'] ?? [];

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
                  const SizedBox(height: 8),
                  Text(
                      'Price per Seat: \$${pricePerSeat.toStringAsFixed(2)}', // Display price per seat
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text('Additional Services:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate(additionalServices.length, (index) {
                    final service = additionalServices[index];
                    return CheckboxListTile(
                      title: Text(service['name'] ?? 'N/A'),
                      subtitle: Text(
                          'Price: \$${(service['price'] ?? 0).toStringAsFixed(2)}'),
                      value: _selectedServices[index],
                      onChanged: (bool? value) {
                        setState(() {
                          _selectedServices[index] = value ?? false;
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedServices = <Map<String, dynamic>>[];

                        // Collect selected services
                        for (int i = 0; i < _selectedServices.length; i++) {
                          if (_selectedServices[i]) {
                            selectedServices.add(additionalServices[i]);
                          }
                        }

                        // Navigating to Quantity and Date Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                quantityanddateFarmhouseScreen(
                              selectedRooms:
                                  selectedServices, // Assuming 'selectedServices' is the equivalent of selected rooms
                              farmhouseId: widget.farmhouseId,
                              timeSlots: widget.timeSlots,
                              roomPrices: [
                                farmhousePrice
                              ], // Wrap the farmhousePrice in a list
                              farmhousePrice: farmhousePrice,
                              selectedServices: selectedServices,
                              pricePerSeat: pricePerSeat, // Pass pricePerSeat
                            ),
                          ),
                        );
                      },
                      child: const Text('Proceed to Booking'),
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
